// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RHVaultFactory — Community vault factory for Robinhood Chain (4663)
/// @notice Deploys BurgersCommunityVault instances via CREATE2 (bytecode-stamped
///         factory). Each vault is a FRESH DEPLOY with constructor-baked immutables
///         (posm, router, permit2, poolManager, token keys, tick range, owner).
///         BurgersCommunityVault uses constructor-set immutables (not initialize()),
///         so EIP-1167 clones are NOT used here — each call to createVault() deploys
///         the full vault bytecode with its own immutable wiring.
///
/// @dev    Ground truth addresses (from rh-v4-addresses.json + rh-burgers-route.json
///         + rh-ftp-vault-v2.json, all verified on-chain 2026-07-13):
///           poolManager  = 0x8366a39CC670B4001A1121B8F6A443A643e40951
///           positionMgr  = 0x58daec3116aae6D93017bAAea7749052E8a04fA7
///           universalRouter = 0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77
///           permit2      = 0x000000000022D473030F116dDEE9F6B43aC78BA3
///           usdg         = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168
///           ftpVault     = 0x873739aeD7b49f005965377b5645914b1D78Ccd3
///           burgers      = 0xf796e42EA375bcD592c892FE64968Ba06188bbA3
///           weth         = 0x0bd7d308f8e1639fab988df18a8011f41eacad73
///
/// @dev    PoolKeys (from rh-burgers-route.json + rh-ftp-vault-v2.json):
///           bfKey (BURGERS/FTP fee=10000 ts=200): c0=ftpVault c1=burgers
///           bwKey (BURGERS/WETH doppler fee=8388608 ts=200 hooks=0x4e34..):
///                  c0=weth c1=burgers
///           wuKey (WETH/USDG vanilla fee=3000 ts=60): c0=weth c1=usdg
///           tickLower=416600 tickUpper=424800 (the reactor's BURGERS/FTP range)
///
/// @dev    No-frills style: no proxy, no upgrades, no owner on the factory itself.
///         Deployer calls createVault(communityOwner, salt) and gets back the
///         vault address. Caller must then transfer the V4 position NFT to the
///         vault and call vault.adoptPosition(tokenId) to activate it.

/// ── Minimal interface for BurgersCommunityVault constructor Init struct ──────
struct PoolKey {
    address currency0;
    address currency1;
    uint24  fee;
    int24   tickSpacing;
    address hooks;
}

/// @dev Mirrors BurgersCommunityVault.Init exactly (same field order + types)
struct VaultInit {
    address usdg;
    address ftpVault;
    address burgers;
    address weth;
    address posm;
    address router;
    address permit2;
    address poolManagerState;
    PoolKey bfKey;
    PoolKey bwKey;
    PoolKey wuKey;
    int24   tickLower;
    int24   tickUpper;
    address owner;
}

