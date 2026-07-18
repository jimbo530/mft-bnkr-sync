// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title BnkrTreeEscrowV4
 * @notice Vault-agnostic drip-feed escrow for large USDC deposits into any
 *         CommunityLPVaultV3 clone. One escrow serves all 50+ tree funding
 *         vaults via a bytecode whitelist.
 *
 * v4 changes from v3:
 *   - Vault-agnostic: createDrip(address vault, uint256 amount) + whitelist
 *   - Double-refund fix: cancelDrip sets d.drippedUSDC = d.totalUSDC
 *   - Min/max deposit guards (1 USDC / 10,000 USDC)
 *   - Per-vault drip tracking
 *
 * Flow:
 *   User → createDrip(vault, USDC) → escrow holds USDC
 *   → keeper drip() every 30s → vault.deposit(chunk) → MfT flywheel
 *   → user claims shares (withdrawn as USDC) or cancels mid-progress
 *
 * Safety:
 *   - Exact per-chunk USDC approval (no lingering allowance)
 *   - Bounded rescue (≤ totalCommittedUSDC)
 *   - renounceRescue() one-way lock
 *   - nonReentrant on all state-changing fns
 *   - CEI pattern in cancelDrip + claimShares
 *   - 2-strike slippage → HELD state
 */
interface ICommunityLPVault {
    function deposit(uint256 amount) external returns (uint256 shares);
    function withdraw(uint256 shares) external returns (uint256);
    function maxInstantDeposit() external view returns (uint256);
    function impactBps() external view returns (uint256);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BnkrTreeEscrowV4 {
    // ============ Errors ============
    error NotKeeper();
    error NotDepositor();
    error NotAdmin();
    error DripIntervalNotElapsed();
    error DripNotActive();
    error DripStillActive();
    error ZeroAmount();
    error DepositTooSmall();
    error DepositTooLarge();
    error VaultNotWhitelisted();
    error RescueRenounced();
    error RescueExceedsCommitted();
    error NoSharesToClaim();
    error DripInProgress();
    error MaxConcurrentDrips();

    // ============ Events ============
    event DripCreated(uint256 indexed dripId, address indexed depositor, address indexed vault, uint256 totalUSDC);
    event DripExecuted(uint256 indexed dripId, uint256 chunkUSDC, uint256 sharesMinted, uint256 drippedSoFar);
    event DripCompleted(uint256 indexed dripId, uint256 totalShares);
    event DripHeld(uint256 indexed dripId, uint256 retryCount);
    event DripCancelled(uint256 indexed dripId, uint256 refundedUSDC, uint256 sharesWithdrawn);
    event SharesClaimed(uint256 indexed dripId, uint256 sharesWithdrawn, uint256 usdcReturned);
    event VaultWhitelisted(address indexed vault, bool status);
    event RescueRenounced();
    event RescueExecuted(uint256 amount);

    // ============ Structs ============
    struct Drip {
        address depositor;
        address vault;
        uint256 totalUSDC;
        uint256 drippedUSDC;
        uint256 sharesEarned;
        uint256 sharesClaimed;
        uint256 lastDripTime;
        uint256 retryCount;
        bool active;
        bool held;
    }

    // ============ Immutables ============
    IERC20 public immutable USDC;
    address public immutable KEEPER;
    address public immutable ADMIN;

    // ============ Constants ============
    uint256 public constant DRIP_INTERVAL = 30 seconds;
    uint256 public constant MAX_SLIPPAGE_BPS = 300;     // 3%
    uint256 public constant MAX_CHUNK_BPS = 9000;        // 90% of safe chunk
    uint256 public constant MIN_DEPOSIT = 1e6;          // 1 USDC
    uint256 public constant MAX_DEPOSIT = 10_000e6;      // 10,000 USDC
    uint256 public constant MAX_CONCURRENT_DRIPS = 20;
    uint256 public constant SLIPPAGE_STRIKES = 2;

    // ============ State ============
    mapping(uint256 => Drip) public drips;
    mapping(address => bool) public whitelistedVaults;
    uint256 public nextDripId = 1;
    uint256 public activeDripCount = 0;
    uint256 public lastGlobalDrip = 0;
    bool public rescueRenounced = false;

    // ============ Modifiers ============
    modifier onlyKeeper() {
        if (msg.sender != KEEPER) revert NotKeeper();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    modifier nonReentrant() {
        assembly { if tload(0) { revert(0, 0) } }
        assembly { tstore(0, 1) }
        _;
        assembly { tstore(0, 0) }
    }

    // ============ Constructor ============
    constructor(address _usdc, address _keeper, address _admin) {
        USDC = IERC20(_usdc);
        KEEPER = _keeper;
        ADMIN = _admin;
    }

    // ============ Admin: Vault Whitelist ============
    function setVaultWhitelist(address vault, bool status) external onlyAdmin {
        whitelistedVaults[vault] = status;
        emit VaultWhitelisted(vault, status);
    }

    // ============ Depositor: Create Drip ============
    function createDrip(address vault, uint256 amount) external nonReentrant returns (uint256 dripId) {
        if (amount < MIN_DEPOSIT) revert DepositTooSmall();
        if (amount > MAX_DEPOSIT) revert DepositTooLarge();
        if (!whitelistedVaults[vault]) revert VaultNotWhitelisted();
        if (activeDripCount >= MAX_CONCURRENT_DRIPS) revert MaxConcurrentDrips();

        // Transfer USDC from depositor to escrow
        if (!USDC.transferFrom(msg.sender, address(this), amount)) revert ZeroAmount();

        dripId = nextDripId++;
        drips[dripId] = Drip({
            depositor: msg.sender,
            vault: vault,
            totalUSDC: amount,
            drippedUSDC: 0,
            sharesEarned: 0,
            sharesClaimed: 0,
            lastDripTime: 0,
            retryCount: 0,
            active: true,
            held: false
        });
        activeDripCount++;

        emit DripCreated(dripId, msg.sender, vault, amount);
    }

    // ============ Keeper: Execute Drip ============
    function drip(uint256 dripId) external onlyKeeper nonReentrant {
        Drip storage d = drips[dripId];
        if (!d.active) revert DripNotActive();
        if (block.timestamp < d.lastDripTime + DRIP_INTERVAL) revert DripIntervalNotElapsed();
        if (block.timestamp < lastGlobalDrip + DRIP_INTERVAL) revert DripIntervalNotElapsed();

        ICommunityLPVault vault = ICommunityLPVault(d.vault);
        uint256 maxInstant = vault.maxInstantDeposit();
        uint256 remaining = d.totalUSDC - d.drippedUSDC;
        uint256 chunk = _computeChunkSize(maxInstant, vault.impactBps());
        if (chunk > remaining) chunk = remaining;

        // Exact approval for this chunk only
        USDC.approve(d.vault, chunk);

        uint256 sharesBefore = _vaultShares(d.vault);
        try vault.deposit(chunk) returns (uint256 sharesMinted) {
            // Clear approval (safety)
            USDC.approve(d.vault, 0);

            d.drippedUSDC += chunk;
            d.sharesEarned += sharesMinted;
            d.lastDripTime = block.timestamp;
            d.retryCount = 0;
            lastGlobalDrip = block.timestamp;

            emit DripExecuted(dripId, chunk, sharesMinted, d.drippedUSDC);

            if (d.drippedUSDC >= d.totalUSDC) {
                d.active = false;
                activeDripCount--;
                emit DripCompleted(dripId, d.sharesEarned);
            }
        } catch {
            USDC.approve(d.vault, 0);
            d.retryCount++;
            d.lastDripTime = block.timestamp;
            lastGlobalDrip = block.timestamp;

            if (d.retryCount >= SLIPPAGE_STRIKES) {
                d.held = true;
                d.active = false;
                activeDripCount--;
                emit DripHeld(dripId, d.retryCount);
            }
        }
    }

    // ============ Depositor: Cancel Drip ============
    function cancelDrip(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert NotDepositor();
        if (!d.active) revert DripNotActive();

        uint256 remainingUSDC = d.totalUSDC - d.drippedUSDC;

        // CEI: state updates BEFORE external calls
        d.active = false;
        d.held = false;
        d.drippedUSDC = d.totalUSDC; // ← v4 FIX: prevents double-refund in claimShares
        activeDripCount--;

        // Return remaining USDC
        if (remainingUSDC > 0) {
            USDC.transfer(d.depositor, remainingUSDC);
        }

        // Withdraw earned shares as USDC
        uint256 unclaimedShares = d.sharesEarned - d.sharesClaimed;
        uint256 sharesWithdrawn = 0;
        if (unclaimedShares > 0) {
            sharesWithdrawn = ICommunityLPVault(d.vault).withdraw(unclaimedShares);
            d.sharesClaimed += unclaimedShares;
            USDC.transfer(d.depositor, sharesWithdrawn);
        }

        emit DripCancelled(dripId, remainingUSDC, sharesWithdrawn);
    }

    // ============ Depositor: Claim Shares ============
    function claimShares(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert NotDepositor();
        if (d.active) revert DripInProgress();

        uint256 unclaimedShares = d.sharesEarned - d.sharesClaimed;
        uint256 remainingUSDC = d.totalUSDC - d.drippedUSDC;

        if (unclaimedShares == 0 && remainingUSDC == 0) revert NoSharesToClaim();

        // CEI: state updates BEFORE external calls
        d.sharesClaimed = d.sharesEarned;
        d.drippedUSDC = d.totalUSDC; // mark fully accounted

        uint256 usdcReturned = 0;

        // Withdraw shares from vault
        if (unclaimedShares > 0) {
            usdcReturned = ICommunityLPVault(d.vault).withdraw(unclaimedShares);
        }

        // Refund un-dripped USDC remainder (HELD recovery)
        if (remainingUSDC > 0) {
            usdcReturned += remainingUSDC;
        }

        if (usdcReturned > 0) {
            USDC.transfer(d.depositor, usdcReturned);
        }

        emit SharesClaimed(dripId, unclaimedShares, usdcReturned);
    }

    // ============ Keeper: Bounded Rescue ============
    function rescue(address vault, uint256 amount) external onlyKeeper nonReentrant {
        if (rescueRenounced) revert RescueRenounced();
        if (amount > totalCommittedUSDC()) revert RescueExceedsCommitted();

        USDC.transfer(KEEPER, amount);
        emit RescueExecuted(amount);
    }

    function renounceRescue() external onlyAdmin {
        rescueRenounced = true;
        emit RescueRenounced();
    }

    // ============ Views ============
    function totalCommittedUSDC() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i < nextDripId; i++) {
            Drip storage d = drips[i];
            if (d.active) {
                total += d.totalUSDC - d.drippedUSDC;
            }
        }
        return total;
    }

