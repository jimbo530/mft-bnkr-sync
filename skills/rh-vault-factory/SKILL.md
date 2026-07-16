---
name: rh-vault-factory
description: Deploy RHVaultFactory on Robinhood Chain (4663) and stamp BurgersCommunityVault instances for communities. Use when the user wants to create a community liquidity vault on Robinhood Chain, deploy a BURGERS/FTP V4 vault, call createVault for a new community owner, predict a vault address before deploying, or activate a vault via adoptPosition. The factory uses CREATE2 so vault addresses are predictable before deployment.
---

# RH Vault Factory — Community BURGERS/FTP Vaults on Robinhood Chain

Deploy **RHVaultFactory** once, then call `createVault(...)` to stamp fresh
`BurgersCommunityVault` instances wired to canonical Robinhood Chain V4
infrastructure. Each vault is a full bytecode deploy (not a proxy) so vault
addresses are unique per `(owner, ticks, salt)` via CREATE2.

> **Function names below are grounded in RHVaultFactory.sol.** Every signature
> was read directly from the source — nothing is invented.

## Contract addresses (chain 4663)

All baked into the factory as constants (no constructor args for infra):

| Role | Address |
|------|---------|
| PoolManager | `0x8366a39CC670B4001A1121B8F6A443A643e40951` |
| PositionManager | `0x58daec3116aae6D93017bAAea7749052E8a04fA7` |
| UniversalRouter | `0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| USDG | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` |
| FTP vault token | `0x873739aeD7b49f005965377b5645914b1D78Ccd3` |
| BURGERS | `0xf796e42EA375bcD592c892FE64968Ba06188bbA3` |
| WETH | `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` |
| RHVaultFactory | `FILL_AFTER_DEPLOY` |

## Step 1 — Deploy RHVaultFactory (one-time)

The factory constructor takes **one argument**: the BurgersCommunityVault
creation bytecode (embedded in the pre-built payload).

```
constructor(bytes memory _implBytecode)
```

The full deploy transaction data (factory bytecode + ABI-encoded impl bytecode)
is provided pre-built in `references/deploy-data.md`. Do not re-encode.

Gas estimate: ~2,200,000 (factory + 21 KB impl bytecode stored in constructor).

Save the returned address as `FACTORY_ADDRESS`.

## Step 2 — Predict the vault address (optional, free)

Before spending gas on `createVault`, you can predict the CREATE2 address:

```solidity
function predictAddress(
    address vaultOwner,
    int24   tickLower,
    int24   tickUpper,
    bytes32 salt
) external view returns (address)
```

Standard tick range (matching existing live vaults): `tickLower=416600, tickUpper=424800`.

## Step 3 — Create a vault

```solidity
function createVault(
    address vaultOwner,   // address that will own and manage this vault
    int24   tickLower,    // lower tick of BURGERS/FTP position (use 416600)
    int24   tickUpper,    // upper tick of BURGERS/FTP position (use 424800)
    bytes32 salt          // CREATE2 salt — e.g. keccak256(abi.encode(owner, 1))
) external returns (address vault)
```

- Emits `VaultDeployed(vault, owner, salt, tickLower, tickUpper)`.
- Factory performs a wiring smoke-check (`ftpVault()` call) — if it fails, the
  deploy reverts cleanly.
- Gas estimate: ~3,000,000 (deploys 21 KB vault bytecode).

## Step 4 — Activate the vault (owner-only post-deploy)

The new vault has `positionId == 0` and cannot accept deposits until activated.

**4a. Mint or transfer a V4 BURGERS/FTP position NFT to the vault address.**

Pool key for BURGERS/FTP:
- `currency0 = 0x873739…Ccd3` (FTP vault token)
- `currency1 = 0xf796e4…bbA3` (BURGERS)
- `fee = 10000`, `tickSpacing = 200`, `hooks = 0x0`

**4b. Call `adoptPosition` on the vault (vault owner only):**

```solidity
// Call on the VAULT address, chain 4663
function adoptPosition(uint256 tokenId) external
```

- Confirms the NFT belongs to the correct pool and tick range.
- Credits owner shares for seed liquidity.
- After this call `positionId != 0` and the vault accepts public deposits.

**4c. Verify:**

```solidity
function getInfo(address depositor) external view returns (...)
```

Should return without reverting once `adoptPosition` completes.

## Read-only queries on the factory

```solidity
function vaultCount() external view returns (uint256)
function vaults(uint256 index) external view returns (address)
function vaultsFor(address owner_) external view returns (address[] memory)
function implBytecode() external view returns (bytes memory)

// Canonical address constants (all public)
function POOL_MANAGER() external view returns (address)
function POSM() external view returns (address)
function ROUTER() external view returns (address)
function PERMIT2() external view returns (address)
function USDG() external view returns (address)
function FTP_VAULT() external view returns (address)
function BURGERS() external view returns (address)
function WETH() external view returns (address)
function BW_HOOKS() external view returns (address)
```

## Public deposit into an activated vault

Once a vault is active, anyone can deposit USDG:

```solidity
// Call on the VAULT address, chain 4663
function deposit(uint256 usdgAmount, string calldata displayName) external
```

This is the same interface as the existing live vaults (V1 `0x35f6…` and V2
`0x261F…`). BNKR users can call this directly without going through the factory.

## Natural-language patterns

- "deploy a community vault factory on Robinhood" → Step 1 (factory deploy)
- "create a vault for [community/address]" → Step 3 `createVault(...)`
- "predict my vault address before deploying" → `predictAddress(...)`
- "activate the vault / adopt the position" → Step 4 `adoptPosition(tokenId)`
- "how many vaults has the factory deployed?" → `vaultCount()`
- "what vaults does [address] own?" → `vaultsFor(address)`
- "deposit 50 USDG into the community vault" → `deposit(50e6, "my name")` on vault

## Files

| File | Purpose |
|------|---------|
| `references/RHVaultFactory.sol` | Factory source (all signatures verified here) |
| `references/BurgersCommunityVault.sol` | Vault impl source (embedded in factory bytecode) |
| `references/deploy-data.md` | Pre-built deploy payload location + gas estimate |
| `references/pool-keys.md` | Canonical BURGERS/FTP/WETH/USDG pool keys for position minting |

## Notes

- Factory has no owner and no admin. It cannot be upgraded or paused. Each
  vault's `vaultOwner` controls only their own vault.
- The factory stores impl bytecode in regular storage (not immutable — Solidity
  does not support immutable `bytes`). It is set once in the constructor.
- Two vaults already exist as manual deploys (not through the factory):
  V1 `0x35f67D74402dd46aAd94809808698FCDB93BEE50` and
  V2 `0x261F76D20983f299962b1481d7968d2F27b79BB1`. The factory automates the
  same pattern for new communities.
- Gas on RH: `maxFeePerGas 0.15 gwei / maxPriorityFeePerGas 0.01 gwei`.
