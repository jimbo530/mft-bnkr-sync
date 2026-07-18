// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BnkrTreeEscrowV5RH
 * @notice Robinhood-chain (4663) port of Base BnkrTreeEscrowV5: vault-agnostic
 *         drip-feed escrow for large USDG deposits into any whitelisted
 *         community vault (BurgersCommunityVault pattern / RHVaultFactory clones).
 *         User pays in TIME, not CAPITAL: commit USDG, then drip slippage-safe
 *         chunks every 30s, and claim the position (as USDG) or cancel.
 *
 * @dev drip() is PUBLIC / permissionless — anyone can press the button and pay
 *      gas. Calling drip() only ever ADVANCES a deposit the depositor already
 *      wants, and the 30s cooldowns cap the rate, so there is no abuse vector.
 *
 *      Port deltas vs Base v5 (venue layer ONLY — logic is 1:1):
 *        - USDC -> USDG (both 6 decimals; MIN/MAX unchanged)
 *        - vault.deposit(amount) -> deposit(amount, displayName); name stored per drip
 *        - vault.maxImpactBps() -> slippageBps() (same semantics: impact tolerance)
 *        - chunk floored up to the vault's own MIN_DEPOSIT() when remaining allows
 *        - rescueDust(token != USDG) for FTP/BURGERS dust the vault returns to
 *          depositors (the escrow) during adds; gated by the SAME one-way
 *          renounceRescue() switch as excess rescue — renounce kills ALL admin exits.
 *
 * Vault interface (verified from RHVaultFactory impl source, live V2 vault
 * 0x261F76D20983f299962b1481d7968d2F27b79BB1):
 *   deposit(uint256,string)->()   withdraw(uint256)->()   (both return NOTHING)
 *   shares(address) view->uint256   maxInstantDeposit() view
 *   slippageBps() view   MIN_DEPOSIT() view
 */
