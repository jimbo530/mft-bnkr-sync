// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BnkrTreeEscrowV3 — Drip-feed vault for large USDC deposits into BNKR Tree Funding Vault
/// @notice Splits large deposits into chunks, drips each chunk into the vault every 30s
///         to stay under the 3% slippage guard. User pays in TIME, not CAPITAL.
/// @dev v3: fixes 2 blockers from Claude's v2 re-review.
///
/// v2 → v3 changelog:
///   1. COMPILE FIX — createDrip's emit was calling _computeChunkSize() with no args,
///      but the signature is _computeChunkSize(uint256 maxInstant). Now passes
///      VAULT.maxInstantDeposit(). v2 never compiled.
///   2. FUND-LOCK FIX — HELD drips (2 slippage fails → active=false, remainder still in
///      escrow) had no recovery path: cancelDrip reverts DripAlreadyInactive, claimShares
///      only returned shares (reverted NoSharesToClaim if 0 chunks landed), rescue can't
///      touch committed USDC. Now claimShares ALSO refunds the un-dripped remainder in
///      the same call (CEI order). Held drip's depositor gets shares AND leftover USDC.
///
/// v1 → v2 changelog (unchanged in v3):
///   1. CRITICAL — Share accounting now per-drip (Drip.sharesEarned), not escrow-total.
///      Deleted sharesAtStart entirely. Shares minted in drip() accrue to d.sharesEarned.
///      claimShares/cancelDrip/getDripInfo all read d.sharesEarned directly.
///   2. CRITICAL — No more maxUint256 approval. Exact approve per chunk inside drip()
///      immediately before VAULT.deposit(chunk). Hard rule compliant.
///   3. MAJOR — rescue() bounded by totalCommittedUSDC (sum of remaining USDC across
///      active drips). Cannot drain depositors' un-dripped funds. One-way
///      renounceRescue() locks rescue forever once the vault is trusted.
///   4. MAJOR — nonReentrant guard on createDrip/drip/cancelDrip/claimShares.
///      cancelDrip sets d.active=false BEFORE any external call (CEI).
///   5. MAJOR — cancelDrip requires(d.active) (no double-cancel). drip() reverts
///      cleanly when maxInstantDeposit()==0 instead of silently dripping 0.

