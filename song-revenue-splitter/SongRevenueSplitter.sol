// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SongRevenueSplitter — song-booth revenue router for ONE band.
/// @notice Holds a band's song-booth revenue (BAND tokens) and split()s it 50/50:
///   - 50% DEEPENS the band's LP: sell half of it -> Money, addLiquidity(Money, BAND)
///   - 50% -> Money -> paid to the OPS WALLET (real-world bills)
/// Payment IN (mint Money -> buy BAND; 10,000 BAND = 1 song) happens upstream in BNKR; this
/// contract only routes the 10,000 BAND per song. No burn. Build-phase escape hatch is
/// renounce-capable (one-way) so the splitter is provably locked at ship.
/// Swap + addLiquidity pattern reused from CommunityLPVaultV3.sol (V2, BAND/Money pair).

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}
interface IUniswapV2Router02 {
    function addLiquidity(address, address, uint256, uint256, uint256, uint256, address, uint256)
        external returns (uint256, uint256, uint256);
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256)
        external returns (uint256[] memory);
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
}

contract SongRevenueSplitter {
    address public immutable BAND;       // band token (e.g. EBM, NN)
    address public immutable MONEY;      // Money for Trees (LP pair + ops payout asset)
    address public immutable LP;         // BAND/Money V2 pair
    address public immutable opsWallet;  // real-world bills (project wallet 0x0780...)
    IUniswapV2Router02 public immutable v2Router;
    bool public immutable moneyIsToken0;

    address public admin;
    uint256 public maxImpactBps = 800;               // 8% swap slippage cap
    uint256 public constant MAX_IMPACT_CAP = 1500;   // 15% hard cap
    bool public adminWithdrawRenounced;              // one-way ship-time lock

    uint256 private _locked = 1;
    modifier nonReentrant() { require(_locked == 1, "reentrant"); _locked = 2; _; _locked = 1; }
    modifier onlyAdmin() { require(msg.sender == admin, "not admin"); _; }

    event Split(uint256 bandIn, uint256 lpAdded, uint256 moneyToOps);
    event MaxImpactChanged(uint256 oldBps, uint256 newBps);
    event AdminTransferred(address indexed prev, address indexed next);
    event AdminWithdrawRenounced();

    constructor(address _band, address _money, address _lp, address _v2Router, address _ops, address _admin) {
        require(_band != address(0) && _money != address(0) && _lp != address(0)
             && _v2Router != address(0) && _ops != address(0), "zero addr");
        BAND = _band; MONEY = _money; LP = _lp; v2Router = IUniswapV2Router02(_v2Router); opsWallet = _ops;
        admin = _admin == address(0) ? msg.sender : _admin;
        moneyIsToken0 = IUniswapV2Pair(_lp).token0() == _money;
        IERC20(_band).approve(_v2Router, type(uint256).max);
        IERC20(_money).approve(_v2Router, type(uint256).max);
    }

    /// @notice Route ALL BAND held here: 50% -> deepen the LP, 50% -> Money -> ops. Permissionless.
    function split() external nonReentrant returns (uint256 lpAdded, uint256 moneyToOps) {
        uint256 bal = IERC20(BAND).balanceOf(address(this));
        require(bal > 3, "nothing to split");
        uint256 halfA = bal / 2;          // LP leg
        uint256 halfB = bal - halfA;      // ops leg

        // LP leg: sell half of halfA -> Money, then addLiquidity(Money, BAND) with the rest.
        uint256 sellForLp = halfA / 2;
        uint256 keepForLp = halfA - sellForLp;
        uint256 moneyForLp = _swap(BAND, MONEY, sellForLp);
        (,, lpAdded) = v2Router.addLiquidity(MONEY, BAND, moneyForLp, keepForLp, 0, 0, address(this), block.timestamp);

        // Ops leg: sell halfB -> Money, then pay the ops wallet ALL Money now held (ops proceeds + any dust).
        _swap(BAND, MONEY, halfB);
        moneyToOps = IERC20(MONEY).balanceOf(address(this));
        if (moneyToOps > 0) _safeTransfer(MONEY, opsWallet, moneyToOps);

        emit Split(bal, lpAdded, moneyToOps);
    }

    // ── admin config ──
    function setMaxImpact(uint256 bps) external onlyAdmin {
        require(bps > 0 && bps <= MAX_IMPACT_CAP, "invalid");
        emit MaxImpactChanged(maxImpactBps, bps); maxImpactBps = bps;
    }
    function transferAdmin(address next) external onlyAdmin {
        require(next != address(0), "zero"); emit AdminTransferred(admin, next); admin = next;
    }

    // ── build-phase escape hatch, renounce-capable at ship ──
    /// @notice Recover tokens during build (misconfig / stuck swap). Disabled FOREVER after renounce.
    function adminWithdraw(address token, uint256 amount) external onlyAdmin {
        require(!adminWithdrawRenounced, "renounced");
        _safeTransfer(token, admin, amount);
    }
    /// @notice One-way: permanently disable adminWithdraw. Call at ship to make the splitter trustless.
    function renounceAdminWithdraw() external onlyAdmin {
        adminWithdrawRenounced = true; emit AdminWithdrawRenounced();
    }

    // ── internal ──
    function _swap(address from, address to, uint256 amt) internal returns (uint256 out) {
        if (amt == 0) return 0;
        address[] memory path = new address[](2);
        path[0] = from; path[1] = to;
        uint256 minOut = _minOut(amt, from == MONEY); // true = money->band, false = band->money
        uint256[] memory amounts = v2Router.swapExactTokensForTokens(amt, minOut, path, address(this), block.timestamp);
        return amounts[1];
    }
    /// @dev constant-product min-out with slippage tolerance, from the BAND/Money reserves.
    function _minOut(uint256 amt, bool moneyToBand) internal view returns (uint256) {
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(LP).getReserves();
        uint256 rIn; uint256 rOut;
        if (moneyToBand) { rIn = moneyIsToken0 ? r0 : r1; rOut = moneyIsToken0 ? r1 : r0; }
        else             { rIn = moneyIsToken0 ? r1 : r0; rOut = moneyIsToken0 ? r0 : r1; }
        require(rIn > 0 && rOut > 0, "pool empty");
        uint256 aFee = amt * 997;
        uint256 expected = (aFee * rOut) / (rIn * 1000 + aFee);
        return expected * (10000 - maxImpactBps) / 10000;
    }
    function _safeTransfer(address token, address to, uint256 amt) internal {
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amt));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");
    }

    // ── views ──
    function pending() external view returns (uint256) { return IERC20(BAND).balanceOf(address(this)); }
}
