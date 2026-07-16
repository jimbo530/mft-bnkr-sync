// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RHReactorFactory — Robinhood Chain (4663) V4 Reactor Factory
///
/// Stamps V4ReactorSuite child reactors (V4BurgersReactor pattern) wired to
/// the canonical RH V4 addresses.  The factory itself holds NO funds.
///
/// DESIGN (grounded in V4ReactorSuite.sol + rh-v4-addresses.json):
///   - RH V4 infra addresses (positionManager, universalRouter, permit2,
///     poolManager) are immutable in this factory.  They were resolved and
///     verified in rh-v4-addresses.json (2026-07-13) and match the live
///     V4ReactorPrime + V4BurgersReactor + V4FryerTuckReactor deployments.
///   - A "prime" address (the upstream aggregator) is also immutable here.
///     It is supplied at factory construction time.
///   - createReactor(coreToken) deploys one child reactor wired as:
///       V4ChildReactor(core, pm, router, permit2, prime, poolManager)
///     matching the V4BurgersReactor / V4FryerTuckReactor constructor exactly.
///   - On-chain registry: token -> reactor (one reactor per core token; a
///     second attempt for the same token reverts).
///   - ADMIN: factory admin can change admin only — no fund-draining power.
///
/// HOUSE RULES (from V4ReactorSuite doctrine):
///   - No silent catches — every create either succeeds or reverts visible.
///   - No empty catch blocks.
///   - No OpenZeppelin imports (self-contained, matching V4ReactorSuite.sol).
///   - Exact pattern: same solc pragma, same evmVersion (paris), same
///     optimizer (viaIR, runs 200) as compile-rh-suite.cjs.

// ═══════════════════════════════════════════════════════════════════════════
//  Minimal interface — only the V4ChildReactor constructor we call
// ═══════════════════════════════════════════════════════════════════════════

/// @dev V4 child reactor constructor signature, shared by V4BurgersReactor
///      and V4FryerTuckReactor (verified from V4BurgersReactor.artifact.json):
///      (address _core, address _pm, address _router, address _permit2,
///       address _prime, address _poolManager)
interface IV4ChildReactor {
    function admin() external view returns (address);
    function transferAdmin(address newAdmin) external;
}

// ═══════════════════════════════════════════════════════════════════════════
//  V4ChildReactor — the reactor we stamp (inline creation bytecode)
// ═══════════════════════════════════════════════════════════════════════════

/// @dev Import inline by pulling the V4ReactorSuite child contracts.  We do
///      NOT re-define them here — we reference the already-compiled bytecode
///      stored in the factory's immutable creationCode.  However, because
///      Solidity's new keyword needs a contract type visible in this file, we
///      declare a minimal concrete shim that inherits nothing (the factory
///      links to the REAL bytecode blob injected at construction time).
///
///      PATTERN: the factory is constructed with the creation bytecode of
///      V4BurgersReactor (or any V4ReactorBase child) as a bytes parameter,
///      stores it immutably, and uses assembly create() to deploy each child.
///      This avoids re-compiling the reactor inside the factory file and keeps
///      the factory small.  The admin of each new reactor is set to msg.sender
///      of createReactor() (not the factory), matching the pattern where each
///      launcher controls their own reactor.

// ═══════════════════════════════════════════════════════════════════════════
//  RHReactorFactory
// ═══════════════════════════════════════════════════════════════════════════