interface IBnkrVault {
    function deposit(uint256 usdcAmount) external;
    function withdraw(uint256 shareAmount) external;
    function withdrawAsToken(uint256 shareAmount) external;
    function getInfo(address user) external view returns (uint256 userShares, uint256 userPending, uint256 userLP, uint256 vaultLP);
    function shares(address user) external view returns (uint256);
    function maxInstantDeposit() external view returns (uint256);
    function maxImpactBps() external view returns (uint256);
    function totalShares() external view returns (uint256);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BnkrTreeEscrowV3 {
    // --- Immutable config ---
    IERC20 public immutable USDC;
    IBnkrVault public immutable VAULT;
    address public immutable KEEPER; // Bankr agent wallet (only address that can call drip)

    // --- Constants ---
    uint256 public constant DRIP_INTERVAL = 30 seconds;
    uint256 public constant MAX_SLIPPAGE_BPS = 300; // 3% guard (tighter than vault's 5%)
    uint256 public constant MAX_CHUNK_BPS = 9000; // Use 90% of maxInstantDeposit for safety margin

    // --- Drip struct (v2: sharesEarned replaces sharesAtStart) ---
    struct Drip {
        address depositor;
        uint256 totalUSDC;       // total USDC committed
        uint256 drippedUSDC;     // USDC already sent to vault
        uint256 sharesEarned;    // v2: vault shares minted FOR THIS DRIP (per-drip accounting)
        uint256 sharesClaimed;   // v2: shares already withdrawn/returned to depositor
        uint256 lastDripTime;    // timestamp of last successful drip
        uint256 retryCount;      // consecutive failures
        bool active;
    }

    // --- State ---
    mapping(uint256 => Drip) public drips;
    uint256 public dripCount;
    uint256 public lastGlobalDrip;     // global cooldown timestamp
    uint256 public totalCommittedUSDC; // v2: sum of remaining USDC across active drips (bounds rescue)
    bool public rescueRenounced;       // v2: one-way lock — once true, rescue() always reverts

    // --- Events ---
    event DripCreated(uint256 indexed dripId, address indexed depositor, uint256 totalUSDC, uint256 chunkSize);
    event DripExecuted(uint256 indexed dripId, uint256 chunkUSDC, uint256 sharesMinted, uint256 timestamp);
    event DripFailed(uint256 indexed dripId, uint256 chunkUSDC, uint256 retryCount, string reason);
    event DripHeld(uint256 indexed dripId, uint256 remainingUSDC, string reason);
    event DripCompleted(uint256 indexed dripId, uint256 totalUSDC, uint256 totalShares);
    event DripCancelled(uint256 indexed dripId, address indexed depositor, uint256 usdcReturned, uint256 sharesReturned);
    event SharesClaimed(uint256 indexed dripId, address indexed depositor, uint256 shares, uint256 usdcOrTokenOut, uint256 usdcRefunded);
    event RescueRenounced();
    event Rescued(address indexed to, uint256 amount);

    // --- Errors ---
    error OnlyKeeper();
    error OnlyDepositor();
    error DripNotActive();
    error DripStillCooling();
    error GlobalCooldownActive();
    error NoPendingUSDC();
    error ChunkTooLarge(uint256 chunk, uint256 maxAllowed);
    error TransferFailed();
    error NoSharesToClaim();
    error DripNotComplete();
    error DripAlreadyInactive();   // v2: cancel/claim on inactive drip
    error RescueRenouncedError();  // v2
    error RescueExceedsCommitted(uint256 requested, uint256 available); // v2
    error Reentrancy();            // v2
    error MaxInstantZero();         // v2: vault maxInstantDeposit() == 0

    // --- Modifiers ---
    modifier onlyKeeper() {
        if (msg.sender != KEEPER) revert OnlyKeeper();
        _;
    }

    modifier nonReentrant() {
        if (_locked) revert Reentrancy();
        _locked = true;
        _;
        _locked = false;
    }

    bool private _locked; // v2: reentrancy guard

    constructor(address _usdc, address _vault, address _keeper) {
        USDC = IERC20(_usdc);
        VAULT = IBnkrVault(_vault);
        KEEPER = _keeper;
    }

    // --- Create a drip ---
    /// @notice User deposits USDC, escrow splits into chunks and drips over time
    /// @param usdcAmount Amount of USDC to deposit (6 decimals)
    function createDrip(uint256 usdcAmount) external nonReentrant returns (uint256 dripId) {
        if (usdcAmount == 0) revert NoPendingUSDC();

        // Transfer USDC from user to escrow
        if (!USDC.transferFrom(msg.sender, address(this), usdcAmount)) revert TransferFailed();

        dripId = dripCount++;
        drips[dripId] = Drip({
            depositor: msg.sender,
            totalUSDC: usdcAmount,
            drippedUSDC: 0,
            sharesEarned: 0,
            sharesClaimed: 0,
            lastDripTime: 0, // first drip can execute immediately
            retryCount: 0,
            active: true
        });

        // v2: track committed USDC to bound rescue()
        totalCommittedUSDC += usdcAmount;

        // v2: NO maxUint256 approval. Exact per-chunk approval happens inside drip().

        // v3 FIX 1: pass VAULT.maxInstantDeposit() — v2 called _computeChunkSize() with no args (compile error)
        emit DripCreated(dripId, msg.sender, usdcAmount, _computeChunkSize(VAULT.maxInstantDeposit()));
    }

    // --- Execute a drip chunk (keeper only) ---
    /// @notice Called by keeper every 30s. Deposits one chunk into the vault.
    function drip(uint256 dripId) external onlyKeeper nonReentrant {
        Drip storage d = drips[dripId];
        if (!d.active) revert DripNotActive();
        if (d.drippedUSDC >= d.totalUSDC) revert NoPendingUSDC();

        // Check global cooldown (one drip every 30s across ALL drips)
        if (block.timestamp < lastGlobalDrip + DRIP_INTERVAL) revert GlobalCooldownActive();

        // Check per-drip cooldown
        if (d.lastDripTime != 0 && block.timestamp < d.lastDripTime + DRIP_INTERVAL) {
            revert DripStillCooling();
        }

        // v2: fail cleanly if vault reports zero capacity
        uint256 maxInstant = VAULT.maxInstantDeposit();
        if (maxInstant == 0) revert MaxInstantZero();

        // Compute chunk size — dynamic, based on vault's maxInstantDeposit
        uint256 chunk = _computeChunkSize(maxInstant);
        uint256 remaining = d.totalUSDC - d.drippedUSDC;
        if (chunk > remaining) chunk = remaining;

        // Safety: chunk must be under maxInstantDeposit * 90%
        uint256 maxSafe = (maxInstant * MAX_CHUNK_BPS) / 10000;
        if (chunk > maxSafe) {
            if (remaining <= maxSafe) {
                chunk = remaining; // last chunk, fine
            } else {
                chunk = maxSafe;
            }
        }

        // v2: EXACT approval for this chunk only — no maxUint256, hard-rule compliant
        USDC.approve(address(VAULT), chunk);

        // Record shares before deposit
        uint256 sharesBefore = VAULT.shares(address(this));

        // Execute deposit — if this reverts, slippage guard triggered
        try VAULT.deposit(chunk) {
            uint256 sharesAfter = VAULT.shares(address(this));
            uint256 sharesMinted = sharesAfter - sharesBefore;

            d.drippedUSDC += chunk;
            d.sharesEarned += sharesMinted; // v2: per-drip accounting
            d.lastDripTime = block.timestamp;
            d.retryCount = 0;
            lastGlobalDrip = block.timestamp;

            // v2: reduce committed USDC by the chunk just dripped
            totalCommittedUSDC -= chunk;

            emit DripExecuted(dripId, chunk, sharesMinted, block.timestamp);

            // Check if drip is complete
            if (d.drippedUSDC >= d.totalUSDC) {
                d.active = false;
                emit DripCompleted(dripId, d.totalUSDC, d.sharesEarned);
            }
        } catch {
            // v2: zero out the exact approval we just set (clean state)
            USDC.approve(address(VAULT), 0);

            // Slippage guard triggered — retry logic
            d.retryCount++;
            if (d.retryCount >= 2) {
                // Two strikes = hold and notify
                d.active = false;
                // v2: remaining USDC stays committed (still in escrow, still owed to depositor)
                // v3 FIX 2: depositor recovers via claimShares (returns shares + leftover USDC)
                emit DripHeld(dripId, d.totalUSDC - d.drippedUSDC, "Slippage guard triggered twice — holding remaining USDC. Claim to recover shares + USDC.");
            } else {
                emit DripFailed(dripId, chunk, d.retryCount, "Slippage guard triggered — will retry next interval");
            }
        }
    }

    // --- Cancel a drip mid-progress ---
    /// @notice Depositor can cancel anytime. Returns remaining USDC + their share of vault position.
    /// @dev v2: requires(d.active), sets active=false BEFORE external calls (CEI).
    function cancelDrip(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert OnlyDepositor();
        if (!d.active) revert DripAlreadyInactive(); // v2: no double-cancel

        uint256 remainingUSDC = d.totalUSDC - d.drippedUSDC;
        uint256 sharesToReturn = d.sharesEarned - d.sharesClaimed; // v2: per-drip

        // v2: CEI — mark inactive and update committed accounting BEFORE external calls
        d.active = false;
        if (remainingUSDC > 0) {
            totalCommittedUSDC -= remainingUSDC;
        }

        // Return remaining USDC
        if (remainingUSDC > 0) {
            if (!USDC.transfer(d.depositor, remainingUSDC)) revert TransferFailed();
        }

        // Withdraw their share of vault position and return as USDC
        if (sharesToReturn > 0) {
            uint256 usdcBefore = USDC.balanceOf(address(this));
            VAULT.withdraw(sharesToReturn);
            uint256 usdcAfter = USDC.balanceOf(address(this));
            uint256 usdcReturned = usdcAfter - usdcBefore;
            d.sharesClaimed += sharesToReturn; // v2: mark claimed
            if (usdcReturned > 0) {
                USDC.transfer(d.depositor, usdcReturned);
            }
        }

        emit DripCancelled(dripId, d.depositor, remainingUSDC, sharesToReturn);
    }

    // --- Claim shares after drip completes or is held ---
    /// @notice After drip completes (or is HELD), depositor claims their vault position
    ///         AND any un-dripped USDC remainder (v3 FIX 2).
    /// @dev v2: requires(!d.active), uses per-drip sharesEarned/sharesClaimed.
    ///      v3: also refunds remainingUSDC = totalUSDC - drippedUSDC for HELD drips.
    ///      CEI: settle all state BEFORE external calls.
    function claimShares(uint256 dripId) external nonReentrant {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert OnlyDepositor();
        if (d.active) revert DripNotComplete();

        uint256 sharesToReturn = d.sharesEarned - d.sharesClaimed; // v2: per-drip, idempotent
        uint256 remainingUSDC = d.totalUSDC - d.drippedUSDC;       // v3: >0 only for HELD drips

        // v3 FIX 2: if nothing to return at all, revert (not just shares==0)
        if (sharesToReturn == 0 && remainingUSDC == 0) revert NoSharesToClaim();

        // v3: CEI — settle ALL state BEFORE any external call
        d.sharesClaimed += sharesToReturn;
        if (remainingUSDC > 0) {
            // Mark the remainder as "dripped" so it can't be refunded twice
            d.drippedUSDC = d.totalUSDC;
            totalCommittedUSDC -= remainingUSDC;
        }

        // v3: refund un-dripped USDC remainder (HELD drips)
        if (remainingUSDC > 0) {
            if (!USDC.transfer(d.depositor, remainingUSDC)) revert TransferFailed();
        }

        // v2: withdraw shares from vault and return as USDC
        uint256 usdcOut;
        if (sharesToReturn > 0) {
            uint256 usdcBefore = USDC.balanceOf(address(this));
            VAULT.withdraw(sharesToReturn);
            uint256 usdcAfter = USDC.balanceOf(address(this));
            usdcOut = usdcAfter - usdcBefore;
            if (usdcOut > 0) {
                USDC.transfer(d.depositor, usdcOut);
            }
        }

        emit SharesClaimed(dripId, d.depositor, sharesToReturn, usdcOut, remainingUSDC);
    }

    // --- View: drip progress ---
    function getDripInfo(uint256 dripId) external view returns (
        address depositor,
        uint256 totalUSDC,
        uint256 drippedUSDC,
        uint256 remainingUSDC,
        uint256 sharesEarned,
        uint256 sharesClaimed,
        uint256 sharesOutstanding,
        bool active,
        uint256 retryCount
    ) {
        Drip storage d = drips[dripId];
        return (
            d.depositor,
            d.totalUSDC,
            d.drippedUSDC,
            d.totalUSDC - d.drippedUSDC,
            d.sharesEarned,
            d.sharesClaimed,
            d.sharesEarned - d.sharesClaimed,
            d.active,
            d.retryCount
        );
    }

    // --- View: current chunk size ---
    function currentChunkSize() external view returns (uint256) {
        return _computeChunkSize(VAULT.maxInstantDeposit());
    }

    // --- Internal: compute chunk size ---
    /// @dev Uses 90% of vault.maxInstantDeposit() as the safe chunk size.
    ///      maxInstantDeposit is the max deposit at vault's maxImpactBps (5%).
    ///      For 3% guard, we scale down: maxInstantDeposit * (300/500) * 0.9
    function _computeChunkSize(uint256 maxInstant) internal view returns (uint256) {
        if (maxInstant == 0) return 0; // v2: guard
        uint256 vaultImpactBps = VAULT.maxImpactBps(); // 500 = 5%

        // Scale from vault's impact to our 3% guard
        // If vault allows 5% impact for maxInstant, then at 3% we get maxInstant * (300/500)
        uint256 scaledMax = (maxInstant * MAX_SLIPPAGE_BPS) / vaultImpactBps;

        // Apply 90% safety margin
        return (scaledMax * MAX_CHUNK_BPS) / 10000;
    }

    // --- Admin: rescue (emergency only, bounded) ---
    /// @notice v2: Can only send USDC in EXCESS of totalCommittedUSDC.
    ///         Once renounceRescue() is called, rescue() reverts forever.
    function rescue(address to) external onlyKeeper {
        if (rescueRenounced) revert RescueRenouncedError();

        uint256 usdcBalance = USDC.balanceOf(address(this));
        uint256 available = usdcBalance > totalCommittedUSDC
            ? usdcBalance - totalCommittedUSDC
            : 0;

        if (available == 0) revert RescueExceedsCommitted(usdcBalance, totalCommittedUSDC);

        USDC.transfer(to, available);
        emit Rescued(to, available);
    }

    // --- Admin: one-way renounce rescue ---
    /// @notice Once called, rescue() is permanently disabled. Use after the vault
    ///         is audited/trusted and no emergency exit path is needed.
    function renounceRescue() external onlyKeeper {
        if (rescueRenounced) revert RescueRenouncedError();
        rescueRenounced = true;
        emit RescueRenounced();
    }
}
