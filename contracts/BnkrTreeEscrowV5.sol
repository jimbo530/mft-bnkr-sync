// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BnkrTreeEscrowV5
 * @notice Vault-agnostic drip-feed escrow for large USDC deposits into any
 *         whitelisted CommunityLPVault clone. ONE escrow serves all 50+ vaults.
 *         User pays in TIME, not CAPITAL: commit USDC, keeper drips slippage-safe
 *         chunks every 30s, user claims their position (as USDC) or cancels.
 *
 * @dev v5 = v3 (correct vault interface + correct bounded rescue) + 3 surgical
 *      changes, NOT a rewrite:
 *        1. Vault-agnostic: createDrip(vault, amount) + admin whitelist (kept from v4)
 *        2. Double-refund fix: cancel/claim set drippedUSDC = totalUSDC
 *        3. Min/max deposit + max-concurrent guards
 *      v4's from-scratch rewrite broke the vault interface (deposit/withdraw
 *      return NOTHING; the fn is maxImpactBps not impactBps; shares() is the
 *      accounting source) and INVERTED the rescue bound (a rug). v5 restores
 *      v3's correctness while adding the vault-agnostic + guard features.
 *
 * Real vault interface (verified on-chain, impl 0x3bB5f84c…DaE318):
 *   deposit(uint256)->()   withdraw(uint256)->()   (both return NOTHING)
 *   shares(address) view->uint256   maxInstantDeposit() view   maxImpactBps() view
 */
