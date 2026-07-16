// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

/**
 * Tasern Bridge — Polygon <-> Base for the Tasern nation tokens + PR25.
 *
 * Model (ChainPort-style lock/mint):
 *   - Polygon side (TasernBridgePolygon): locks original fixed-supply tokens,
 *     releases them when the matching Base twin is burned.
 *   - Base side (TasernBridgeBase): mints a BridgedToken twin when originals
 *     lock on Polygon, burns it to bridge back.
 *
 * Invariant: twin.totalSupply() on Base == originals locked on Polygon.
 * Each twin has a hard cap equal to the original's fixed total supply, so
 * global supply (both chains) can never exceed the original mint.
 *
 * Trust model: a single relayer key carries messages between chains. Replay
 * is blocked on-chain (each outbound transfer gets a nonce, each side marks
 * nonces processed). Owner can pause and swap the relayer. The Polygon vault
 * keeps a build-phase escape hatch (adminWithdraw) to be renounced once the
 * bridge is proven — see renounceEscapeHatch().
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

/// Minimal ERC20 twin. Mint/burn restricted to the bridge vault that deploys it.
contract BridgedToken {
    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public immutable cap; // original chain's fixed total supply
    address public immutable bridge;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _cap) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        cap = _cap;
        bridge = msg.sender;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        require(a >= amount, "allowance");
        if (a != type(uint256).max) allowance[from][msg.sender] = a - amount;
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == bridge, "only bridge");
        require(totalSupply + amount <= cap, "cap");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == bridge, "only bridge");
        require(balanceOf[from] >= amount, "balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "zero to");
        require(balanceOf[from] >= amount, "balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}

/// Shared plumbing: owner, relayer, pause, replay protection.
abstract contract BridgeCore {
    address public owner;
    address public relayer;
    bool public paused;

    uint256 public outboundNonce;                 // this chain -> other chain
    mapping(uint256 => bool) public processedInbound; // other chain nonce -> done

    event RelayerSet(address relayer);
    event Paused(bool paused);

    modifier onlyOwner() { require(msg.sender == owner, "only owner"); _; }
    modifier onlyRelayer() { require(msg.sender == relayer, "only relayer"); _; }
    modifier notPaused() { require(!paused, "paused"); _; }

    function setRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
        emit RelayerSet(_relayer);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "zero owner");
        owner = _owner;
    }
}

/// Polygon side: lock originals going out, release them coming back.
contract TasernBridgePolygon is BridgeCore {
    mapping(address => bool) public supported; // original token allowlist (add-only)
    bool public escapeHatchRenounced;

    event TokenAdded(address indexed token);
    event Locked(uint256 indexed nonce, address indexed token, address indexed from, address baseRecipient, uint256 amount);
    event Released(uint256 indexed inboundNonce, address indexed token, address indexed to, uint256 amount);
    event EscapeHatchRenounced();

    constructor() { owner = msg.sender; }

    function addToken(address token) external onlyOwner {
        supported[token] = true;
        emit TokenAdded(token);
    }

    /// Lock originals here; relayer mints the twin to `baseRecipient` on Base.
    function bridgeToBase(address token, uint256 amount, address baseRecipient) external notPaused {
        require(supported[token], "token not supported");
        require(amount > 0, "zero amount");
        require(baseRecipient != address(0), "zero recipient");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer failed");
        uint256 nonce = ++outboundNonce;
        emit Locked(nonce, token, msg.sender, baseRecipient, amount);
    }

    /// Relayer releases originals after the twin burned on Base.
    function release(uint256 inboundNonce, address token, address to, uint256 amount) external onlyRelayer notPaused {
        require(supported[token], "token not supported");
        require(!processedInbound[inboundNonce], "already processed");
        processedInbound[inboundNonce] = true;
        require(IERC20(token).transfer(to, amount), "transfer failed");
        emit Released(inboundNonce, token, to, amount);
    }

    /// Build-phase escape hatch: recover locked tokens if the bridge is
    /// abandoned before launch. MUST be renounced once the bridge ships.
    function adminWithdraw(address token, address to, uint256 amount) external onlyOwner {
        require(!escapeHatchRenounced, "renounced");
        require(IERC20(token).transfer(to, amount), "transfer failed");
    }

    function renounceEscapeHatch() external onlyOwner {
        escapeHatchRenounced = true;
        emit EscapeHatchRenounced();
    }
}

/// Base side: deploys twins, mints them for inbound locks, burns to go back.
contract TasernBridgeBase is BridgeCore {
    mapping(address => address) public twinOf;     // polygon original -> base twin
    mapping(address => address) public originalOf; // base twin -> polygon original

    event TwinDeployed(address indexed polygonToken, address indexed twin, string symbol);
    event Minted(uint256 indexed inboundNonce, address indexed twin, address indexed to, uint256 amount);
    event Burned(uint256 indexed nonce, address indexed twin, address indexed from, address polygonRecipient, uint256 amount);

    constructor() { owner = msg.sender; }

    /// Deploy a twin for a Polygon original. Add-only; one twin per original.
    function deployTwin(
        address polygonToken,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        uint256 cap_
    ) external onlyOwner returns (address twin) {
        require(twinOf[polygonToken] == address(0), "twin exists");
        twin = address(new BridgedToken(name_, symbol_, decimals_, cap_));
        twinOf[polygonToken] = twin;
        originalOf[twin] = polygonToken;
        emit TwinDeployed(polygonToken, twin, symbol_);
    }

    /// Relayer mints twins after originals locked on Polygon.
    function mintFromPolygon(uint256 inboundNonce, address polygonToken, address to, uint256 amount) external onlyRelayer notPaused {
        address twin = twinOf[polygonToken];
        require(twin != address(0), "no twin");
        require(!processedInbound[inboundNonce], "already processed");
        processedInbound[inboundNonce] = true;
        BridgedToken(twin).mint(to, amount);
        emit Minted(inboundNonce, twin, to, amount);
    }

    /// Burn twins here; relayer releases originals to `polygonRecipient` on Polygon.
    function bridgeToPolygon(address twin, uint256 amount, address polygonRecipient) external notPaused {
        require(originalOf[twin] != address(0), "not a twin");
        require(amount > 0, "zero amount");
        require(polygonRecipient != address(0), "zero recipient");
        BridgedToken(twin).burn(msg.sender, amount);
        uint256 nonce = ++outboundNonce;
        emit Burned(nonce, twin, msg.sender, polygonRecipient, amount);
    }
}
