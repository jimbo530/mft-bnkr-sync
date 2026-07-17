// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IAaveV3Pool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

/// @title CourtEndowment — a permanent, per-tier court endowment for the medieval Acorn game.
/// @notice ONE deployable instance per court tier (Mayor / Lord / Petty King / High King / Emperor).
///
///         Tribute is received as PRINCIPAL: USDC is supplied to Aave and the endowment grows
///         FOREVER. There is deliberately NO function that withdraws the principal — this is a
///         permanent endowment, like a college fund that only ever spends its interest.
///
///         harvest(minCbBtcOut) is KEEPER-GATED (sandwich protection — the keeper supplies a
///         live-quoted, BINDING minCbBtcOut, never a floor-of-1). It:
///           1. computes the Aave yield  = aUSDC balance - principal owed
///           2. withdraws ONLY that yield as USDC
///           3. swaps USDC -> cbBTC on the verified Uniswap V3 0.05% pool
///           4. transfers 100% of the cbBTC bought to the configured `prizePool`.
///
///         The endowment pays NO depositor and NO owner. It is a one-way funnel: tribute in
///         (principal, permanent), cbBTC yield out (to the prize pool). The achievement prize
///         pool — and the rules for who wins — live entirely in the separate PrizePool contract,
///         which can be reconfigured/extended over time without touching the endowment.
///
///         ROUTE NOTE (mirrors MayorVault): there is NO Money/cbBTC pool on Base. The buy-leg
///         therefore swaps USDC -> cbBTC DIRECTLY on the deep USDC/cbBTC 0.05% Uniswap V3 pool
///         (0xfBB6Eed8e7aa03B138556eeDaF5D271A5E1e43ef).
///
///         No upgrades. No admin over funds. Keepers can ONLY trigger harvests. `prizePool` is
///         set ONCE (add-only / one-time settable) so the endowment can be deployed before the
///         pool and wired afterward — then it is locked forever.
contract CourtEndowment is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ======================== IMMUTABLES ========================

    string  public tierName;                  // immutable label, e.g. "Emperor" (set once in ctor)
    IERC20        public immutable usdc;
    IAaveV3Pool   public immutable aavePool;
    IERC20        public immutable aUsdc;
    IERC20        public immutable cbBtc;      // payout token bought every harvest (8 decimals)
    ISwapRouter02 public immutable v3Router;   // Uniswap V3 SwapRouter02
    uint24        public immutable poolFee;    // USDC/cbBTC pool fee, e.g. 500 (0.05%)

    // Harvest keepers (sandwich protection). Immutable, no other powers.
    address public immutable keeperA;
    address public immutable keeperB;
    address public immutable keeperC;

    // ======================== PRIZE POOL (one-time settable) ========================

    /// @notice The cbBTC sink: every harvest sends 100% of bought cbBTC here. Set ONCE, then locked.
    address public prizePool;
    /// @notice Who may set prizePool the one time it is unset (the deployer). No other powers.
    address public immutable wirer;

    // ======================== ACCOUNTING ========================

    /// @notice Cumulative USDC tribute supplied as principal. The endowment NEVER returns this.
    ///         Used as the yield baseline: yield = aUSDC balance - principal.
    uint256 public principal;

    // Tracking (telemetry only)
    uint256 public totalYieldHarvested; // cumulative USDC yield processed
    uint256 public totalCbBtcToPool;    // cumulative cbBTC sent to the prize pool

    uint256 public constant MIN_HARVEST = 100_000; // $0.10 — avoids dust swaps

    // ======================== EVENTS ========================

    event Tribute(address indexed from, uint256 amount, uint256 newPrincipal);
    event PrizePoolSet(address indexed prizePool);
    event Harvest(address indexed caller, uint256 yieldAmount, uint256 cbBtcBought, address indexed prizePool);
    event Swept(uint256 amount);

    // ======================== CONSTRUCTOR ========================

    constructor(
        string memory _tierName,   // e.g. "Mayor" / "Lord" / "PettyKing" / "HighKing" / "Emperor"
        address _usdc,
        address _aavePool,
        address _aUsdc,
        address _cbBtc,
        address _v3Router,
        uint24  _poolFee,          // USDC/cbBTC pool fee (e.g. 500)
        address _prizePool,        // may be address(0) to wire later via setPrizePool
        address _wirer,            // who may set prizePool once (typically the deployer/curator)
        address _keeperA,
        address _keeperB,
        address _keeperC
    ) {
        require(bytes(_tierName).length > 0, "zero tier");
        require(_usdc != address(0), "zero usdc");
        require(_aavePool != address(0), "zero aavePool");
        require(_aUsdc != address(0), "zero aUsdc");
        require(_cbBtc != address(0), "zero cbBtc");
        require(_v3Router != address(0), "zero router");
        require(_poolFee > 0, "zero fee");
        require(_wirer != address(0), "zero wirer");
        require(_keeperA != address(0) && _keeperB != address(0) && _keeperC != address(0), "zero keeper");

        tierName = _tierName;
        usdc = IERC20(_usdc);
        aavePool = IAaveV3Pool(_aavePool);
        aUsdc = IERC20(_aUsdc);
        cbBtc = IERC20(_cbBtc);
        v3Router = ISwapRouter02(_v3Router);
        poolFee = _poolFee;
        wirer = _wirer;
        keeperA = _keeperA;
        keeperB = _keeperB;
        keeperC = _keeperC;

        // Optional: wire the prize pool at construction. Otherwise set once later.
        if (_prizePool != address(0)) {
            prizePool = _prizePool;
            emit PrizePoolSet(_prizePool);
        }
    }

    // ======================== PRIZE POOL WIRING (one-time) ========================

    /// @notice Set the prize pool ONCE if it was not provided at construction. After it is set,
    ///         this can never be called again — the cbBTC sink is locked forever. Add-only.
    function setPrizePool(address _prizePool) external {
        require(msg.sender == wirer, "not wirer");
        require(prizePool == address(0), "already set");
        require(_prizePool != address(0), "zero pool");
        prizePool = _prizePool;
        emit PrizePoolSet(_prizePool);
    }

    // ======================== TRIBUTE (principal, permanent) ========================

    /// @notice Send USDC tribute to the endowment as PRINCIPAL. Supplied to Aave; grows forever.
    ///         Permissionless — anyone (a game contract, a UI, a patron) may grow the endowment.
    ///         This USDC can NEVER be withdrawn: only its yield is ever spent.
    function tribute(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        usdc.forceApprove(address(aavePool), amount); // exact approval per tx
        aavePool.supply(address(usdc), amount, address(this), 0);
        principal += amount;
        emit Tribute(msg.sender, amount, principal);
    }

    // ======================== HARVEST (keeper-gated; yield -> cbBTC -> prize pool) ========================

    /// @notice Process accrued Aave yield: withdraw the yield as USDC, swap USDC -> cbBTC on the
    ///         verified 0.05% pool, and transfer 100% of the cbBTC to the prize pool.
    ///         Keeper-only — the keeper computes minCbBtcOut from live prices (QuoterV2) so the
    ///         swap can't be sandwiched. The principal is never touched.
    /// @param minCbBtcOut Live-quoted minimum cbBTC out for the swap (BINDING — never floor-of-1).
    function harvest(uint256 minCbBtcOut) external nonReentrant {
        require(msg.sender == keeperA || msg.sender == keeperB || msg.sender == keeperC, "!keeper");
        require(minCbBtcOut > 0, "zero minOut");
        address pool = prizePool;
        require(pool != address(0), "prize pool unset");

        // Yield = current aUSDC balance - principal owed. Principal stays in Aave, untouched.
        uint256 backing = aUsdc.balanceOf(address(this));
        require(backing > principal, "no yield");
        uint256 yieldAmount = backing - principal;
        require(yieldAmount >= MIN_HARVEST, "below min harvest");

        // Withdraw ONLY the yield as USDC.
        aavePool.withdraw(address(usdc), yieldAmount, address(this));

        // Swap USDC -> cbBTC on the verified direct pool.
        usdc.forceApprove(address(v3Router), yieldAmount); // exact approval per tx
        uint256 cbBtcBefore = cbBtc.balanceOf(address(this));
        v3Router.exactInputSingle(ISwapRouter02.ExactInputSingleParams({
            tokenIn: address(usdc),
            tokenOut: address(cbBtc),
            fee: poolFee,
            recipient: address(this),
            amountIn: yieldAmount,
            amountOutMinimum: minCbBtcOut, // BINDING live-quoted minimum — never floor-of-1
            sqrtPriceLimitX96: 0
        }));
        uint256 cbBtcReceived = cbBtc.balanceOf(address(this)) - cbBtcBefore;
        require(cbBtcReceived > 0, "swap returned zero");

        // Funnel 100% of the cbBTC to the prize pool.
        cbBtc.safeTransfer(pool, cbBtcReceived);

        totalYieldHarvested += yieldAmount;
        totalCbBtcToPool += cbBtcReceived;

        emit Harvest(msg.sender, yieldAmount, cbBtcReceived, pool);
    }

    /// @notice Push any stray USDC sitting on this contract into Aave as additional PRINCIPAL.
    ///         Permissionless. Folds dust/airdropped USDC into the permanent endowment so it can
    ///         never be mistaken for yield. (cbBTC is never held here beyond a single harvest tx.)
    function sweep() external nonReentrant {
        uint256 raw = usdc.balanceOf(address(this));
        require(raw > 0, "nothing to sweep");
        usdc.forceApprove(address(aavePool), raw);
        aavePool.supply(address(usdc), raw, address(this), 0);
        principal += raw;
        emit Swept(raw);
    }

    // ======================== VIEWS (for UI) ========================

    /// @notice USDC yield accrued but not yet harvested.
    function pendingYield() external view returns (uint256) {
        uint256 backing = aUsdc.balanceOf(address(this));
        return backing > principal ? backing - principal : 0;
    }

    /// @notice Total USDC backing currently in Aave (principal + un-harvested yield).
    function totalBacking() external view returns (uint256) {
        return aUsdc.balanceOf(address(this));
    }
}