interface ICommunityVaultRH {
    function deposit(uint256 usdgAmount, string calldata displayName) external;
    function withdraw(uint256 shareAmount) external;    // pays USDG → read balance delta
    function shares(address user) external view returns (uint256);
    function maxInstantDeposit() external view returns (uint256);
    function slippageBps() external view returns (uint256);
    function MIN_DEPOSIT() external view returns (uint256);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BnkrTreeEscrowV5RH {
    // ---- Roles ----
    IERC20  public immutable USDG;   // RH USDG 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168 at deploy
    address public immutable ADMIN;  // whitelists vaults, rescues EXCESS/dust only, renounces rescue

    // ---- Constants ----
    uint256 public constant DRIP_INTERVAL    = 30 seconds;
    uint256 public constant MAX_SLIPPAGE_BPS = 300;         // 3% (tighter than the vault's own guard)
    uint256 public constant MAX_CHUNK_BPS    = 9000;        // 90% safety margin under maxInstantDeposit
    uint256 public constant MIN_DEPOSIT      = 1e6;         // 1 USDG (6 dec)
    uint256 public constant MAX_DEPOSIT      = 10_000e6;    // 10,000 USDG
    uint256 public constant MAX_CONCURRENT   = 20;          // active-drip cap (queue-saturation guard)
    uint256 public constant SLIPPAGE_STRIKES = 2;

    // ---- Drip ----
    struct Drip {
        address depositor;
        address vault;
        uint256 totalUSDG;
        uint256 drippedUSDG;
        uint256 sharesEarned;
        uint256 sharesClaimed;
        uint256 lastDripTime;
        uint256 retryCount;
        bool    active;
        bool    held;
    }

    // ---- State ----
    mapping(uint256 => Drip) public drips;
    mapping(uint256 => string) public dripName;             // vault leaderboard displayName per drip
    mapping(address => bool)  public whitelistedVaults;
    uint256 public nextDripId = 1;
    uint256 public activeDripCount;
    uint256 public lastGlobalDrip;
    uint256 public totalCommittedUSDG; // O(1) running total of USDG owed to depositors (active + held remainders)
    bool    public rescueRenounced;
    bool    private _locked;

    // ---- Events ----
    event VaultWhitelisted(address indexed vault, bool status);
    event DripCreated(uint256 indexed dripId, address indexed depositor, address indexed vault, uint256 totalUSDG, uint256 chunkSize);
    event DripExecuted(uint256 indexed dripId, uint256 chunkUSDG, uint256 sharesMinted, uint256 drippedSoFar, address caller);
    event DripFailed(uint256 indexed dripId, uint256 retryCount);
    event DripHeld(uint256 indexed dripId, uint256 remainingUSDG);
    event DripCompleted(uint256 indexed dripId, uint256 totalShares);
    event DripCancelled(uint256 indexed dripId, uint256 usdgRefunded, uint256 usdgFromShares);
    event SharesClaimed(uint256 indexed dripId, uint256 usdgFromShares, uint256 usdgRefunded);
    event RescueExecuted(address indexed to, uint256 amount);
    event DustRescued(address indexed token, address indexed to, uint256 amount);
    event RescueRenounced();

    // ---- Errors ----
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
    error DustCannotBeUSDG();

    modifier onlyAdmin()  { if (msg.sender != ADMIN) revert NotAdmin(); _; }
    modifier nonReentrant() { if (_locked) revert Reentrancy(); _locked = true; _; _locked = false; }

    constructor(address _usdg, address _admin) {
        require(_usdg != address(0) && _admin != address(0), "zero addr");
        USDG  = IERC20(_usdg);
        ADMIN = _admin;
    }

    // ---- Admin: whitelist the vaults this escrow may drip into ----
    function setVaultWhitelist(address vault, bool status) external onlyAdmin {
        whitelistedVaults[vault] = status;
        emit VaultWhitelisted(vault, status);
    }

    // ---- Depositor: commit USDG for a drip into a whitelisted vault ----
    function createDrip(address vault, uint256 amount, string calldata displayName) external nonReentrant returns (uint256 dripId) {
        if (amount < MIN_DEPOSIT) revert DepositTooSmall();
        if (amount > MAX_DEPOSIT) revert DepositTooLarge();
        if (!whitelistedVaults[vault]) revert VaultNotWhitelisted();
        if (activeDripCount >= MAX_CONCURRENT) revert TooManyConcurrent();

        if (!USDG.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        dripId = nextDripId++;
        drips[dripId] = Drip({
            depositor: msg.sender, vault: vault,
            totalUSDG: amount, drippedUSDG: 0,
            sharesEarned: 0, sharesClaimed: 0,
            lastDripTime: 0, retryCount: 0,
            active: true, held: false
        });
        if (bytes(displayName).length > 0) dripName[dripId] = displayName;
        activeDripCount++;
        totalCommittedUSDG += amount;

        emit DripCreated(dripId, msg.sender, vault, amount, _chunkFor(vault));
    }

    // ---- PUBLIC: execute one slippage-safe chunk. Anyone can call (pay gas). Cooldowns cap the rate. ----
    function drip(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (!d.active) revert DripNotActive();
        if (d.lastDripTime != 0 && block.timestamp < d.lastDripTime + DRIP_INTERVAL) revert Cooling();
        if (block.timestamp < lastGlobalDrip + DRIP_INTERVAL) revert Cooling();

        ICommunityVaultRH vault = ICommunityVaultRH(d.vault);
        uint256 maxInstant = vault.maxInstantDeposit();
        if (maxInstant == 0) revert MaxInstantZero();

        uint256 chunk = _computeChunk(maxInstant, vault.slippageBps());
        uint256 remaining = d.totalUSDG - d.drippedUSDG;
        if (chunk > remaining) chunk = remaining;
        uint256 maxSafe = (maxInstant * MAX_CHUNK_BPS) / 10000;
        if (chunk > maxSafe) chunk = maxSafe;
        // vault enforces its own MIN_DEPOSIT floor — bump the chunk up to it when the
        // remaining commitment allows, else let strikes route the tail to claimShares
        uint256 vaultMin = vault.MIN_DEPOSIT();
        if (chunk < vaultMin && remaining >= vaultMin) chunk = vaultMin;
        if (chunk == 0) revert MaxInstantZero();

        // exact approval for this chunk only — no lingering allowance
        USDG.approve(d.vault, chunk);

        uint256 sharesBefore = vault.shares(address(this));
        try vault.deposit(chunk, dripName[dripId]) {
            // vault.deposit returns NOTHING → shares minted = shares() delta
            uint256 minted = vault.shares(address(this)) - sharesBefore;
            USDG.approve(d.vault, 0); // clear any residual allowance

            d.drippedUSDG      += chunk;
            d.sharesEarned     += minted;
            d.lastDripTime      = block.timestamp;
            d.retryCount        = 0;
            lastGlobalDrip      = block.timestamp;
            totalCommittedUSDG -= chunk;

            emit DripExecuted(dripId, chunk, minted, d.drippedUSDG, msg.sender);

            if (d.drippedUSDG >= d.totalUSDG) {
                d.active = false;
                activeDripCount--;
                emit DripCompleted(dripId, d.sharesEarned);
            }
        } catch {
            USDG.approve(d.vault, 0); // deposit reverted → clear the approval
            d.retryCount++;
            d.lastDripTime = block.timestamp;
            lastGlobalDrip = block.timestamp;
            if (d.retryCount >= SLIPPAGE_STRIKES) {
                d.held   = true;
                d.active = false;
                activeDripCount--;
                // remaining stays in totalCommittedUSDG — still owed; recovered via claimShares
                emit DripHeld(dripId, d.totalUSDG - d.drippedUSDG);
            } else {
                emit DripFailed(dripId, d.retryCount);
            }
        }
    }

    // ---- Depositor: cancel an ACTIVE drip → remaining USDG + earned position (as USDG) ----
    function cancelDrip(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert NotDepositor();
        if (!d.active) revert DripNotActive();

        uint256 remainingUSDG = d.totalUSDG - d.drippedUSDG;
        uint256 unclaimed     = d.sharesEarned - d.sharesClaimed;

        // CEI — settle ALL state before external calls
        d.active = false;
        activeDripCount--;
        d.drippedUSDG   = d.totalUSDG;        // ← double-refund guard (mirrors claimShares)
        d.sharesClaimed = d.sharesEarned;
        if (remainingUSDG > 0) totalCommittedUSDG -= remainingUSDG;

        uint256 usdgFromShares = 0;
        if (unclaimed > 0) {
            uint256 balBefore = USDG.balanceOf(address(this));
            ICommunityVaultRH(d.vault).withdraw(unclaimed); // pays USDG → balance delta
            usdgFromShares = USDG.balanceOf(address(this)) - balBefore;
        }
        uint256 payout = remainingUSDG + usdgFromShares;
        if (payout > 0 && !USDG.transfer(d.depositor, payout)) revert TransferFailed();

        emit DripCancelled(dripId, remainingUSDG, usdgFromShares);
    }

    // ---- Depositor: claim after the drip COMPLETES or is HELD ----
    function claimShares(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert NotDepositor();
        if (d.active) revert DripStillActive();

        uint256 unclaimed     = d.sharesEarned - d.sharesClaimed;
        uint256 remainingUSDG = d.totalUSDG - d.drippedUSDG; // >0 only for HELD drips
        if (unclaimed == 0 && remainingUSDG == 0) revert NothingToClaim();

        // CEI
        d.sharesClaimed = d.sharesEarned;
        if (remainingUSDG > 0) {
            d.drippedUSDG       = d.totalUSDG;    // can't be refunded twice
            totalCommittedUSDG -= remainingUSDG;
        }

        uint256 usdgFromShares = 0;
        if (unclaimed > 0) {
            uint256 balBefore = USDG.balanceOf(address(this));
            ICommunityVaultRH(d.vault).withdraw(unclaimed);
            usdgFromShares = USDG.balanceOf(address(this)) - balBefore;
        }
        uint256 payout = remainingUSDG + usdgFromShares;
        if (payout > 0 && !USDG.transfer(d.depositor, payout)) revert TransferFailed();

        emit SharesClaimed(dripId, usdgFromShares, remainingUSDG);
    }

    // ---- Admin: bounded rescue — EXCESS above committed only (never depositor funds) ----
    function rescue(address to, uint256 amount) external onlyAdmin nonReentrant {
        if (rescueRenounced) revert RescueIsRenounced();
        uint256 bal = USDG.balanceOf(address(this));
        uint256 available = bal > totalCommittedUSDG ? bal - totalCommittedUSDG : 0;
        if (amount > available) revert RescueExceedsExcess(amount, available);
        if (!USDG.transfer(to, amount)) revert TransferFailed();
        emit RescueExecuted(to, amount);
    }

    // ---- Admin: recover non-USDG dust (FTP/BURGERS add-remainders the vault returns
    //      to the escrow). Depositor funds are USDG-only, so this can never touch them.
    //      Gated by the SAME one-way renounce as rescue — renounce kills ALL admin exits.
    function rescueDust(address token, address to, uint256 amount) external onlyAdmin nonReentrant {
        if (rescueRenounced) revert RescueIsRenounced();
        if (token == address(USDG)) revert DustCannotBeUSDG();
        if (!IERC20(token).transfer(to, amount)) revert TransferFailed();
        emit DustRescued(token, to, amount);
    }

    function renounceRescue() external onlyAdmin {
        rescueRenounced = true;
        emit RescueRenounced();
    }

    // ---- Views ----
    function currentChunk(address vault) external view returns (uint256) { return _chunkFor(vault); }

    function getDrip(uint256 dripId) external view returns (
        address depositor, address vault, uint256 totalUSDG, uint256 drippedUSDG,
        uint256 sharesEarned, uint256 sharesClaimed, uint256 remainingUSDG, bool active, bool held
    ) {
        Drip storage d = drips[dripId];
        return (d.depositor, d.vault, d.totalUSDG, d.drippedUSDG, d.sharesEarned, d.sharesClaimed, d.totalUSDG - d.drippedUSDG, d.active, d.held);
    }

    /// @notice Active drip IDs anyone should call drip() on. View-only (off-chain, gas-free).
    function activeDrips() external view returns (uint256[] memory ids) {
        ids = new uint256[](activeDripCount);
        uint256 k = 0;
        for (uint256 i = 1; i < nextDripId; i++) {
            if (drips[i].active) ids[k++] = i;
        }
    }

    // ---- Internal ----
    function _chunkFor(address vault) internal view returns (uint256) {
        uint256 mi = ICommunityVaultRH(vault).maxInstantDeposit();
        if (mi == 0) return 0;
        return _computeChunk(mi, ICommunityVaultRH(vault).slippageBps());
    }

    /// @dev chunk = maxInstant × (3% / vault's impact cap) × 90%. Scales with pool depth.
    function _computeChunk(uint256 maxInstant, uint256 vaultImpactBps) internal pure returns (uint256) {
        if (maxInstant == 0 || vaultImpactBps == 0) return 0;
        return (maxInstant * MAX_SLIPPAGE_BPS / vaultImpactBps) * MAX_CHUNK_BPS / 10000;
    }
}
