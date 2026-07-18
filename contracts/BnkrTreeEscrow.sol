// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BnkrTreeEscrow — Drip-feed vault for large USDC deposits into BNKR Tree Funding Vault
/// @notice Splits large deposits into chunks, drips each chunk into the vault every 30s
///         to stay under the 3% slippage guard. User pays in TIME, not CAPITAL.
/// @dev v1: single queue, Bankr calls drip(). No concurrent drips, no gas bounty.
///        Shares accrue to the escrow; user claims their portion on exit.

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

contract BnkrTreeEscrow {
    // --- Immutable config ---
    IERC20 public immutable USDC;
    IBnkrVault public immutable VAULT;
    address public immutable KEEPER; // Bankr agent wallet (only address that can call drip)

    // --- Constants ---
    uint256 public constant DRIP_INTERVAL = 30 seconds;
    uint256 public constant MAX_SLIPPAGE_BPS = 300; // 3% guard (tighter than vault's 5%)
    uint256 public constant MAX_CHUNK_BPS = 9000; // Use 90% of maxInstantDeposit for safety margin

    // --- Drip struct ---
    struct Drip {
        address depositor;
        uint256 totalUSDC;       // total USDC committed
        uint256 drippedUSDC;     // USDC already sent to vault
        uint256 sharesAtStart;   // escrow's vault shares before this drip started (for accounting)
        uint256 lastDripTime;   // timestamp of last successful drip
        uint256 retryCount;     // consecutive failures
        bool active;
    }

    // --- State ---
    mapping(uint256 => Drip) public drips;
    uint256 public dripCount;
    uint256 public lastGlobalDrip; // global cooldown timestamp

    // --- Events ---
    event DripCreated(uint256 indexed dripId, address indexed depositor, uint256 totalUSDC, uint256 chunkSize);
    event DripExecuted(uint256 indexed dripId, uint256 chunkUSDC, uint256 sharesMinted, uint256 timestamp);
    event DripFailed(uint256 indexed dripId, uint256 chunkUSDC, uint256 retryCount, string reason);
    event DripHeld(uint256 indexed dripId, uint256 remainingUSDC, string reason);
    event DripCompleted(uint256 indexed dripId, uint256 totalUSDC, uint256 totalShares);
    event DripCancelled(uint256 indexed dripId, address indexed depositor, uint256 usdcReturned, uint256 sharesReturned);
    event SharesClaimed(uint256 indexed dripId, address indexed depositor, uint256 shares, uint256 usdcOrTokenOut);

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

    // --- Modifiers ---
    modifier onlyKeeper() {
        if (msg.sender != KEEPER) revert OnlyKeeper();
        _;
    }

    constructor(address _usdc, address _vault, address _keeper) {
        USDC = IERC20(_usdc);
        VAULT = IBnkrVault(_vault);
        KEEPER = _keeper;
    }

    // --- Create a drip ---
    /// @notice User deposits USDC, escrow splits into chunks and drips over time
    /// @param usdcAmount Amount of USDC to deposit (6 decimals)
    function createDrip(uint256 usdcAmount) external returns (uint256 dripId) {
        if (usdcAmount == 0) revert NoPendingUSDC();

        // Transfer USDC from user to escrow
        if (!USDC.transferFrom(msg.sender, address(this), usdcAmount)) revert TransferFailed();

        dripId = dripCount++;
        drips[dripId] = Drip({
            depositor: msg.sender,
            totalUSDC: usdcAmount,
            drippedUSDC: 0,
            sharesAtStart: VAULT.shares(address(this)),
            lastDripTime: 0, // first drip can execute immediately
            retryCount: 0,
            active: true
        });

        // Approve vault to spend our USDC
        USDC.approve(address(VAULT), type(uint256).max);

        emit DripCreated(dripId, msg.sender, usdcAmount, _computeChunkSize());
    }

    // --- Execute a drip chunk (keeper only) ---
    /// @notice Called by keeper every 30s. Deposits one chunk into the vault.
    function drip(uint256 dripId) external onlyKeeper {
        Drip storage d = drips[dripId];
        if (!d.active) revert DripNotActive();
        if (d.drippedUSDC >= d.totalUSDC) revert NoPendingUSDC();

        // Check global cooldown (one drip every 30s across ALL drips)
        if (block.timestamp < lastGlobalDrip + DRIP_INTERVAL) revert GlobalCooldownActive();

        // Check per-drip cooldown
        if (d.lastDripTime != 0 && block.timestamp < d.lastDripTime + DRIP_INTERVAL) {
            revert DripStillCooling();
        }

        // Compute chunk size — dynamic, based on vault's maxInstantDeposit
        uint256 chunk = _computeChunkSize();
        uint256 remaining = d.totalUSDC - d.drippedUSDC;
        if (chunk > remaining) chunk = remaining;

        // Safety: chunk must be under maxInstantDeposit * 90%
        uint256 maxSafe = (VAULT.maxInstantDeposit() * MAX_CHUNK_BPS) / 10000;
        if (chunk > maxSafe) {
            if (remaining <= maxSafe) {
                chunk = remaining; // last chunk, fine
            } else {
                chunk = maxSafe;
            }
        }

        // Record shares before deposit
        uint256 sharesBefore = VAULT.shares(address(this));

        // Execute deposit — if this reverts, slippage guard triggered
        try VAULT.deposit(chunk) {
            uint256 sharesAfter = VAULT.shares(address(this));
            uint256 sharesMinted = sharesAfter - sharesBefore;

            d.drippedUSDC += chunk;
            d.lastDripTime = block.timestamp;
            d.retryCount = 0;
            lastGlobalDrip = block.timestamp;

            emit DripExecuted(dripId, chunk, sharesMinted, block.timestamp);

            // Check if drip is complete
            if (d.drippedUSDC >= d.totalUSDC) {
                d.active = false;
                emit DripCompleted(dripId, d.totalUSDC, VAULT.shares(address(this)) - d.sharesAtStart);
            }
        } catch {
            // Slippage guard triggered — retry logic
            d.retryCount++;
            if (d.retryCount >= 2) {
                // Two strikes = hold and notify
                d.active = false;
                emit DripHeld(dripId, d.totalUSDC - d.drippedUSDC, "Slippage guard triggered twice — holding remaining USDC");
            } else {
                emit DripFailed(dripId, chunk, d.retryCount, "Slippage guard triggered — will retry next interval");
            }
        }
    }

    // --- Cancel a drip mid-progress ---
    /// @notice Depositor can cancel anytime. Returns remaining USDC + their share of vault position.
    function cancelDrip(uint256 dripId) external {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert OnlyDepositor();

        uint256 remainingUSDC = d.totalUSDC - d.drippedUSDC;
        uint256 sharesEarned = VAULT.shares(address(this)) - d.sharesAtStart;

        // Return remaining USDC
        if (remainingUSDC > 0) {
            if (!USDC.transfer(d.depositor, remainingUSDC)) revert TransferFailed();
        }

        // Withdraw their share of vault position and return as USDC
        if (sharesEarned > 0) {
            uint256 usdcBefore = USDC.balanceOf(address(this));
            VAULT.withdraw(sharesEarned);
            uint256 usdcAfter = USDC.balanceOf(address(this));
            uint256 usdcReturned = usdcAfter - usdcBefore;
            if (usdcReturned > 0) {
                USDC.transfer(d.depositor, usdcReturned);
            }
        }

        d.active = false;
        emit DripCancelled(dripId, d.depositor, remainingUSDC, sharesEarned);
    }

    // --- Claim shares after drip completes ---
    /// @notice After drip completes (or is held), depositor claims their vault position
    function claimShares(uint256 dripId) external {
        Drip storage d = drips[dripId];
        if (msg.sender != d.depositor) revert OnlyDepositor();
        if (d.active) revert DripNotComplete();

        uint256 sharesEarned = VAULT.shares(address(this)) - d.sharesAtStart;
        if (sharesEarned == 0) revert NoSharesToClaim();

        // Withdraw from vault and return as USDC
        uint256 usdcBefore = USDC.balanceOf(address(this));
        VAULT.withdraw(sharesEarned);
        uint256 usdcAfter = USDC.balanceOf(address(this));
        uint256 usdcOut = usdcAfter - usdcBefore;

        if (usdcOut > 0) {
            USDC.transfer(d.depositor, usdcOut);
        }

        d.sharesAtStart = VAULT.shares(address(this)); // reset accounting
        emit SharesClaimed(dripId, d.depositor, sharesEarned, usdcOut);
    }

    // --- View: drip progress ---
    function getDripInfo(uint256 dripId) external view returns (
        address depositor,
        uint256 totalUSDC,
        uint256 drippedUSDC,
        uint256 remainingUSDC,
        uint256 sharesEarned,
        bool active,
        uint256 retryCount
    ) {
        Drip storage d = drips[dripId];
        return (
            d.depositor,
            d.totalUSDC,
            d.drippedUSDC,
            d.totalUSDC - d.drippedUSDC,
            VAULT.shares(address(this)) - d.sharesAtStart,
            d.active,
            d.retryCount
        );
    }

    // --- View: current chunk size ---
    function currentChunkSize() external view returns (uint256) {
        return _computeChunkSize();
    }

    // --- Internal: compute chunk size ---
    /// @dev Uses 90% of vault.maxInstantDeposit() as the safe chunk size.
    ///      maxInstantDeposit is the max deposit at vault's maxImpactBps (5%).
    ///      For 3% guard, we scale down: maxInstantDeposit * (300/500) * 0.9
    function _computeChunkSize() internal view returns (uint256) {
        uint256 maxInstant = VAULT.maxInstantDeposit();
        uint256 vaultImpactBps = VAULT.maxImpactBps(); // 500 = 5%
        
        // Scale from vault's impact to our 3% guard
        // If vault allows 5% impact for maxInstant, then at 3% we get maxInstant * (300/500)
        uint256 scaledMax = (maxInstant * MAX_SLIPPAGE_BPS) / vaultImpactBps;
        
        // Apply 90% safety margin
        return (scaledMax * MAX_CHUNK_BPS) / 10000;
    }

    // --- Admin: rescue (emergency only) ---
    function rescue(address to) external onlyKeeper {
        uint256 usdcBalance = USDC.balanceOf(address(this));
        if (usdcBalance > 0) {
            USDC.transfer(to, usdcBalance);
        }
    }
}