interface ICommunityLPVault {
    function deposit(uint256 usdcAmount) external;      // returns nothing → read shares() delta
    function withdraw(uint256 shareAmount) external;    // returns nothing → read USDC balance delta
    function shares(address user) external view returns (uint256);
    function maxInstantDeposit() external view returns (uint256);
    function maxImpactBps() external view returns (uint256);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BnkrTreeEscrowV5 {
    // ---- Roles ----
    IERC20  public immutable USDC;    // set to the REAL Base USDC 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 at deploy
    address public immutable KEEPER;  // calls drip()
    address public immutable ADMIN;   // whitelist vaults, rescue excess, renounce

    // ---- Constants ----
    uint256 public constant DRIP_INTERVAL    = 30 seconds;
    uint256 public constant MAX_SLIPPAGE_BPS = 300;         // 3% (tighter than the vault's own guard)
    uint256 public constant MAX_CHUNK_BPS    = 9000;        // 90% safety margin under maxInstantDeposit
    uint256 public constant MIN_DEPOSIT      = 1e6;         // 1 USDC (6 dec)
    uint256 public constant MAX_DEPOSIT      = 10_000e6;    // 10,000 USDC
    uint256 public constant MAX_CONCURRENT   = 20;          // active-drip cap (queue-saturation guard)
    uint256 public constant SLIPPAGE_STRIKES = 2;

    // ---- Drip ----
    struct Drip {
        address depositor;
        address vault;
        uint256 totalUSDC;
        uint256 drippedUSDC;
        uint256 sharesEarned;
        uint256 sharesClaimed;
        uint256 lastDripTime;
        uint256 retryCount;
        bool    active;
        bool    held;
    }

    // ---- State ----
    mapping(uint256 => Drip) public drips;
    mapping(address => bool)  public whitelistedVaults;
    uint256 public nextDripId = 1;
    uint256 public activeDripCount;
    uint256 public lastGlobalDrip;
    uint256 public totalCommittedUSDC; // O(1) running total of USDC owed to depositors (active + held remainders)
    bool    public rescueRenounced;
    bool    private _locked;

    // ---- Events ----
    event VaultWhitelisted(address indexed vault, bool status);
    event DripCreated(uint256 indexed dripId, address indexed depositor, address indexed vault, uint256 totalUSDC, uint256 chunkSize);
    event DripExecuted(uint256 indexed dripId, uint256 chunkUSDC, uint256 sharesMinted, uint256 drippedSoFar);
    event DripFailed(uint256 indexed dripId, uint256 retryCount);
    event DripHeld(uint256 indexed dripId, uint256 remainingUSDC);
    event DripCompleted(uint256 indexed dripId, uint256 totalShares);
    event DripCancelled(uint256 indexed dripId, uint256 usdcRefunded, uint256 usdcFromShares);
    event SharesClaimed(uint256 indexed dripId, uint256 usdcFromShares, uint256 usdcRefunded);
    event RescueExecuted(address indexed to, uint256 amount);
    event RescueRenounced();

    // ---- Errors ----
    error NotKeeper();
    error NotAdmin();
    error NotDepositor();
    error DepositTooSmall();
    error DepositTooLarge();
    error VaultNotWhitelisted();
    error TooManyConcurrent();
    error TransferFailed();
    error DripNotActive();
    error DripStillActive();
    error Cooling();
    error MaxInstantZero();
    error NothingToClaim();
    error Reentrancy();
    error RescueIsRenounced();
    error RescueExceedsExcess(uint256 requested, uint256 available);

    modifier onlyKeeper() { if (msg.sender != KEEPER) revert NotKeeper(); _; }
    modifier onlyAdmin()  { if (msg.sender != ADMIN)  revert NotAdmin();  _; }
    modifier nonReentrant() { if (_locked) revert Reentrancy(); _locked = true; _; _locked = false; }

    constructor(address _usdc, address _keeper, address _admin) {
        require(_usdc != address(0) && _keeper != address(0) && _admin != address(0), "zero addr");
        USDC   = IERC20(_usdc);
        KEEPER = _keeper;
        ADMIN  = _admin;
    }

    // ---- Admin: whitelist the vaults this escrow may drip into ----
    function setVaultWhitelist(address vault, bool status) external onlyAdmin {
        whitelistedVaults[vault] = status;
        emit VaultWhitelisted(vault, status);
    }

    // ---- Depositor: commit USDC for a drip into a whitelisted vault ----
    function createDrip(address vault, uint256 amount) external nonReentrant returns (uint256 dripId) {
        if (amount < MIN_DEPOSIT) revert DepositTooSmall();
        if (amount > MAX_DEPOSIT) revert DepositTooLarge();
        if (!whitelistedVaults[vault]) revert VaultNotWhitelisted();
        if (activeDripCount >= MAX_CONCURRENT) revert TooManyConcurrent();

        if (!USDC.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        dripId = nextDripId++;
        drips[dripId] = Drip({
            depositor: msg.sender, vault: vault,
            totalUSDC: amount, drippedUSDC: 0,
            sharesEarned: 0, sharesClaimed: 0,
            lastDripTime: 0, retryCount: 0,
            active: true, held: false
        });
        activeDripCount++;
        totalCommittedUSDC += amount;

        emit DripCreated(dripId, msg.sender, vault, amount, _chunkFor(vault));
    }

    // ---- Keeper: execute one slippage-safe chunk (every 30s) ----
    function drip(uint256 dripId) external onlyKeeper nonReentrant {
        Drip storage d = drips[dripId];
        if (!d.active) revert DripNotActive();
        if (d.lastDripTime != 0 && block.timestamp < d.lastDripTime + DRIP_INTERVAL) revert Cooling();
        if (block.timestamp < lastGlobalDrip + DRIP_INTERVAL) revert Cooling();

        ICommunityLPVault vault = ICommunityLPVault(d.vault);
        uint256 maxInstant = vault.maxInstantDeposit();
        if (maxInstant == 0) revert MaxInstantZero();

        uint256 chunk = _computeChunk(maxInstant, vault.maxImpactBps());
        uint256 remaining = d.totalUSDC - d.drippedUSDC;
        if (chunk > remaining) chunk = remaining;
        uint256 maxSafe = (maxInstant * MAX_CHUNK_BPS) / 10000;
        if (chunk > maxSafe) chunk = maxSafe;
        if (chunk == 0) revert MaxInstantZero();

        // exact approval for this chunk only — no lingering allowance
        USDC.approve(d.vault, chunk);

        uint256 sharesBefore = vault.shares(address(this));
        try vault.deposit(chunk) {
            // vault.deposit returns NOTHING → shares minted = shares() delta
            uint256 minted = vault.shares(address(this)) - sharesBefore;
            USDC.approve(d.vault, 0); // clear any residual allowance

            d.drippedUSDC      += chunk;
            d.sharesEarned     += minted;
            d.lastDripTime      = block.timestamp;
            d.retryCount        = 0;
            lastGlobalDrip      = block.timestamp;
            totalCommittedUSDC -= chunk;

            emit DripExecuted(dripId, chunk, minted, d.drippedUSDC);

            if (d.drippedUSDC >= d.totalUSDC) {
                d.active = false;
                activeDripCount--;
                emit DripCompleted(dripId, d.sharesEarned);
            }
        } catch {
            USDC.approve(d.vault, 0); // deposit reverted → clear the approval
            d.retryCount++;
            d.lastDripTime = block.timestamp;
            lastGlobalDrip = block.timestamp;
            if (d.retryCount >= SLIPPAGE_STRIKES) {
                d.held   = true;
                d.active = false;
                activeDripCount--;
                // remaining stays in totalCommittedUSDC — still owed; recovered via claimShares
                emit DripHeld(dripId, d.totalUSDC - d.drippedUSDC);
            } else {
                emit DripFailed(dripId, d.retryCount);
            }
        }
    }

    // ---- Depositor: cancel an ACTIVE drip → remaining USDC + earned position (as USDC) ----
    function cancelDrip(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert NotDepositor();
        if (!d.active) revert DripNotActive();

        uint256 remainingUSDC = d.totalUSDC - d.drippedUSDC;
        uint256 unclaimed     = d.sharesEarned - d.sharesClaimed;

        // CEI — settle ALL state before external calls
        d.active = false;
        activeDripCount--;
        d.drippedUSDC   = d.totalUSDC;        // ← double-refund guard (mirrors claimShares)
        d.sharesClaimed = d.sharesEarned;
        if (remainingUSDC > 0) totalCommittedUSDC -= remainingUSDC;

        uint256 usdcFromShares = 0;
        if (unclaimed > 0) {
            uint256 balBefore = USDC.balanceOf(address(this));
            ICommunityLPVault(d.vault).withdraw(unclaimed); // returns nothing → balance delta
            usdcFromShares = USDC.balanceOf(address(this)) - balBefore;
        }
        uint256 payout = remainingUSDC + usdcFromShares;
        if (payout > 0 && !USDC.transfer(d.depositor, payout)) revert TransferFailed();

        emit DripCancelled(dripId, remainingUSDC, usdcFromShares);
    }

    // ---- Depositor: claim after the drip COMPLETES or is HELD ----
    function claimShares(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert NotDepositor();
        if (d.active) revert DripStillActive();

        uint256 unclaimed     = d.sharesEarned - d.sharesClaimed;
        uint256 remainingUSDC = d.totalUSDC - d.drippedUSDC; // >0 only for HELD drips
        if (unclaimed == 0 && remainingUSDC == 0) revert NothingToClaim();

        // CEI
        d.sharesClaimed = d.sharesEarned;
        if (remainingUSDC > 0) {
            d.drippedUSDC       = d.totalUSDC;    // can't be refunded twice
            totalCommittedUSDC -= remainingUSDC;
        }

        uint256 usdcFromShares = 0;
        if (unclaimed > 0) {
            uint256 balBefore = USDC.balanceOf(address(this));
            ICommunityLPVault(d.vault).withdraw(unclaimed);
            usdcFromShares = USDC.balanceOf(address(this)) - balBefore;
        }
        uint256 payout = remainingUSDC + usdcFromShares;
        if (payout > 0 && !USDC.transfer(d.depositor, payout)) revert TransferFailed();

        emit SharesClaimed(dripId, usdcFromShares, remainingUSDC);
    }

    // ---- Admin: bounded rescue — EXCESS above committed only (never depositor funds) ----
    function rescue(address to, uint256 amount) external onlyAdmin nonReentrant {
        if (rescueRenounced) revert RescueIsRenounced();
        uint256 bal = USDC.balanceOf(address(this));
        uint256 available = bal > totalCommittedUSDC ? bal - totalCommittedUSDC : 0;
        if (amount > available) revert RescueExceedsExcess(amount, available);
        if (!USDC.transfer(to, amount)) revert TransferFailed();
        emit RescueExecuted(to, amount);
    }

    function renounceRescue() external onlyAdmin {
        rescueRenounced = true;
        emit RescueRenounced();
    }

    // ---- Views ----
    function currentChunk(address vault) external view returns (uint256) { return _chunkFor(vault); }

    function getDrip(uint256 dripId) external view returns (
        address depositor, address vault, uint256 totalUSDC, uint256 drippedUSDC,
        uint256 sharesEarned, uint256 sharesClaimed, uint256 remainingUSDC, bool active, bool held
    ) {
        Drip storage d = drips[dripId];
        return (d.depositor, d.vault, d.totalUSDC, d.drippedUSDC, d.sharesEarned, d.sharesClaimed, d.totalUSDC - d.drippedUSDC, d.active, d.held);
    }

    /// @notice Active drip IDs the keeper should call drip() on. View-only (off-chain, gas-free).
    function activeDrips() external view returns (uint256[] memory ids) {
        ids = new uint256[](activeDripCount);
        uint256 k = 0;
        for (uint256 i = 1; i < nextDripId; i++) {
            if (drips[i].active) ids[k++] = i;
        }
    }

    // ---- Internal ----
    function _chunkFor(address vault) internal view returns (uint256) {
        uint256 mi = ICommunityLPVault(vault).maxInstantDeposit();
        if (mi == 0) return 0;
        return _computeChunk(mi, ICommunityLPVault(vault).maxImpactBps());
    }

    /// @dev chunk = maxInstant × (3% / vault's impact cap) × 90%. Scales with pool depth.
    function _computeChunk(uint256 maxInstant, uint256 vaultImpactBps) internal pure returns (uint256) {
        if (maxInstant == 0 || vaultImpactBps == 0) return 0;
        return (maxInstant * MAX_SLIPPAGE_BPS / vaultImpactBps) * MAX_CHUNK_BPS / 10000;
    }
}
