// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
  ManufacturingPool — the LAYER-(b) BUSINESS primitive for Seize the Seas
  (founder 2026-06-27, CAMP-TO-TOWN-MODEL §0/§11 #1: "owners own the LP + stock, can pull logs/lumber").

  THE GAP THIS FILLS (do not misrepresent the live primitives):
   * StructureFactory.seal() waters a seed into a WaterV2 tree -> LOCKED FOREVER. Correct for the
     FOUNDATION layer (a) — the immobile, permanent stake. NOT working capital.
   * LocationPool.sol is ADD-ONLY: an admin can NEVER withdraw; value only leaves via gated swaps.
     Correct for the treasury-priced trade-route pools. NOT an owner's withdrawable business.
   * WaterV2 trees lock forever. Neither lets an owner pull their own stock back out.

  ManufacturingPool is the missing primitive: a LOCATION-KEYED, OWNER-WITHDRAWABLE, AUTOMATED
  production pool — the player's "business." It is WORKING CAPITAL, NOT locked:

    1. OWNER deposits INPUT stock (logs / ore / ingredients) and can ALWAYS WITHDRAW either side
       (inputs OR finished outputs), one side or both, at any time. NO LOCK — this is the founder's
       whole "owners own the stock, can pull logs/lumber" requirement. (no-premature-lock applies
       PERMANENTLY here, not just pre-seal — a business' stock is never locked.)

    2. AUTOMATED CONVERSION via a fixed RECIPE: N input goods (each with a per-batch quantity) ->
       one output good at a set ratio. A keeper or the owner calls process(batches): it CONSUMES
       inputs from stock (debited AND physically shipped to a sink — "used up") and CREDITS the
       produced output into stock, capped by the available input stock (Anno-style "build it, keep
       it fed, the line runs itself"). Because Seas goods are FIXED-SUPPLY (no mint), the produced
       output is PRE-FUNDED: the pool must already hold enough outputToken to back what it credits,
       so the line can only ever pay out output it actually holds (real-or-nothing, no minting from
       thin air). Supports MULTI-INPUT (copper+tin->bronze; iron+coal->steel; multi-ingredient
       cooking) AND single-input (ore->ingot, shale->brick, log->lumber).

    3. LOCATION-KEYED: tied to a hex `location` like LocationPool. Owner ops are owner-gated.
       OPTIONAL presence-gated public BUY: if `publicBuyEnabled`, a travelling player at `location`
       (proven by a gameSigner attestation, the LocationPool pattern) may buy finished OUTPUT from
       stock for an INPUT-or-payment token at a fixed owner-set price. OFF by default — v1's primary
       model is owner-run (owner deposits inputs, the line converts, owner withdraws outputs to sell
       elsewhere). The public storefront is a notable extra, not required.

  EXPLICITLY NOT IN THIS CONTRACT:
   * WAGES / owner payout via the modular 50/50 WaterV2 waters (GOODS-water + COPPER wage-water) are
     SEPARATE (WaterV2, attached by a keeper). This contract is ONLY the stock + the conversion line.
   * No fee-on-transfer assumptions (reserve accounting credits the EXACT amount transferred in for
     deposits; for non-standard ERC20s use only well-behaved goods tokens — the Seas ItemTokens are).

  RECIPE LIFECYCLE (no-premature-lock, mirrors StructureFactory's seal discipline for the RECIPE only):
   * The recipe may be set/changed by the owner WHILE UNSEALED (prototype freedom).
   * seal() freezes the recipe permanently (a shipped business has a fixed line). Stock deposit/
     withdraw/process keep working forever — seal locks ONLY the recipe, NEVER the owner's stock.
*/

contract ManufacturingPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Roles ──
    address public owner;       // the player who owns this business (deposits/withdraws stock)
    address public keeper;      // automation allowed to call process() on the owner's behalf (0 = owner only)
    address public gameSigner;  // signs presence attestations for the OPTIONAL public buy (0 = no public buy)

    // Where CONSUMED inputs physically go when the line runs. Fixed-supply Seas goods can't be burned
    // by the contract, so consumed inputs are MOVED OUT to this sink (the in-fiction "raw material is
    // used up"). Default = the standard burn address; owner may point it at a game treasury/recycler.
    // This keeps the ledger HONEST: for every tracked token, stock == this pool's real balance.
    address public constant DEFAULT_INPUT_SINK = 0x000000000000000000000000000000000000dEaD;
    address public inputSink;

    // ── Location + flags ──
    uint256 public immutable location;   // hex id this business stands on (immobile, like LocationPool)
    bool    public recipeSealed;         // true = recipe frozen permanently (stock is NEVER frozen)
    bool    public publicBuyEnabled;     // owner toggle for the optional presence-gated storefront

    // ── Recipe: many INPUT goods -> one OUTPUT good, per "batch" ──
    struct Input { IERC20 token; uint256 perBatch; } // consume `perBatch` of `token` per batch
    Input[]  public inputs;              // 1..N inputs (multi-input industry is fine — it's automated)
    IERC20   public outputToken;         // the produced good (LUMBER/INGOT/BRICK/FOOD/...)
    uint256  public outputPerBatch;      // produced per batch into stock

    // ── Stock accounting (reserve-tracked, fee-on-transfer NOT assumed) ──
    mapping(address => uint256) public stock; // token => owner-owned stock held by this pool

    // ── Optional public storefront pricing (presence-gated) ──
    // Buyer pays `buyPriceIn` of `payToken` to receive `buyAmountOut` of `outputToken` from stock.
    IERC20  public payToken;     // token a public buyer pays in (e.g. COPPER / GOLD)
    uint256 public buyPriceIn;   // pay amount per purchase unit
    uint256 public buyAmountOut; // output delivered per purchase unit
    uint32  public buyCooldown;  // seconds between buys per player
    mapping(address => uint256) public lastBuy;

    // ── Events (every state change visible; no silent failures) ──
    event Initialized(address indexed owner, uint256 location);
    event KeeperSet(address indexed keeper);
    event GameSignerSet(address indexed gameSigner);
    event InputSinkSet(address indexed inputSink);
    event RecipeSet(address[] inputTokens, uint256[] inputPerBatch, address outputToken, uint256 outputPerBatch);
    event RecipeSealed();
    event Deposited(address indexed token, uint256 amount, uint256 newStock);
    event Withdrawn(address indexed token, address indexed to, uint256 amount, uint256 newStock);
    event Processed(uint256 batches, uint256 outputProduced);
    event PublicBuySet(bool enabled, address payToken, uint256 priceIn, uint256 amountOut, uint32 cooldown);
    event Bought(address indexed player, uint256 units, uint256 paidIn, uint256 outOut);

    modifier onlyOwner() { require(msg.sender == owner, "!owner"); _; }
    modifier onlyKeeper() { require(msg.sender == owner || (keeper != address(0) && msg.sender == keeper), "!keeper"); _; }

    /// @param _owner       the player who owns the business
    /// @param _location    hex id this business is keyed to
    /// @param _keeper      automation allowed to process() (0 = owner only)
    /// @param _gameSigner  presence attestor for the optional public buy (0 = none)
    constructor(address _owner, uint256 _location, address _keeper, address _gameSigner) {
        require(_owner != address(0), "owner=0");
        owner = _owner;
        location = _location;
        keeper = _keeper;
        gameSigner = _gameSigner;
        inputSink = DEFAULT_INPUT_SINK;
        emit Initialized(_owner, _location);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Roles / config (owner)
    // ═══════════════════════════════════════════════════════════════════════

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
        emit KeeperSet(_keeper);
    }

    function setGameSigner(address _gameSigner) external onlyOwner {
        gameSigner = _gameSigner;
        emit GameSignerSet(_gameSigner);
    }

    /// @notice Where consumed inputs are sent when the line runs (default = burn). Cannot be the pool
    ///         itself (would re-credit nothing and break the honest balance==stock invariant) and
    ///         cannot be address(0).
    function setInputSink(address _inputSink) external onlyOwner {
        require(_inputSink != address(0) && _inputSink != address(this), "bad sink");
        inputSink = _inputSink;
        emit InputSinkSet(_inputSink);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "newOwner=0");
        owner = newOwner;
        emit Initialized(newOwner, location);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  RECIPE — set while unsealed; seal() freezes it forever (stock stays free)
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Set/replace the conversion recipe. Owner-only and ONLY while unsealed.
    ///         Supports 1..N inputs -> one output. perBatch quantities define the ratio.
    /// @param inputTokens  the input goods (>=1, no dups, none == outputToken)
    /// @param inputPerBatch quantity of each input consumed per batch (each > 0)
    /// @param _outputToken the produced good
    /// @param _outputPerBatch quantity produced per batch (> 0)
    function setRecipe(
        address[] calldata inputTokens,
        uint256[] calldata inputPerBatch,
        address _outputToken,
        uint256 _outputPerBatch
    ) external onlyOwner {
        require(!recipeSealed, "recipe sealed");
        require(inputTokens.length >= 1 && inputTokens.length == inputPerBatch.length, "bad inputs");
        require(_outputToken != address(0), "output=0");
        require(_outputPerBatch > 0, "output qty=0");

        // Rebuild the inputs array, validating each.
        delete inputs;
        for (uint256 i = 0; i < inputTokens.length; i++) {
            address t = inputTokens[i];
            require(t != address(0), "input=0");
            require(t != _outputToken, "input==output");
            require(inputPerBatch[i] > 0, "input qty=0");
            // reject duplicate input tokens (would double-count consumption)
            for (uint256 j = 0; j < i; j++) require(inputTokens[j] != t, "dup input");
            inputs.push(Input({ token: IERC20(t), perBatch: inputPerBatch[i] }));
        }
        outputToken = IERC20(_outputToken);
        outputPerBatch = _outputPerBatch;
        emit RecipeSet(inputTokens, inputPerBatch, _outputToken, _outputPerBatch);
    }

    /// @notice Freeze the recipe permanently (a shipped business has a fixed line).
    ///         Locks ONLY the recipe — owner stock deposit/withdraw/process keep working forever.
    function seal() external onlyOwner {
        require(!recipeSealed, "already sealed");
        require(inputs.length >= 1 && address(outputToken) != address(0), "no recipe");
        recipeSealed = true;
        emit RecipeSealed();
    }

    function inputCount() external view returns (uint256) { return inputs.length; }

    // ═══════════════════════════════════════════════════════════════════════
    //  STOCK — owner deposits inputs; owner can ALWAYS withdraw (no lock)
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Deposit working-capital stock (typically an INPUT good, but any token is allowed —
    ///         e.g. pre-loading finished OUTPUT to sell from the storefront). Reserve-accounted by
    ///         measured balance delta (no fee-on-transfer assumption baked into the credit).
    function deposit(address token, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(0), "token=0");
        require(amount > 0, "zero");
        uint256 before = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = IERC20(token).balanceOf(address(this)) - before;
        require(received > 0, "no tokens received");
        stock[token] += received;
        emit Deposited(token, received, stock[token]);
    }

    /// @notice Withdraw stock back to the owner — ALWAYS available (working capital, never locked).
    ///         Either side or both: call once per token. This is the founder's "pull logs/lumber".
    function withdraw(address token, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "zero");
        uint256 bal = stock[token];
        require(amount <= bal, "over stock");
        stock[token] = bal - amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawn(token, msg.sender, amount, stock[token]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  PROCESS — the automated line: consume inputs -> produce output, capped by stock
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice How many batches the current stock can support (the available-input cap).
    function maxBatches() public view returns (uint256 m) {
        uint256 n = inputs.length;
        if (n == 0) return 0;
        m = type(uint256).max;
        for (uint256 i = 0; i < n; i++) {
            Input storage inp = inputs[i];
            uint256 canDo = stock[address(inp.token)] / inp.perBatch; // perBatch > 0 by setRecipe
            if (canDo < m) m = canDo;
        }
    }

    /// @notice Run the line. For up to `batches` batches (capped by available input stock):
    ///           - CONSUMES inputs: debits stock AND physically sends the consumed input tokens to
    ///             `inputSink` (the raw material is "used up"). This keeps the honest invariant that,
    ///             for every tracked token, stock == this pool's real balance — no stranded tokens.
    ///           - PRODUCES output: credits stock[output]. Because Seas goods are FIXED-SUPPLY (no
    ///             mint), the produced output must be PRE-FUNDED into the pool's outputToken balance
    ///             (the owner deposits OUTPUT as un-stocked backing, or the deploy seeds it). The line
    ///             may only credit output the pool can actually pay out — real-or-nothing.
    ///         Owner or keeper may call. Anno-style idle line: keep it fed, it converts.
    /// @param batches requested batches (0 = run the max the input stock supports)
    /// @return ran the batches actually executed
    function process(uint256 batches) external onlyKeeper nonReentrant returns (uint256 ran) {
        uint256 n = inputs.length;
        require(n >= 1 && address(outputToken) != address(0), "no recipe");

        uint256 cap = maxBatches();
        ran = (batches == 0 || batches > cap) ? cap : batches;
        require(ran > 0, "no input stock");

        uint256 produced = ran * outputPerBatch;

        // Solvency: the pool must physically hold enough OUTPUT beyond what it already owes as output
        // stock, to back the newly produced output. Output is fixed-supply — it must be pre-funded.
        uint256 outBal = outputToken.balanceOf(address(this));
        uint256 outOwed = stock[address(outputToken)];
        uint256 unbacked = outBal > outOwed ? outBal - outOwed : 0;
        require(produced <= unbacked, "insufficient output backing");

        // Consume inputs: debit stock and ship the physical tokens to the sink (used up).
        for (uint256 i = 0; i < n; i++) {
            Input storage inp = inputs[i];
            uint256 used = ran * inp.perBatch;          // safe: ran <= maxBatches
            stock[address(inp.token)] -= used;
            inp.token.safeTransfer(inputSink, used);
        }
        // Credit produced output into stock (fully backed by held outputToken balance).
        stock[address(outputToken)] += produced;

        emit Processed(ran, produced);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  OPTIONAL public storefront — presence-gated buy (LocationPool attestation)
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Owner configures the storefront: a travelling player at `location` pays `priceIn` of
    ///         `_payToken` to receive `amountOut` of the OUTPUT good from stock. gameSigner must be
    ///         set for buys to work. Disable by passing enabled=false.
    function setPublicBuy(
        bool enabled,
        address _payToken,
        uint256 priceIn,
        uint256 amountOut,
        uint32 cooldown
    ) external onlyOwner {
        if (enabled) {
            require(_payToken != address(0), "payToken=0");
            require(priceIn > 0 && amountOut > 0, "zero price/out");
            require(address(outputToken) != address(0), "no output");
            payToken = IERC20(_payToken);
            buyPriceIn = priceIn;
            buyAmountOut = amountOut;
            buyCooldown = cooldown;
        }
        publicBuyEnabled = enabled;
        emit PublicBuySet(enabled, _payToken, priceIn, amountOut, cooldown);
    }

    /// @notice The message the game signs to attest the buyer is physically at this pool's location.
    function attestationHash(address player, uint256 expiry) public view returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(
            keccak256(abi.encodePacked(address(this), player, location, expiry, block.chainid))
        );
    }

    /// @notice Buy finished OUTPUT from stock at the owner-set price. Presence-gated: requires a fresh
    ///         gameSigner attestation that the caller is at `location`. The payToken goes into stock
    ///         (owner withdraws it later); the output leaves stock to the buyer.
    /// @param units    number of purchase units (each = priceIn paid, amountOut received)
    /// @param maxPayIn slippage/safety guard on total paid
    /// @param expiry   attestation expiry
    /// @param sig      gameSigner signature over attestationHash(buyer, expiry)
    function buy(
        uint256 units,
        uint256 maxPayIn,
        uint256 expiry,
        bytes calldata sig
    ) external nonReentrant returns (uint256 paidIn, uint256 outOut) {
        require(publicBuyEnabled, "buy disabled");
        require(gameSigner != address(0), "no signer");
        require(units > 0, "zero");
        require(block.timestamp >= lastBuy[msg.sender] + buyCooldown, "cooldown");
        require(block.timestamp <= expiry, "expired");
        require(
            ECDSA.recover(attestationHash(msg.sender, expiry), sig) == gameSigner,
            "bad attestation"
        );

        paidIn = units * buyPriceIn;
        outOut = units * buyAmountOut;
        require(paidIn <= maxPayIn, "over maxPayIn");
        require(stock[address(outputToken)] >= outOut, "insufficient output stock");

        lastBuy[msg.sender] = block.timestamp;

        // Pull payment into stock (reserve-accounted by measured delta).
        uint256 before = payToken.balanceOf(address(this));
        payToken.safeTransferFrom(msg.sender, address(this), paidIn);
        uint256 received = payToken.balanceOf(address(this)) - before;
        require(received >= paidIn, "fee-on-transfer payToken");
        stock[address(payToken)] += received;

        // Deliver output from stock.
        stock[address(outputToken)] -= outOut;
        outputToken.safeTransfer(msg.sender, outOut);

        emit Bought(msg.sender, units, paidIn, outOut);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Views
    // ═══════════════════════════════════════════════════════════════════════

    function recipeView() external view returns (
        address[] memory inputTokens,
        uint256[] memory inputPerBatch,
        address out,
        uint256 outPerBatch
    ) {
        uint256 n = inputs.length;
        inputTokens = new address[](n);
        inputPerBatch = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            inputTokens[i] = address(inputs[i].token);
            inputPerBatch[i] = inputs[i].perBatch;
        }
        out = address(outputToken);
        outPerBatch = outputPerBatch;
    }
}