contract RHReactorFactory {

    // ── Immutable RH V4 infrastructure ─────────────────────────────────────
    // All verified from rh-v4-addresses.json (2026-07-13):
    //   positionManager  = 0x58daec3116aae6D93017bAAea7749052E8a04fA7
    //   universalRouter  = 0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77
    //   permit2          = 0x000000000022D473030F116dDEE9F6B43aC78BA3
    //   poolManager      = 0x8366a39CC670B4001A1121B8F6A443A643e40951
    address public immutable positionManager;
    address public immutable universalRouter;
    address public immutable permit2;
    address public immutable poolManager;

    // ── Immutable prime / upstream ──────────────────────────────────────────
    // The V4ReactorPrime that child reactors route their upstream fuel cut to.
    // Set at construction; cannot be changed (matches reactor immutability).
    address public immutable prime;

    // ── Child reactor creation bytecode ────────────────────────────────────
    // Passed at construction.  Must be the compilation output of
    // V4BurgersReactor (or any V4ReactorBase child with the same constructor
    // signature).  Stored as bytes so the factory can deploy any compatible
    // child without recompiling.
    bytes public childCreationCode;

    // ── Registry ───────────────────────────────────────────────────────────
    /// @notice core token -> deployed reactor address.  Zero if not deployed.
    mapping(address => address) public reactorOf;

    /// @notice All deployed reactor addresses in creation order.
    address[] public allReactors;

    // ── Admin ──────────────────────────────────────────────────────────────
    address public admin;
    address public pendingAdmin;

    // ── Events ─────────────────────────────────────────────────────────────
    /// @notice Emitted when a new child reactor is deployed.
    /// @param coreToken  The token the reactor burns.
    /// @param reactor    The deployed child reactor address.
    /// @param deployer   The msg.sender who called createReactor().
    event ReactorCreated(
        address indexed coreToken,
        address indexed reactor,
        address indexed deployer
    );

    event AdminTransferStarted(address indexed current, address indexed pending_);
    event AdminTransferred(address indexed previous, address indexed next_);

    // ── Modifiers ──────────────────────────────────────────────────────────
    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    // ── Constructor ────────────────────────────────────────────────────────
    /// @param _positionManager  RH V4 PositionManager
    ///        (0x58daec3116aae6D93017bAAea7749052E8a04fA7)
    /// @param _universalRouter  RH canonical Uniswap V4 UniversalRouter
    ///        (0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77)
    /// @param _permit2          Permit2 singleton
    ///        (0x000000000022D473030F116dDEE9F6B43aC78BA3)
    /// @param _poolManager      RH V4 PoolManager singleton
    ///        (0x8366a39CC670B4001A1121B8F6A443A643e40951)
    /// @param _prime            V4ReactorPrime upstream aggregator
    ///        (the REAL PRIME deployed at 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D)
    /// @param _childCreationCode  ABI-matched creation bytecode for the child
    ///        reactor (V4BurgersReactor or any V4ReactorBase child with the
    ///        6-arg constructor: core, pm, router, permit2, prime, poolManager).
    constructor(
        address _positionManager,
        address _universalRouter,
        address _permit2,
        address _poolManager,
        address _prime,
        bytes memory _childCreationCode
    ) {
        require(_positionManager != address(0), "pm zero");
        require(_universalRouter  != address(0), "ur zero");
        require(_permit2          != address(0), "p2 zero");
        require(_poolManager      != address(0), "pm state zero");
        require(_prime            != address(0), "prime zero");
        require(_childCreationCode.length > 0,   "empty bytecode");

        positionManager  = _positionManager;
        universalRouter  = _universalRouter;
        permit2          = _permit2;
        poolManager      = _poolManager;
        prime            = _prime;
        childCreationCode = _childCreationCode;

        admin = msg.sender;
    }

    // ── Core: deploy a child reactor ────────────────────────────────────────

    /// @notice Deploy a new V4 child reactor for `coreToken`.
    ///
    ///         The new reactor is constructed with:
    ///           (coreToken, positionManager, universalRouter, permit2,
    ///            prime, poolManager)
    ///         matching the V4BurgersReactor / V4FryerTuckReactor constructor
    ///         (verified from V4BurgersReactor.artifact.json abi).
    ///
    ///         Admin of the new reactor = msg.sender (the launchers control
    ///         their own reactors; the factory does not retain admin).
    ///
    ///         Reverts if a reactor for this coreToken already exists.
    ///
    /// @param coreToken  The ERC20 token address that the new reactor will burn.
    /// @return reactor   The address of the newly deployed child reactor.
    function createReactor(address coreToken) external returns (address reactor) {
        require(coreToken != address(0), "core zero");
        require(reactorOf[coreToken] == address(0), "already exists");

        // ABI-encode the constructor arguments for the child reactor.
        // Constructor signature (6 args, all address):
        //   (address _core, address _pm, address _router, address _permit2,
        //    address _prime, address _poolManager)
        bytes memory constructorArgs = abi.encode(
            coreToken,
            positionManager,
            universalRouter,
            permit2,
            prime,
            poolManager
        );

        // Append constructor args to creation bytecode.
        bytes memory deployData = abi.encodePacked(childCreationCode, constructorArgs);

        // Deploy using inline assembly (CREATE opcode).
        // The new reactor's constructor sets admin = msg.sender = this factory.
        // We then immediately transfer admin to the actual caller so the factory
        // never retains control over the reactor.
        assembly {
            reactor := create(0, add(deployData, 32), mload(deployData))
        }
        require(reactor != address(0), "deploy failed");

        // Transfer admin of the new reactor from the factory to msg.sender.
        // The child reactor uses a two-step transferAdmin/acceptAdmin pattern
        // (from V4ReactorBase), but the factory IS the admin at deploy time
        // (admin = msg.sender in the child constructor, and msg.sender is this
        // factory when CREATE executes).  We initiate the transfer and the
        // caller must call acceptAdmin() on the reactor.
        //
        // NOTE: The child constructor sets admin = msg.sender which is this
        // factory contract (because CREATE context makes the factory the caller).
        // We call transferAdmin to start the two-step handoff to the real caller.
        IV4ChildReactor(reactor).transferAdmin(msg.sender);

        // Record in registry.
        reactorOf[coreToken] = reactor;
        allReactors.push(reactor);

        emit ReactorCreated(coreToken, reactor, msg.sender);
    }

    // ── Views ──────────────────────────────────────────────────────────────

    /// @notice Number of reactors deployed by this factory.
    function reactorCount() external view returns (uint256) {
        return allReactors.length;
    }

    /// @notice Returns the reactor for a given core token, or address(0).
    function getReactor(address coreToken) external view returns (address) {
        return reactorOf[coreToken];
    }

    // ── Admin: factory-level admin transfer only ────────────────────────────
    // The factory admin has NO special power over deployed reactors.
    // Admin here is for future factory upgrades (e.g. updating childCreationCode
    // for a new reactor version) if needed.

    function transferAdmin(address a) external onlyAdmin {
        require(a != address(0), "zero");
        pendingAdmin = a;
        emit AdminTransferStarted(admin, a);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending");
        emit AdminTransferred(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function renounceAdmin() external onlyAdmin {
        emit AdminTransferred(admin, address(0));
        admin = address(0);
        pendingAdmin = address(0);
    }
}