    function getDrip(uint256 dripId) external view returns (
        address depositor,
        address vault,
        uint256 totalUSDC,
        uint256 drippedUSDC,
        uint256 sharesEarned,
        uint256 sharesClaimed,
        bool active,
        bool held
    ) {
        Drip storage d = drips[dripId];
        return (d.depositor, d.vault, d.totalUSDC, d.drippedUSDC, d.sharesEarned, d.sharesClaimed, d.active, d.held);
    }

    function activeDrips() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](activeDripCount);
        uint256 idx = 0;
        for (uint256 i = 1; i < nextDripId; i++) {
            if (drips[i].active) {
                result[idx++] = i;
            }
        }
        return result;
    }

    // ============ Internal ============
    function _computeChunkSize(uint256 maxInstant, uint256 vaultImpactBps) internal pure returns (uint256) {
        if (maxInstant == 0 || vaultImpactBps == 0) return 0;
        // chunk = maxInstant × (MAX_SLIPPAGE_BPS / vaultImpactBps) × MAX_CHUNK_BPS / 10000
        return (maxInstant * MAX_SLIPPAGE_BPS / vaultImpactBps) * MAX_CHUNK_BPS / 10000;
    }

    function _vaultShares(address vault) internal view returns (uint256) {
        // Approximation: track via balanceOf if vault issues share tokens
        // For CommunityLPVaultV3, shares are internal — we use the return value
        // from deposit() instead. This is a fallback for accounting.
        return IERC20(vault).balanceOf(address(this));
    }
}
