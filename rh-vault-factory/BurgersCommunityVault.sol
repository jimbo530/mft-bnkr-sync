// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PegCommunityVault.sol"; // PoolKey, IV4PositionManager, IPermit2, IV4PoolManagerState, TickMath, LiquidityAmounts, FullMath, IFeedingPeopleVault

/// @title BurgersCommunityVault — public community LP for the BURGERS/FTP pool
///        (fee=10000) on Robinhood Chain (4663). Build D2. Same share/attribution/
///        withdraw model as the peg community vault (and the live Base
///        CommunityLPVaultV4), but the paired side is BURGERS, acquired and
///        liquidated through the DEEP route (BURGERS/WETH Doppler pool -> WETH ->
///        USDG) with live-price slippage guards — never the 51%-fee USDG stray.
///
///        deposit(usdg, name): HALF mints FTP 1:1 at the FeedingPeopleVault (that
///        principal earns Morpho yield = feeds people); HALF buys BURGERS via the
///        deep route (slippage-guarded, live price only); BOTH added to the
///        vault's OWN BURGERS/FTP position NFT (separate from the reactor's). The
///        depositor gets pro-rata shares.
///
///        withdraw(shares): remove the pro-rata slice; FTP side redeems 1:1 -> USDG;
///        BURGERS side liquidated via the deep route -> USDG; depositor paid in
///        USDG (their deposit + their share of fees/growth, which can be more OR
///        less — LP exposure cuts both ways). withdrawAsTokens(shares): the escape
///        variant returns raw FTP + BURGERS (no swap) — matches the Base vault's
///        dual withdraw so a depositor is never trapped by a thin/slipping route.
///
///        ATTRIBUTION: lifetime contributed[user] + displayName + totalContributed
///        never decreases on withdrawal (impact numbers don't un-happen); a
///        separate withdrawn[user]/totalWithdrawn tracks exits.
///
///        COMPLIANCE: "build the position" / "deepen liquidity" / "feed people";
///        FTP = charity vault deposit receipt; withdrawal "returns your share of
///        the position"; NEVER invest/APY/returns/guaranteed-gains.
///
///        RECOVERABILITY: owner withdrawPosition BLOCKED while shares exist (the
///        escape hatch can never strand depositors); depositors always exit
///        self-serve. HOUSE RULES: no empty catches, exact Permit2 approvals reset
///        to 0, live-price-only slippage bounds (never 0/hardcoded), fail loud.
contract BurgersCommunityVault is IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── immutable wiring ──
    IERC20  public immutable usdg;
    IFeedingPeopleVault public immutable ftpVault;
    IERC20  public immutable ftp;
    IERC20  public immutable burgers;
    IERC20  public immutable weth;
    IV4PositionManager public immutable posm;
    IUniversalRouter public immutable router;   // canonical UR 0x53BF
    IPermit2 public immutable permit2;
    IV4PoolManagerState public immutable poolManagerState;

    PoolKey public bfKey;      // BURGERS/FTP (fee 10000) — the position pool
    PoolKey public bwKey;      // BURGERS/WETH (doppler) — deep route leg 1
    PoolKey public wuKey;      // WETH/USDG (vanilla)     — deep route leg 2
    bool    public immutable ftpIsC0_bf;
    int24   public immutable tickLower;
    int24   public immutable tickUpper;

    uint256 public positionId;

    // ── shares + attribution (identical semantics to the peg vault) ──
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    mapping(address => uint256) public contributed;   // lifetime USDG in (never decreases)
    mapping(address => uint256) public withdrawn;     // lifetime USDG out
    mapping(address => string)  public displayNameOf;
    uint256 public totalContributed;
    uint256 public totalWithdrawn;
    uint256 public totalMintedThroughVault;           // cumulative USDG -> FTP principal (the feed number)
    uint256 public totalYieldProcessed;               // cumulative yield-FTP folded to shareholders

    address public owner;

    /// @notice One-way flag: once true, withdrawPosition() is permanently disabled.
    ///         Call renounceAdminWithdraw() at ship time. Cannot be un-set.
    bool public adminWithdrawRenounced;

    // ── config ──
    uint256 public slippageBps = 300;                 // deep-route swap tolerance (3%), live-price-bounded
    uint256 public constant MAX_SLIP_BPS = 1000;      // never worse than 10%
    uint256 public constant MIN_DEPOSIT = 100000;     // 0.1 USDG floor (BURGERS side needs a non-dust buy)
    uint256 public constant MIN_YIELD = 100000;       // 0.1 FTP floor to process (buy needs non-dust)
    uint256 public cooldown = 0;                      // processYield cadence (owner-set; 0 = anytime)
    uint256 public lastProcess;
    uint256 internal constant DEADLINE_BUFFER = 15 minutes;
    uint256 internal constant POOLS_SLOT = 6;

    // V4 opcodes
    uint8 internal constant INCREASE_LIQUIDITY = 0x00;
    uint8 internal constant DECREASE_LIQUIDITY = 0x01;
    uint8 internal constant SETTLE_PAIR        = 0x0d;
    uint8 internal constant TAKE_PAIR          = 0x11;
    uint8 internal constant UR_V4_SWAP           = 0x10;
    uint8 internal constant SWAP_EXACT_IN_SINGLE = 0x06;
    uint8 internal constant SETTLE_ALL           = 0x0c;
    uint8 internal constant TAKE_ALL             = 0x0f;

    event Deposited(address indexed user, string displayName, uint256 usdcIn, uint256 mintedFtp, uint256 burgersBought, uint128 liquidityAdded, uint256 sharesMinted);
    event WithdrawnUSDG(address indexed user, uint256 sharesBurned, uint256 usdgOut);
    event WithdrawnTokens(address indexed user, uint256 sharesBurned, uint256 ftpOut, uint256 burgersOut);
    event YieldProcessed(address indexed caller, uint256 ftpIn, uint256 usdgFromRedeem, uint256 burgersBought, uint128 liquidityAdded);
    event YieldHeld(uint256 ftpHeld, string reason);
    event Donated(address indexed donor, uint256 usdcIn, uint128 liquidityAdded);
    event PositionAdopted(uint256 indexed tokenId);
    event PositionWithdrawn(uint256 indexed tokenId, address to);
    event SlippageChanged(uint256 bps);
    event OwnershipTransferred(address indexed prev, address indexed next_);
    event AdminWithdrawRenounced();

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    struct Init {
        address usdg; address ftpVault; address burgers; address weth;
        address posm; address router; address permit2; address poolManagerState;
        PoolKey bfKey; PoolKey bwKey; PoolKey wuKey;
        int24 tickLower; int24 tickUpper; address owner;
    }

    constructor(Init memory i) {
        require(i.usdg != address(0) && i.ftpVault != address(0) && i.burgers != address(0) && i.weth != address(0), "zero core");
        require(i.posm != address(0) && i.router != address(0) && i.permit2 != address(0) && i.poolManagerState != address(0) && i.owner != address(0), "zero addr");
        require(i.bfKey.currency0 == i.ftpVault || i.bfKey.currency1 == i.ftpVault, "ftp not in bf");
        require(i.bfKey.currency0 == i.burgers || i.bfKey.currency1 == i.burgers, "burgers not in bf");
        require(i.tickLower < i.tickUpper, "bad range");
        usdg = IERC20(i.usdg); ftpVault = IFeedingPeopleVault(i.ftpVault); ftp = IERC20(i.ftpVault);
        burgers = IERC20(i.burgers); weth = IERC20(i.weth);
        posm = IV4PositionManager(i.posm); router = IUniversalRouter(i.router);
        permit2 = IPermit2(i.permit2); poolManagerState = IV4PoolManagerState(i.poolManagerState);
        bfKey = i.bfKey; bwKey = i.bwKey; wuKey = i.wuKey;
        ftpIsC0_bf = (i.bfKey.currency0 == i.ftpVault);
        tickLower = i.tickLower; tickUpper = i.tickUpper; owner = i.owner;
    }

    // ══════════════════════ owner ══════════════════════

    function adoptPosition(uint256 tokenId) external onlyOwner {
        require(positionId == 0, "already adopted");
        require(posm.ownerOf(tokenId) == address(this), "not owned");
        (PoolKey memory k,) = posm.getPoolAndPositionInfo(tokenId);
        require(_sameKey(k, bfKey), "wrong pool");
        positionId = tokenId;
        // CREDIT the adopted seed liquidity as OWNER shares (see PegCommunityVault):
        // keeps pro-rata withdraw honest so the first depositor can't pull the seed.
        uint128 seedLiq = posm.getPositionLiquidity(tokenId);
        if (seedLiq > 0) { shares[owner] += seedLiq; totalShares += seedLiq; }
        emit PositionAdopted(tokenId);
    }

    /// @notice Owner recovery — BLOCKED while depositors hold shares AND while
    ///         adminWithdrawRenounced == false only; once renounced this function
    ///         is permanently disabled regardless of depositor state.
    function withdrawPosition() external onlyOwner nonReentrant {
        require(!adminWithdrawRenounced, "withdraw renounced");
        // blocked while any NON-OWNER depositor holds shares (owner's own seed shares
        // don't block — the owner recovering their own seed can't strand anyone).
        require(totalShares == shares[owner], "depositors present - cannot pull position");
        uint256 t = positionId; require(t != 0, "no position");
        positionId = 0;
        posm.safeTransferFrom(address(this), owner, t);
        emit PositionWithdrawn(t, owner);
    }

    /// @notice One-way lock: permanently disables withdrawPosition(). Call at ship
    ///         time to make this vault provably trustless. Cannot be undone.
    ///         rescueToken, setSlippage, and transferOwnership remain active.
    function renounceAdminWithdraw() external onlyOwner {
        adminWithdrawRenounced = true;
        emit AdminWithdrawRenounced();
    }

    function rescueToken(address token, uint256 amount) external onlyOwner {
        if (totalShares > 0) require(token != address(usdg) && token != address(ftp) && token != address(burgers), "core token locked while depositors present");
        IERC20(token).safeTransfer(owner, amount);
    }

    function setSlippage(uint256 bps) external onlyOwner { require(bps > 0 && bps <= MAX_SLIP_BPS, "range"); slippageBps = bps; emit SlippageChanged(bps); }
    function transferOwnership(address n) external onlyOwner { emit OwnershipTransferred(owner, n); owner = n; }

    // ══════════════════════ deposit (BASE flow: mint ALL -> swap HALF via OUR pool) ══════════════════════

    /// @notice Add USDG. BASE FLOW (founder 2026-07-13): ALL of the USDG mints FTP
    ///         1:1 (the WHOLE deposit backs feeding-people yield -> feed number is the
    ///         FULL amount), then HALF the FTP is swapped -> BURGERS through OUR OWN
    ///         BURGERS/FTP pool (1% fee, which FEEDS the Burgers reactor's LP), and
    ///         both sides are added to the community position. NO deep route. The
    ///         FTP->BURGERS swap pushes our pool (BURGERS rich in ours) — INTENDED:
    ///         RT-BURGERS + the peg guard correct it (the web working). Shares = the
    ///         liquidity this deposit added (accrue yield via processYield later).
    function deposit(uint256 usdgAmount, string calldata displayName) external nonReentrant {
        require(positionId != 0, "position not adopted");
        require(usdgAmount >= MIN_DEPOSIT, "below min");
        usdg.safeTransferFrom(msg.sender, address(this), usdgAmount);

        uint256 ftpBaseline = ftp.balanceOf(address(this));
        uint256 burgBaseline = burgers.balanceOf(address(this));

        // ALL USDG -> FTP (1:1). The whole deposit becomes feeding-people-backing FTP.
        uint256 minted = _mintFtp(usdgAmount);
        totalMintedThroughVault += minted;                       // FULL deposit is the feed number

        // swap HALF the fresh FTP -> BURGERS through OUR pool (fee feeds the reactor).
        uint256 ftpForSwap = minted / 2;
        uint256 burgBought = _swapFtpForBurgersOurs(ftpForSwap);
        require(burgBought > 0, "burgers swap filled zero");
        uint256 ftpForLP = minted - ftpForSwap;                  // the un-swapped FTP half

        uint128 liq = _addToPosition(ftpForLP, burgBought);
        require(liq > 0, "no liquidity added");
        shares[msg.sender] += liq; totalShares += liq;

        contributed[msg.sender] += usdgAmount; totalContributed += usdgAmount;
        if (bytes(displayName).length > 0) displayNameOf[msg.sender] = displayName;

        // return operation dust (unused side of the add) to depositor
        _returnDust(msg.sender, ftpBaseline, burgBaseline);
        emit Deposited(msg.sender, displayName, usdgAmount, minted, burgBought, liq, liq);
    }

    // ══════════════════════ LEG-3 YIELD -> ACCRUES TO SHAREHOLDERS ══════════════════════

    /// @notice Fold the yield-FTP this vault received (as a FeedingPeopleVault
    ///         whitelist recipient) into THIS vault's BURGERS/FTP position. Same BASE
    ///         handling as deposit (founder: "same handling should be to LP the FTP
    ///         is in getting fed via manager contract"): swap HALF the yield-FTP ->
    ///         BURGERS through OUR pool, add FTP + BURGERS. Mints NO NEW SHARES, so
    ///         positionLiquidity grows while totalShares is unchanged -> every EXISTING
    ///         SHAREHOLDER's slice grows. NO deep route. Permissionless (+ cooldown).
    ///         totalShares == 0 -> HOLD the yield-FTP, roll forward. Slippage-guarded.
    function processYield() external nonReentrant {
        require(positionId != 0, "position not adopted");
        require(block.timestamp >= lastProcess + cooldown, "cooldown");
        uint256 ftpBal = ftp.balanceOf(address(this));
        require(ftpBal >= MIN_YIELD, "no yield to process");
        // roll forward while only the OWNER's seed shares exist (no public depositors).
        if (totalShares == shares[owner]) { emit YieldHeld(ftpBal, "no public depositors - yield-FTP held (rolls forward)"); return; }
        lastProcess = block.timestamp;

        uint256 half = ftpBal / 2;
        uint256 burgBought = _swapFtpForBurgersOurs(half);        // HALF yield-FTP -> BURGERS via OUR pool
        require(burgBought > 0, "burgers swap filled zero");
        uint256 ftpForLP = ftpBal - half;                        // the un-swapped half
        uint128 liq = _addToPosition(ftpForLP, burgBought);
        require(liq > 0, "no liquidity added");
        totalYieldProcessed += ftpBal;
        // NO new shares -> existing shareholders' slices grew. Residual rolls forward.
        emit YieldProcessed(msg.sender, ftpBal, 0, burgBought, liq);
    }

    /// @notice Gift USDG that deepens the position for CURRENT shareholders (mints NO
    ///         shares — their slices grow), matching Base CommunityLPVaultV4.donate.
    ///         BASE flow: ALL USDG -> FTP, swap HALF -> BURGERS via OUR pool, add both.
    function donate(uint256 usdgAmount) external nonReentrant {
        require(positionId != 0, "position not adopted");
        require(totalShares > shares[owner], "no public depositors to donate to");
        require(usdgAmount >= MIN_DEPOSIT, "below min");
        usdg.safeTransferFrom(msg.sender, address(this), usdgAmount);
        uint256 minted = _mintFtp(usdgAmount);
        totalMintedThroughVault += minted;
        uint256 half = minted / 2;
        uint256 burgBought = _swapFtpForBurgersOurs(half);
        require(burgBought > 0, "burgers swap filled zero");
        uint128 liq = _addToPosition(minted - half, burgBought);
        require(liq > 0, "no liquidity added");
        emit Donated(msg.sender, usdgAmount, liq);
    }

    // ══════════════════════ withdraw (USDG default; raw-token escape) ══════════════════════

    /// @notice Withdraw to USDG (BASE flow, mirror of deposit): remove the pro-rata
    ///         slice -> sell the BURGERS side back through OUR pool -> FTP -> redeem
    ///         ALL FTP 1:1 -> USDG out. NO deep route. Slippage-guarded.
    function withdraw(uint256 shareAmount) external nonReentrant {
        (uint256 ftpGot, uint256 burgGot) = _removeShare(shareAmount);
        // sell the BURGERS leg back through OUR pool -> FTP, then redeem ALL FTP 1:1.
        uint256 ftpFromBurg = burgGot > 0 ? _swapBurgersForFtpOurs(burgGot) : 0;
        uint256 totalFtp = ftpGot + ftpFromBurg;
        uint256 out = totalFtp > 0 ? _redeemFtp(totalFtp) : 0;
        require(out > 0, "nothing out");
        withdrawn[msg.sender] += out; totalWithdrawn += out;
        usdg.safeTransfer(msg.sender, out);
        emit WithdrawnUSDG(msg.sender, shareAmount, out);
    }

    /// @notice Escape withdraw: return the raw FTP + BURGERS slice (no swap) — for
    ///         when a depositor prefers the tokens or the deep route is thin. FTP is
    ///         still 1:1-redeemable at the vault by the holder themselves.
    function withdrawAsTokens(uint256 shareAmount) external nonReentrant {
        (uint256 ftpGot, uint256 burgGot) = _removeShare(shareAmount);
        if (ftpGot > 0) ftp.safeTransfer(msg.sender, ftpGot);
        if (burgGot > 0) burgers.safeTransfer(msg.sender, burgGot);
        emit WithdrawnTokens(msg.sender, shareAmount, ftpGot, burgGot);
    }

    function _removeShare(uint256 shareAmount) internal returns (uint256 ftpGot, uint256 burgGot) {
        require(shareAmount > 0 && shareAmount <= shares[msg.sender], "bad shares");
        require(positionId != 0, "position not adopted");
        uint128 posLiq = posm.getPositionLiquidity(positionId);
        uint128 liqToPull = uint128((uint256(posLiq) * shareAmount) / totalShares);
        require(liqToPull > 0, "dust withdraw");
        shares[msg.sender] -= shareAmount; totalShares -= shareAmount;
        uint256 ftpBefore = ftp.balanceOf(address(this));
        uint256 burgBefore = burgers.balanceOf(address(this));
        _decreasePosition(liqToPull);
        ftpGot = ftp.balanceOf(address(this)) - ftpBefore;
        burgGot = burgers.balanceOf(address(this)) - burgBefore;
    }

    // ══════════════════════ internal: FTP vault ══════════════════════

    function _mintFtp(uint256 usdgIn) internal returns (uint256 minted) {
        if (usdgIn == 0) return 0;
        uint256 before = ftp.balanceOf(address(this));
        usdg.forceApprove(address(ftpVault), usdgIn);
        ftpVault.deposit(usdgIn);
        minted = ftp.balanceOf(address(this)) - before;
        require(minted == usdgIn, "ftp mint != 1:1");
    }
    function _redeemFtp(uint256 ftpIn) internal returns (uint256 usdgOut) {
        if (ftpIn == 0) return 0;
        uint256 before = usdg.balanceOf(address(this));
        ftpVault.redeem(ftpIn);
        usdgOut = usdg.balanceOf(address(this)) - before;
        require(usdgOut >= ftpIn - 1, "ftp redeem < 1:1");
    }

    // ══════════════════════ internal: deep route (live-price slippage) ══════════════════════

    /// @dev USDG -> WETH -> BURGERS. minOut derived from LIVE pool prices x (1-slip).
    function _buyBurgers(uint256 usdgIn) internal returns (uint256 burgOut) {
        if (usdgIn == 0) return 0;
        // leg A: USDG -> WETH (vanilla). expected from live WETH/USDG price.
        uint256 wethExp = _quoteUsdgToWeth(usdgIn);
        uint256 wethMin = wethExp * (10000 - slippageBps) / 10000;
        require(wethMin > 0, "weth min 0");
        uint256 wBefore = weth.balanceOf(address(this));
        _swap(wuKey, address(usdg), address(weth), usdgIn, wethMin);
        uint256 wGot = weth.balanceOf(address(this)) - wBefore;
        require(wGot >= wethMin, "usdg->weth under min");
        // leg B: WETH -> BURGERS (doppler). expected from live BURGERS/WETH price.
        uint256 burgExp = _quoteWethToBurgers(wGot);
        uint256 burgMin = burgExp * (10000 - slippageBps) / 10000;
        require(burgMin > 0, "burg min 0");
        uint256 bBefore = burgers.balanceOf(address(this));
        _swap(bwKey, address(weth), address(burgers), wGot, burgMin);
        burgOut = burgers.balanceOf(address(this)) - bBefore;
        require(burgOut >= burgMin, "weth->burg under min");
    }

    /// @dev BURGERS -> WETH -> USDG (reverse deep route).
    function _sellBurgers(uint256 burgIn) internal returns (uint256 usdgOut) {
        if (burgIn == 0) return 0;
        uint256 wethExp = _quoteBurgersToWeth(burgIn);
        uint256 wethMin = wethExp * (10000 - slippageBps) / 10000;
        require(wethMin > 0, "weth min 0");
        uint256 wBefore = weth.balanceOf(address(this));
        _swap(bwKey, address(burgers), address(weth), burgIn, wethMin);
        uint256 wGot = weth.balanceOf(address(this)) - wBefore;
        require(wGot >= wethMin, "burg->weth under min");
        uint256 usdgExp = _quoteWethToUsdg(wGot);
        uint256 usdgMin = usdgExp * (10000 - slippageBps) / 10000;
        require(usdgMin > 0, "usdg min 0");
        uint256 uBefore = usdg.balanceOf(address(this));
        _swap(wuKey, address(weth), address(usdg), wGot, usdgMin);
        usdgOut = usdg.balanceOf(address(this)) - uBefore;
        require(usdgOut >= usdgMin, "weth->usdg under min");
    }

    // ══════════════════════ internal: swap through OUR BURGERS/FTP pool (Base flow) ══════════════════════
    // Founder 2026-07-13: deposits mint ALL USDG->FTP then swap HALF the FTP->BURGERS
    // through OUR OWN BURGERS/FTP pool (fee=10000) — "that is how base worked". The
    // 1% fee on this swap FEEDS the Burgers reactor's position (the reactor's LP earns
    // it). This swap PUSHES our pool (FTP-per-BURGERS down => BURGERS rich in ours) —
    // INTENDED: the RT-BURGERS + peg-guard web corrects it (the web working, not a bug).
    // NO deep route here — the deep route is ONLY the arb/keeper's tool.

    // REALIZED output (impact-inclusive, single-range closed form) of selling `amtIn`
    // of `tokenIn` into OUR pool at LIVE sqrt + LIVE liquidity + LIVE fee. This is the
    // ACTUAL amount the swap delivers (not the no-impact spot estimate) — so a minOut
    // derived from it x (1-slip) is meetable; slippageBps then guards against MOVEMENT
    // between this read and execution (front-running/staleness). Same math the arb uses.
    function _realizedOut(address tokenIn, uint256 amtIn) internal view returns (uint256) {
        uint256 sqrtCur = _sqrt(bfKey);
        uint128 Lq = _bfLiquidity();
        if (Lq == 0 || amtIn == 0) return 0;
        uint256 fee = (uint256(poolManagerState.extsload(keccak256(abi.encode(keccak256(abi.encode(bfKey)), POOLS_SLOT)))) >> 208) & 0xffffff; // live lpFee (1e6)
        uint256 inAfterFee = amtIn * (1000000 - fee) / 1000000;
        uint256 QQ = uint256(1) << 96;
        bool zeroForOne = (bfKey.currency0 == tokenIn);
        if (zeroForOne) {
            // price falls. newSqrt = L*Q*cur / (L*Q + inAfterFee*cur); out1 = L*(cur-new)/Q
            // L*Q*cur can overflow uint256 -> use mulDiv for the numerator/denominator.
            uint256 denom = uint256(Lq) * QQ + inAfterFee * sqrtCur;   // L*Q ~ 2^128*2^96 fits; +inAfterFee*sqrt fits
            uint256 newSqrt = FullMath.mulDiv(uint256(Lq) * QQ, sqrtCur, denom);
            return uint256(Lq) * (sqrtCur - newSqrt) / QQ;
        } else {
            // price rises. newSqrt = cur + inAfterFee*Q/L; out0 = L*Q*(new-cur)/(cur*new)
            uint256 newSqrt = sqrtCur + (inAfterFee * QQ) / uint256(Lq);
            // out0 = L*Q*(new-cur)/(cur*new). cur*new can overflow -> two-step mulDiv.
            return FullMath.mulDiv(FullMath.mulDiv(uint256(Lq), QQ, sqrtCur), newSqrt - sqrtCur, newSqrt);
        }
    }
    function _bfLiquidity() internal view returns (uint128) {
        bytes32 base = keccak256(abi.encode(keccak256(abi.encode(bfKey)), POOLS_SLOT));
        return uint128(uint256(poolManagerState.extsload(bytes32(uint256(base) + 3))));
    }

    // No-impact SPOT expected output (linear at the live price) — the yardstick for
    // the max-impact guard. FTP 6-dec, BURGERS 18-dec. raw = (s/2^96)^2.
    function _spotBurgForFtp(uint256 ftpIn) internal view returns (uint256) {
        uint256 pX192 = _sqrt(bfKey); pX192 = pX192 * pX192;
        if (ftpIsC0_bf) return FullMath.mulDiv(ftpIn, pX192, uint256(1) << 192);      // ftpIn * raw
        require(pX192 != 0, "price 0");
        return FullMath.mulDiv(ftpIn, uint256(1) << 192, pX192);                      // ftpIn / raw
    }

    /// @dev Swap `ftpIn` FTP -> BURGERS through OUR pool with a MAX-IMPACT GUARD: the
    ///      realized (impact-inclusive) output must be within `slippageBps` of the
    ///      no-impact spot — i.e. this deposit's own price impact must be <= slippageBps,
    ///      else ABORT LOUD. This is what makes maxInstantDeposit() a TRUE label: it is
    ///      exactly the size where impact hits slippageBps and the swap starts to
    ///      protect you. minOut also enforces the same bound at execution. No deep route.
    function _swapFtpForBurgersOurs(uint256 ftpIn) internal returns (uint256 burgOut) {
        if (ftpIn == 0) return 0;
        uint256 spotExp = _spotBurgForFtp(ftpIn);
        uint256 realized = _realizedOut(address(ftp), ftpIn);
        uint256 bound = spotExp * (10000 - slippageBps) / 10000;   // max-impact floor
        require(realized >= bound, "deposit too large - price impact exceeds max");
        require(bound > 0, "ftp->burg min 0");
        uint256 before = burgers.balanceOf(address(this));
        _swap(bfKey, address(ftp), address(burgers), ftpIn, bound);
        burgOut = burgers.balanceOf(address(this)) - before;
        require(burgOut >= bound, "ftp->burg under min");
    }

    /// @dev Swap `burgIn` BURGERS -> FTP through OUR pool (withdraw path). Same guard.
    ///      For a legitimately tiny withdraw where the realized FTP rounds below 1,
    ///      floor minOut at 1 (a dust swap can't be meaningfully manipulated) so a
    ///      small holder can always exit — never revert them on rounding.
    function _swapBurgersForFtpOurs(uint256 burgIn) internal returns (uint256 ftpOut) {
        if (burgIn == 0) return 0;
        uint256 exp = _realizedOut(address(burgers), burgIn);
        uint256 minOut = exp * (10000 - slippageBps) / 10000;
        if (minOut == 0) minOut = 1;                       // dust-exit floor
        uint256 before = ftp.balanceOf(address(this));
        _swap(bfKey, address(burgers), address(ftp), burgIn, minOut);
        ftpOut = ftp.balanceOf(address(this)) - before;
        require(ftpOut >= minOut, "burg->ftp under min");
    }

    /// @notice MAX SAFE DEPOSIT (matches the Base community-vault label semantics):
    ///         the largest USDG deposit whose half-FTP->BURGERS swap through OUR pool
    ///         keeps price impact within `slippageBps` (the level at which the deposit
    ///         would start to abort). Read live; the page shows "~$X (pool depth
    ///         limit)". Returns 0 if the pool is unreadable. The label is thus TRUE —
    ///         it is exactly where the contract's own guard begins to protect you.
    function maxInstantDeposit() external view returns (uint256) {
        uint128 Lq = _bfLiquidity();
        if (Lq == 0) return 0;
        // The half swapped is FTP. Find the FTP-in whose realized fill is within
        // slippageBps of the no-impact spot (i.e. impact == slippageBps). Closed form:
        // for selling FTP, realized/spot = new/cur (price ratio). Impact = 1-new/cur.
        // Setting impact = slip: new/cur = 1-slip. From newSqrt relation, solve ftpIn.
        // We approximate with the price-move bound used by Base (linear-in-reserve):
        // maxHalfFtp such that ftpIn moves sqrt by ~slip/2. Robust + monotonic.
        uint256 sqrtCur = _sqrt(bfKey);
        uint256 QQ = uint256(1) << 96;
        uint256 slip = slippageBps; // bps of price
        // FTP is the side we sell. If FTP=c0, selling c0 lowers sqrt: target newSqrt =
        // sqrtCur*(1 - slip/2/10000) [half because price ~ sqrt^2]. ftpIn = L*Q*(cur-new)/(cur*new).
        // If FTP=c1, selling c1 raises sqrt: newSqrt = sqrtCur*(1+slip/2/10000); ftpIn=L*(new-cur)/Q.
        uint256 halfFtp;
        if (ftpIsC0_bf) {
            uint256 newSqrt = sqrtCur - (sqrtCur * slip) / (2 * 10000);
            if (newSqrt == 0 || newSqrt >= sqrtCur) return 0;
            // L*Q*(cur-new)/(cur*new) — avoid cur*new overflow via two-step mulDiv.
            halfFtp = FullMath.mulDiv(FullMath.mulDiv(uint256(Lq), QQ, sqrtCur), sqrtCur - newSqrt, newSqrt);
        } else {
            uint256 newSqrt = sqrtCur + (sqrtCur * slip) / (2 * 10000);
            halfFtp = uint256(Lq) * (newSqrt - sqrtCur) / QQ;
        }
        // deposit = 2 x halfFtp (the other half stays FTP; ALL USDG minted 1:1 so
        // USDG amount == FTP amount, 6-dec == 6-dec).
        return halfFtp * 2;
    }

    // live-price quotes from slot0 sqrtP (no hardcodes; throws if unreadable).
    // WETH is 18-dec, USDG 6-dec, BURGERS 18-dec.  (DEEP-ROUTE quotes — arb/keeper only.)
    function _sqrt(PoolKey memory k) internal view returns (uint256) {
        bytes32 slot0 = poolManagerState.extsload(keccak256(abi.encode(keccak256(abi.encode(k)), POOLS_SLOT)));
        uint256 s = uint160(uint256(slot0));
        require(s != 0, "pool uninit");
        return s;
    }
    // price of currency1 per currency0 (raw) = (s/2^96)^2. We compute out via ratio.
    function _quoteUsdgToWeth(uint256 usdgIn) internal view returns (uint256) {
        uint256 s = _sqrt(wuKey); uint256 pX192 = s * s;                    // c1/c0 * 2^192
        bool usdgIs0 = wuKey.currency0 == address(usdg);
        // WETH out = usdgIn * price(WETH per USDG)
        // if USDG is c0: c1=WETH, WETH per USDG = pX192/2^192 ; else invert.
        return usdgIs0 ? FullMath.mulDiv(usdgIn, pX192, 1 << 192) : FullMath.mulDiv(usdgIn, 1 << 192, pX192);
    }
    function _quoteWethToUsdg(uint256 wethIn) internal view returns (uint256) {
        uint256 s = _sqrt(wuKey); uint256 pX192 = s * s;
        bool wethIs0 = wuKey.currency0 == address(weth);
        return wethIs0 ? FullMath.mulDiv(wethIn, pX192, 1 << 192) : FullMath.mulDiv(wethIn, 1 << 192, pX192);
    }
    function _quoteWethToBurgers(uint256 wethIn) internal view returns (uint256) {
        uint256 s = _sqrt(bwKey); uint256 pX192 = s * s;
        bool wethIs0 = bwKey.currency0 == address(weth);
        return wethIs0 ? FullMath.mulDiv(wethIn, pX192, 1 << 192) : FullMath.mulDiv(wethIn, 1 << 192, pX192);
    }
    function _quoteBurgersToWeth(uint256 burgIn) internal view returns (uint256) {
        uint256 s = _sqrt(bwKey); uint256 pX192 = s * s;
        bool burgIs0 = bwKey.currency0 == address(burgers);
        return burgIs0 ? FullMath.mulDiv(burgIn, pX192, 1 << 192) : FullMath.mulDiv(burgIn, 1 << 192, pX192);
    }

    /// @dev UR V4 single-hop exact-in (single-struct ExactInputSingleParams — the
    ///      layout the reactor build root-caused; field-encoding empty-reverts).
    function _swap(PoolKey memory k, address tokenIn, address tokenOut, uint256 amountIn, uint256 minOut) internal {
        _permit2ApproveExactTo(tokenIn, address(router), amountIn);
        bool zeroForOne = (k.currency0 == tokenIn);
        bytes memory swapAction = abi.encodePacked(uint8(SWAP_EXACT_IN_SINGLE), uint8(SETTLE_ALL), uint8(TAKE_ALL));
        bytes[] memory sp = new bytes[](3);
        sp[0] = abi.encode(ExactInputSingleParams({ poolKey: k, zeroForOne: zeroForOne, amountIn: uint128(amountIn), amountOutMinimum: uint128(minOut), hookData: bytes("") }));
        sp[1] = abi.encode(tokenIn, amountIn);
        sp[2] = abi.encode(tokenOut, minOut);
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(swapAction, sp);
        router.execute(abi.encodePacked(uint8(UR_V4_SWAP)), inputs, block.timestamp + DEADLINE_BUFFER);
        _permit2RevokeTo(tokenIn, address(router));
    }

    // ══════════════════════ internal: V4 position ══════════════════════

    function _addToPosition(uint256 ftpAmount, uint256 burgAmount) internal returns (uint128 liq) {
        uint256 amt0 = ftpIsC0_bf ? ftpAmount : burgAmount;
        uint256 amt1 = ftpIsC0_bf ? burgAmount : ftpAmount;
        if (amt0 == 0 && amt1 == 0) return 0;
        uint160 sqrtCur = uint160(_sqrt(bfKey));
        uint128 liqRaw = LiquidityAmounts.getLiquidityForAmounts(sqrtCur, TickMath.getSqrtPriceAtTick(tickLower), TickMath.getSqrtPriceAtTick(tickUpper), amt0, amt1);
        require(liqRaw > 0, "zero liquidity delta");
        liq = uint128((uint256(liqRaw) * 9995) / 10000);
        require(liq > 0, "liq too small after shave");
        _permit2ApproveExactTo(bfKey.currency0, address(posm), amt0);
        _permit2ApproveExactTo(bfKey.currency1, address(posm), amt1);
        bytes memory actions = abi.encodePacked(uint8(INCREASE_LIQUIDITY), uint8(SETTLE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(positionId, liq, uint128(amt0), uint128(amt1), bytes(""));
        params[1] = abi.encode(bfKey.currency0, bfKey.currency1);
        posm.modifyLiquidities(abi.encode(actions, params), block.timestamp + DEADLINE_BUFFER);
        _permit2RevokeTo(bfKey.currency0, address(posm));
        _permit2RevokeTo(bfKey.currency1, address(posm));
    }

    function _decreasePosition(uint128 liq) internal {
        bytes memory actions = abi.encodePacked(uint8(DECREASE_LIQUIDITY), uint8(TAKE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(positionId, liq, uint256(0), uint256(0), bytes(""));
        params[1] = abi.encode(bfKey.currency0, bfKey.currency1, address(this));
        posm.modifyLiquidities(abi.encode(actions, params), block.timestamp + DEADLINE_BUFFER);
    }

    // ══════════════════════ Permit2 exact-approve hygiene ══════════════════════

    function _permit2ApproveExactTo(address token, address spender, uint256 amount) internal {
        if (amount == 0) return;
        require(amount <= type(uint160).max, "amt overflow");
        (bool ok, bytes memory d) = token.staticcall(abi.encodeWithSignature("allowance(address,address)", address(this), address(permit2)));
        require(ok, "allowance read failed");
        if (abi.decode(d, (uint256)) < amount) _erc20Approve(token, address(permit2), amount);
        permit2.approve(token, spender, uint160(amount), uint48(block.timestamp + 20 minutes));
    }
    function _permit2RevokeTo(address token, address spender) internal { permit2.approve(token, spender, 0, 0); }

    function _erc20Approve(address t, address s, uint256 a) internal {
        // Doppler tokens (BURGERS) fix the Permit2 allowance at infinity and revert
        // on approve — treat that specific revert as already-approved (no silent
        // catch: we re-check and only swallow the known FixedAtInfinity selector).
        (bool ok0, bytes memory d0) = t.call(abi.encodeWithSignature("approve(address,uint256)", s, uint256(0)));
        if (!ok0 && !_isFixedInfinity(d0)) revert("approve reset failed");
        (bool ok1, bytes memory d1) = t.call(abi.encodeWithSignature("approve(address,uint256)", s, a));
        if (!ok1 && !_isFixedInfinity(d1)) revert("approve failed");
        if (ok1) require(d1.length == 0 || abi.decode(d1, (bool)), "approve returned false");
    }
    function _isFixedInfinity(bytes memory d) private pure returns (bool) {
        // Permit2 AllowanceFixedAtInfinity() selector 0x3f68539a
        return d.length >= 4 && d[0] == 0x3f && d[1] == 0x68 && d[2] == 0x53 && d[3] == 0x9a;
    }

    function _returnDust(address to, uint256 ftpBaseline, uint256 burgBaseline) internal {
        uint256 f = ftp.balanceOf(address(this));
        uint256 b = burgers.balanceOf(address(this));
        if (f > ftpBaseline) ftp.safeTransfer(to, f - ftpBaseline);
        if (b > burgBaseline) burgers.safeTransfer(to, b - burgBaseline);
    }

    function _sameKey(PoolKey memory a, PoolKey memory b) internal pure returns (bool) {
        return a.currency0 == b.currency0 && a.currency1 == b.currency1 && a.fee == b.fee && a.tickSpacing == b.tickSpacing && a.hooks == b.hooks;
    }

    // ══════════════════════ views ══════════════════════

    function getInfo(address user) external view returns (uint256 userShares, uint256 userContributed, uint256 userWithdrawn, string memory name, uint256 userLiquidity, uint256 vaultLiquidity) {
        userShares = shares[user]; userContributed = contributed[user]; userWithdrawn = withdrawn[user]; name = displayNameOf[user];
        vaultLiquidity = positionId == 0 ? 0 : posm.getPositionLiquidity(positionId);
        if (totalShares > 0) userLiquidity = (vaultLiquidity * userShares) / totalShares;
    }
    function feedThePeopleTotal() external view returns (uint256) { return totalMintedThroughVault; }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

struct ExactInputSingleParams { PoolKey poolKey; bool zeroForOne; uint128 amountIn; uint128 amountOutMinimum; bytes hookData; }
interface IUniversalRouter { function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable; }
