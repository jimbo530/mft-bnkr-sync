// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FeeSplitter — immutable N-way fee router (pull-based, trustless by construction).
/// @notice Splits every native-ETH and ERC20 inflow between N recipients by basis-point
/// shares fixed FOREVER at deploy. There is NO admin, NO owner, NO pause, NO upgrade and
/// NOTHING to renounce — the constructor arguments are the entire trust model. Anything
/// sent to this address is claimable only by the configured recipients, pro-rata, forever.
///
/// Pattern: pull-based accounting (OpenZeppelin PaymentSplitter style, reimplemented
/// self-contained, generalized to per-token):
///   totalReceived(token) = balance(token) + totalReleased(token)
///   owed(token, account) = totalReceived * sharesBps[account] / 10000 - released[token][account]
/// so repeated release() calls only ever pay NEW inflows. token = address(0) is native ETH.
///
/// Anyone may call release()/releaseAll() — funds always go to the recipients, never the
/// caller, so permissionless triggering is safe (keepers welcome).
///
/// Known edges (accepted, documented):
///  - Rounding: floor division leaves dust in the contract, bounded by < N wei per token
///    at any moment. It is never lost to a third party; it is just too small to split.
///  - A recipient CONTRACT with no receive()/fallback cannot take its NATIVE share
///    (its release() reverts; other recipients are unaffected — accounting is per-account).
///    Use EOAs or receive()-capable contracts for native flows; ERC20s always deliver.
///  - releaseAll() is all-or-nothing: one failing transfer reverts the whole call. The
///    per-account release() is the guaranteed path a single bad recipient can never block.
///  - Fee-on-transfer tokens: accounting splits what the SPLITTER received; a transfer-out
///    fee is borne by that recipient. Rebasing-DOWN tokens are unsupported (release reverts
///    if the balance shrinks below what the accounting expects).
contract FeeSplitter {
    uint256 public constant TOTAL_BPS = 10000;

    address[] private _recipients;
    mapping(address => uint256) private _sharesBps;                    // recipient => bps
    mapping(address => uint256) private _totalReleased;                // token => total paid out
    mapping(address => mapping(address => uint256)) private _released; // token => recipient => paid

    uint256 private _locked = 1;
    modifier nonReentrant() { require(_locked == 1, "reentrant"); _locked = 2; _; _locked = 1; }

    event PaymentReceived(address indexed from, uint256 amount);
    event PaymentReleased(address indexed token, address indexed to, uint256 amount);

    /// @param recipients_ the payees — fixed forever, check them twice.
    /// @param sharesBps_  basis points per payee; must sum to exactly 10000.
    constructor(address[] memory recipients_, uint256[] memory sharesBps_) {
        require(recipients_.length == sharesBps_.length, "length mismatch");
        require(recipients_.length >= 2, "need at least 2 recipients");
        uint256 sum;
        for (uint256 i = 0; i < recipients_.length; i++) {
            address r = recipients_[i];
            uint256 s = sharesBps_[i];
            require(r != address(0), "zero recipient");
            require(s > 0, "zero share");
            require(_sharesBps[r] == 0, "duplicate recipient");
            _recipients.push(r);
            _sharesBps[r] = s;
            sum += s;
        }
        require(sum == TOTAL_BPS, "shares must sum to 10000");
    }

    /// @notice Accept native ETH (fees route here by plain transfer).
    receive() external payable { emit PaymentReceived(msg.sender, msg.value); }

    /// @notice Pay `account` its owed share of every `token` inflow to date. Callable by
    /// anyone; funds go to `account`. token = address(0) pays native ETH.
    function release(address token, address account) external nonReentrant returns (uint256 amount) {
        require(_sharesBps[account] > 0, "not a recipient");
        amount = _pending(token, account);
        require(amount > 0, "nothing due");
        _pay(token, account, amount);
    }

    /// @notice Push every recipient's currently-owed `token` share in one call.
    /// All-or-nothing: if any single transfer fails the whole call reverts — fall back to
    /// per-account release(). Reverts if nothing is due at all (visible no-op).
    function releaseAll(address token) external nonReentrant returns (uint256 totalPaid) {
        uint256 n = _recipients.length;
        for (uint256 i = 0; i < n; i++) {
            address account = _recipients[i];
            uint256 amount = _pending(token, account);
            if (amount == 0) continue; // this payee is simply up to date — not a failure
            _pay(token, account, amount);
            totalPaid += amount;
        }
        require(totalPaid > 0, "nothing due");
    }

    // ── views ──

    /// @notice What `account` could withdraw of `token` right now (0 for non-recipients).
    function pending(address token, address account) external view returns (uint256) {
        return _pending(token, account);
    }

    /// @notice `account`'s share in basis points (0 = not a recipient).
    function shares(address account) external view returns (uint256) { return _sharesBps[account]; }

    /// @notice Total `token` ever paid out to all recipients.
    function totalReleased(address token) external view returns (uint256) { return _totalReleased[token]; }

    /// @notice Total `token` already paid out to `account`.
    function released(address token, address account) external view returns (uint256) {
        return _released[token][account];
    }

    /// @notice The full immutable recipient list.
    function recipients() external view returns (address[] memory) { return _recipients; }

    function recipientCount() external view returns (uint256) { return _recipients.length; }

    // ── internal ──

    function _pending(address token, address account) internal view returns (uint256) {
        uint256 share = _sharesBps[account];
        if (share == 0) return 0;
        uint256 totalReceived = _balanceHere(token) + _totalReleased[token];
        return (totalReceived * share) / TOTAL_BPS - _released[token][account];
    }

    function _balanceHere(address token) internal view returns (uint256) {
        if (token == address(0)) return address(this).balance;
        (bool ok, bytes memory data) =
            token.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(ok && data.length >= 32, "balanceOf failed");
        return abi.decode(data, (uint256));
    }

    /// @dev Effects before interaction: the accounting is settled BEFORE the transfer, and
    /// balance + totalReleased move in lockstep, so totalReceived is invariant mid-payout —
    /// a reentering recipient sees fully consistent state and nothing extra to claim.
    function _pay(address token, address to, uint256 amount) internal {
        _released[token][to] += amount;
        _totalReleased[token] += amount;
        if (token == address(0)) {
            (bool ok, ) = to.call{value: amount}("");
            require(ok, "native send failed");
        } else {
            (bool ok, bytes memory data) =
                token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
            require(ok && (data.length == 0 || abi.decode(data, (bool))), "token send failed");
        }
        emit PaymentReleased(token, to, amount);
    }
}
