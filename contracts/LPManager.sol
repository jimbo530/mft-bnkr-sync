// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
  LPManager — per-token fee router that builds a LOCKED Token/Money LP floor.
  DRAFT-1 (uncompiled; to be compile-checked + fork-tested + hardened before any deploy).

  Flow: set this as a launched token's FEE RECIPIENT. compound() converts accrued TOKEN
  fees into a TOKEN/MONEY V2 LP and HOLDS it. Admin can recover during build; renounce
  locks the LP forever = the permanent charity-liquidity floor.

  MONEY = CharityFund (VERIFIED): depositFor(to, usdc) mints Money 1:1 (USDC -> Aave),
  redeem 1:1 back; charity earns the Aave yield. So the LP's Money side is USDC-backed.

  SAFETY: exact approvals (never MaxUint256) · live-quoted slippage (never hardcoded) ·
  reentrancy-guarded · no silent catches · renounce-capable (build withdrawable -> lock at ship).

  TODO before ship (do NOT renounce until these land):
   - harden addLiquidity mins (quote/TWAP guard; draft uses 0 = fine only while adminWithdraw is live)
   - confirm fee-accrual token(s) vs a real BNKR launch (TOKEN only, or TOKEN+WETH)
   - RH port: swap venue V2->V4 + MONEY->GST (see LAUNCHER-FEE-ROUTER-SPEC.md)
*/

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}
interface IV2Router {
    function factory() external view returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256, uint256, uint256);
}
interface IV2Factory { function getPair(address, address) external view returns (address); }
interface ICharityFund { function depositFor(address to, uint256 amount) external; } // USDC -> Money 1:1

contract LPManager {
    address public admin;
    bool    public renounced;           // one-way: once true, adminWithdraw is dead forever

    address public immutable TOKEN;     // the launched token (Xtoken)
    address public immutable MONEY;     // mftUSD / CharityFund
    address public immutable USDC;
    address public immutable WETH;
    IV2Router public immutable router;

    uint16  public slippageBps = 300;   // 3% on swaps; admin-settable while not renounced
    uint256 public minCompound;         // dust guard (TOKEN units)
    uint256 private _lock;

    event Compounded(address indexed caller, uint256 tokenIn, uint256 moneyMade, uint256 liquidity);
    event AdminWithdraw(address indexed token, uint256 amount, address to);
    event Renounced();

    modifier onlyAdmin() { require(msg.sender == admin, "not admin"); _; }
    modifier nonReentrant() { require(_lock == 0, "reentry"); _lock = 1; _; _lock = 0; }

    constructor(address _token, address _money, address _usdc, address _weth, address _router, uint256 _minCompound) {
        require(_token != address(0) && _money != address(0) && _usdc != address(0) && _weth != address(0) && _router != address(0), "zero addr");
        admin = msg.sender;
        TOKEN = _token; MONEY = _money; USDC = _usdc; WETH = _weth;
        router = IV2Router(_router);
        minCompound = _minCompound;
    }

    /// @notice Permissionless. Converts accrued TOKEN fees into TOKEN/MONEY LP held by this contract (the buy machine).
    function compound() external nonReentrant returns (uint256 liquidity) {
        uint256 tokenBal = IERC20(TOKEN).balanceOf(address(this));
        require(tokenBal >= minCompound && tokenBal > 1, "nothing to compound");

        uint256 half = tokenBal / 2;
        uint256 moneyMade = _toMoney(half);                 // TOKEN -> MONEY (direct if pair liquid, else via USDC mint)

        uint256 tokenForLp = IERC20(TOKEN).balanceOf(address(this));
        uint256 moneyForLp = IERC20(MONEY).balanceOf(address(this));
        _approveExact(TOKEN, address(router), tokenForLp);
        _approveExact(MONEY, address(router), moneyForLp);
        ( , , liquidity) = router.addLiquidity(
            TOKEN, MONEY, tokenForLp, moneyForLp,
            0, 0,                                           // TODO harden (see header) — safe while adminWithdraw live
            address(this),                                  // LP held here: recoverable until renounce
            block.timestamp
        );
        emit Compounded(msg.sender, tokenBal, moneyMade, liquidity);
    }

    function _toMoney(uint256 tokenAmount) internal returns (uint256 moneyOut) {
        address pair = IV2Factory(router.factory()).getPair(TOKEN, MONEY);
        bool direct = pair != address(0) && IERC20(MONEY).balanceOf(pair) > 0 && IERC20(TOKEN).balanceOf(pair) > 0;
        uint256 before = IERC20(MONEY).balanceOf(address(this));

        if (direct) {
            address[] memory path = new address[](2);
            path[0] = TOKEN; path[1] = MONEY;
            _approveExact(TOKEN, address(router), tokenAmount);
            router.swapExactTokensForTokens(tokenAmount, _minOut(tokenAmount, path), path, address(this), block.timestamp);
        } else {
            // bootstrap: TOKEN -> WETH -> USDC, then depositFor -> MONEY 1:1 (USDC -> Aave, charity earns yield)
            address[] memory path = new address[](3);
            path[0] = TOKEN; path[1] = WETH; path[2] = USDC;
            _approveExact(TOKEN, address(router), tokenAmount);
            uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));
            router.swapExactTokensForTokens(tokenAmount, _minOut(tokenAmount, path), path, address(this), block.timestamp);
            uint256 usdcGot = IERC20(USDC).balanceOf(address(this)) - usdcBefore;
            _approveExact(USDC, MONEY, usdcGot);
            ICharityFund(MONEY).depositFor(address(this), usdcGot);
        }
        moneyOut = IERC20(MONEY).balanceOf(address(this)) - before;
        require(moneyOut > 0, "no money made");
    }

    function _minOut(uint256 amountIn, address[] memory path) internal view returns (uint256) {
        uint256[] memory amts = router.getAmountsOut(amountIn, path);   // live quote — never hardcoded
        return amts[amts.length - 1] * (10000 - slippageBps) / 10000;
    }

    function _approveExact(address t, address spender, uint256 amount) internal {
        IERC20(t).approve(spender, 0);                                  // reset, then exact (never MaxUint256)
        IERC20(t).approve(spender, amount);
    }

    // ---- admin / one-way renounce ----
    function setSlippageBps(uint16 bps) external onlyAdmin { require(!renounced, "renounced"); require(bps <= 1000, "max 10%"); slippageBps = bps; }
    function setMinCompound(uint256 v) external onlyAdmin { require(!renounced, "renounced"); minCompound = v; }

    /// @notice Build-time escape hatch. Recover any token (incl. the LP) — ONLY while not renounced.
    function adminWithdraw(address token, uint256 amount, address to) external onlyAdmin nonReentrant {
        require(!renounced, "renounced: locked forever");
        require(to != address(0), "zero to");
        require(IERC20(token).transfer(to, amount), "transfer failed");
        emit AdminWithdraw(token, amount, to);
    }

    /// @notice ONE-WAY. After this, adminWithdraw is dead and the LP is locked forever = the floor.
    function renounceAdminWithdraw() external onlyAdmin {
        renounced = true;
        admin = address(0);
        emit Renounced();
    }
}