contract RHVaultFactory {

    // ── Canonical RH chain addresses (chain 4663) ────────────────────────────
    // All grounded from rh-v4-addresses.json + rh-burgers-route.json + rh-ftp-vault-v2.json
    address public constant POOL_MANAGER  = 0x8366a39CC670B4001A1121B8F6A443A643e40951;
    address public constant POSM          = 0x58daec3116aae6D93017bAAea7749052E8a04fA7;
    address public constant ROUTER        = 0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77;
    address public constant PERMIT2       = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public constant USDG          = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address public constant FTP_VAULT     = 0x873739aeD7b49f005965377b5645914b1D78Ccd3;
    address public constant BURGERS       = 0xf796e42EA375bcD592c892FE64968Ba06188bbA3;
    address public constant WETH          = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73;
    // Deep-route hook for BURGERS/WETH doppler pool (grounded from rh-burgers-route.json)
    address public constant BW_HOOKS      = 0x4e3468951D49f2EEa976eD0D6e75fFCb44a9a544;

    // ── Vault implementation bytecode ────────────────────────────────────────
    // BurgersCommunityVault (build D2) compiled artifact: BurgersCommunityVault.artifact.json
    // viaIR=true, optimizer runs=200, evmVersion=paris, solc 0.8.35+commit.47b9dedd
    // Callers MUST ensure this bytecode matches the artifact before any createVault call.
    // bytes cannot be immutable in Solidity; stored in regular storage (set once in constructor).
    bytes public implBytecode;

    // ── Registry ─────────────────────────────────────────────────────────────
    address[] public vaults;
    mapping(address => address[]) public vaultsByOwner;

    // ── Events ───────────────────────────────────────────────────────────────
    event VaultDeployed(
        address indexed vault,
        address indexed owner,
        bytes32 indexed salt,
        int24 tickLower,
        int24 tickUpper
    );

    // ── Constructor ───────────────────────────────────────────────────────────
    /// @param _implBytecode Creation bytecode of BurgersCommunityVault (without
    ///        constructor args — the factory appends the ABI-encoded Init struct
    ///        when deploying each clone). Pass the bytecode field from
    ///        BurgersCommunityVault.artifact.json.
    constructor(bytes memory _implBytecode) {
        require(_implBytecode.length > 0, "empty bytecode");
        implBytecode = _implBytecode;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  CREATE VAULT
    // ═════════════════════════════════════════════════════════════════════════

    /// @notice Deploy a new BurgersCommunityVault wired to canonical RH V4 infra.
    /// @param  vaultOwner   Address that will own and manage the new vault
    ///                      (calls adoptPosition, setSlippage, withdrawPosition).
    /// @param  tickLower    Lower tick of the BURGERS/FTP V4 position range.
    ///                      Use 416600 for the standard reactor range (verified on-chain).
    /// @param  tickUpper    Upper tick of the BURGERS/FTP V4 position range.
    ///                      Use 424800 for the standard reactor range (verified on-chain).
    /// @param  salt         CREATE2 salt — allows deterministic address prediction.
    ///                      Pass keccak256(abi.encode(vaultOwner, nonce)) or any bytes32.
    /// @return vault        The deployed vault address.
    function createVault(
        address vaultOwner,
        int24   tickLower,
        int24   tickUpper,
        bytes32 salt
    ) external returns (address vault) {
        require(vaultOwner != address(0), "zero owner");
        require(tickLower < tickUpper,    "bad tick range");

        // Build the Init struct with canonical RH addresses + caller-supplied range/owner
        VaultInit memory init = VaultInit({
            usdg:             USDG,
            ftpVault:         FTP_VAULT,
            burgers:          BURGERS,
            weth:             WETH,
            posm:             POSM,
            router:           ROUTER,
            permit2:          PERMIT2,
            poolManagerState: POOL_MANAGER,
            // bfKey: BURGERS/FTP fee=10000 ts=200 — sorted c0=FTP(lower addr) c1=BURGERS
            bfKey: PoolKey({
                currency0:   FTP_VAULT,
                currency1:   BURGERS,
                fee:         10000,
                tickSpacing: 200,
                hooks:       address(0)
            }),
            // bwKey: BURGERS/WETH doppler fee=8388608 ts=200 — sorted c0=WETH c1=BURGERS
            bwKey: PoolKey({
                currency0:   WETH,
                currency1:   BURGERS,
                fee:         8388608,
                tickSpacing: 200,
                hooks:       BW_HOOKS
            }),
            // wuKey: WETH/USDG vanilla fee=3000 ts=60 — sorted c0=WETH c1=USDG
            wuKey: PoolKey({
                currency0:   WETH,
                currency1:   USDG,
                fee:         3000,
                tickSpacing: 60,
                hooks:       address(0)
            }),
            tickLower: tickLower,
            tickUpper: tickUpper,
            owner:     vaultOwner
        });

        // Encode: creation bytecode + ABI-encoded constructor arg (the Init tuple)
        bytes memory deployData = abi.encodePacked(implBytecode, abi.encode(init));

        assembly {
            vault := create2(0, add(deployData, 0x20), mload(deployData), salt)
        }
        require(vault != address(0), "deploy failed");

        // Validate the vault wired correctly (smoke-check one immutable)
        (bool ok, bytes memory retData) = vault.staticcall(
            abi.encodeWithSignature("ftpVault()")
        );
        require(ok && abi.decode(retData, (address)) == FTP_VAULT, "wiring check failed");

        vaults.push(vault);
        vaultsByOwner[vaultOwner].push(vault);

        emit VaultDeployed(vault, vaultOwner, salt, tickLower, tickUpper);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  VIEWS
    // ═════════════════════════════════════════════════════════════════════════

    function vaultCount() external view returns (uint256) {
        return vaults.length;
    }

    function vaultsFor(address owner_) external view returns (address[] memory) {
        return vaultsByOwner[owner_];
    }

    /// @notice Predict the CREATE2 address before deployment.
    function predictAddress(
        address vaultOwner,
        int24   tickLower,
        int24   tickUpper,
        bytes32 salt
    ) external view returns (address) {
        VaultInit memory init = VaultInit({
            usdg:             USDG,
            ftpVault:         FTP_VAULT,
            burgers:          BURGERS,
            weth:             WETH,
            posm:             POSM,
            router:           ROUTER,
            permit2:          PERMIT2,
            poolManagerState: POOL_MANAGER,
            bfKey: PoolKey({ currency0: FTP_VAULT, currency1: BURGERS, fee: 10000, tickSpacing: 200, hooks: address(0) }),
            bwKey: PoolKey({ currency0: WETH, currency1: BURGERS, fee: 8388608, tickSpacing: 200, hooks: BW_HOOKS }),
            wuKey: PoolKey({ currency0: WETH, currency1: USDG, fee: 3000, tickSpacing: 60, hooks: address(0) }),
            tickLower: tickLower,
            tickUpper: tickUpper,
            owner:     vaultOwner
        });
        bytes memory deployData = abi.encodePacked(implBytecode, abi.encode(init));
        bytes32 initHash = keccak256(deployData);
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initHash)))));
    }
}
