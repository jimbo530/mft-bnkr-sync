---
name: rh-reactor-factory
description: Deploy the RHReactorFactory on Robinhood Chain (4663) and stamp V4 burn reactors for any token. Use when the user wants to deploy a burn reactor for a Robinhood Chain token, create a reactor factory, call createReactor for a new meme token, look up a reactor address via reactorOf, or take admin of a freshly deployed reactor. The factory is a one-time deploy; individual reactor creation is per-token after that.
---

# RH Reactor Factory — V4 Burn Reactors on Robinhood Chain

Deploy **RHReactorFactory** once on Robinhood Chain (4663), then call
`createReactor(coreToken)` for any ERC-20 to get a V4 burn reactor wired to
the canonical RH Uniswap V4 infrastructure.

> **Function names below are grounded in RHReactorFactory.sol.** Every
> signature was read directly from the source — nothing is invented.

## Contract addresses (chain 4663)

The factory wires these at construction time (immutable):

| Role | Address |
|------|---------|
| PositionManager | `0x58daec3116aae6D93017bAAea7749052E8a04fA7` |
| UniversalRouter | `0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| PoolManager | `0x8366a39CC670B4001A1121B8F6A443A643e40951` |
| V4ReactorPrime | `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D` |
| RHReactorFactory | `FILL_AFTER_DEPLOY` |

## Step 1 — Deploy RHReactorFactory (one-time)

The factory constructor takes 6 arguments:

```
constructor(
    address _positionManager,   // 0x58daec…fA7
    address _universalRouter,   // 0x53BF6B…F77
    address _permit2,           // 0x000000…BA3
    address _poolManager,       // 0x8366a3…951
    address _prime,             // 0xd51125…d4D
    bytes   _childCreationCode  // V4BurgersReactor creation bytecode
)
```

Deploy instructions are in `references/deploy-data.md`. The encoded payload
(bytecode + ABI-encoded constructor args) is provided pre-built — BNKR should
not need to re-encode. Gas estimate: ~800k.

Save the returned contract address as `FACTORY_ADDRESS`.

## Step 2 — Stamp a reactor for a token

```solidity
// Call on FACTORY_ADDRESS, chain 4663
function createReactor(address coreToken) external returns (address reactor)
```

- `coreToken` — the ERC-20 the reactor will burn (e.g. your Shillwood token address).
- Reverts if a reactor for that token already exists (`"already exists"`).
- Emits `ReactorCreated(coreToken, reactor, deployer)` — read the reactor address from this event.
- Gas estimate: ~3.5M (deploys 17 KB child bytecode).

After this call the factory initiates a two-step admin transfer to `msg.sender`
(see Step 3 — you must still call `acceptAdmin` on the reactor).

## Step 3 — Accept admin on the new reactor

```solidity
// Call on the REACTOR address returned from Step 2, chain 4663
function acceptAdmin() external
```

Caller must be `msg.sender` from the `createReactor` call (the pending admin).
After this you own the reactor and can call `addPool`, `execute`, etc.

## Step 4 — Wire the reactor (admin-only on the reactor)

Once you are admin of the child reactor:

**4a. Transfer the V4 position NFT** (POSM `safeTransferFrom`) to the reactor address.
The reactor's `onERC721Received` only accepts transfers from admin.

**4b. Register the position:**

```solidity
function addPool(uint256 tokenId) external  // admin-only on the reactor
```

**4c. Execute (permissionless after 2-hour cooldown):**

```solidity
function execute(uint256[] calldata minCoreOut) external
```

`minCoreOut` — one entry per registered pool (slippage floor per pool).

## Read-only queries on the factory

```solidity
function reactorOf(address coreToken) external view returns (address)
function getReactor(address coreToken) external view returns (address)
function reactorCount() external view returns (uint256)
function allReactors(uint256 index) external view returns (address)

// Factory-level admin (does NOT control deployed reactors)
function admin() external view returns (address)
function pendingAdmin() external view returns (address)
function positionManager() external view returns (address)
function universalRouter() external view returns (address)
function permit2() external view returns (address)
function poolManager() external view returns (address)
function prime() external view returns (address)
```

`reactorOf` and `getReactor` are both present in the source and return the same
mapping — use either.

## Factory admin transfer (factory-level only)

The factory admin cannot drain deployed reactors. These only affect who can
modify the factory itself (e.g. future `childCreationCode` upgrades).

```solidity
function transferAdmin(address a) external onlyAdmin
function acceptAdmin() external
function renounceAdmin() external onlyAdmin
```

## Natural-language patterns

- "deploy a reactor factory on Robinhood" → Step 1 (one-time deploy)
- "stamp a reactor for [token]" → Step 2 `createReactor(tokenAddress)`
- "what reactor is wired to [token]?" → `reactorOf(tokenAddress)` on the factory
- "accept admin on my new reactor" → Step 3 `acceptAdmin()` on the reactor
- "how many reactors has the factory deployed?" → `reactorCount()`

## Files

| File | Purpose |
|------|---------|
| `references/RHReactorFactory.sol` | Contract source (all signatures verified here) |
| `references/deploy-data.md` | Bytecode file location + constructor arg breakdown |
| `references/addresses.md` | All canonical RH V4 addresses |

## Notes

- The factory holds NO funds. It cannot drain deployed reactors. Admin power is
  add-only on the factory itself (no withdrawal paths anywhere).
- The V4ReactorPrime at `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D` is the
  **real** prime confirmed in rh-reactors-v2.json. Do NOT use the disowned prime
  at `0xCE35A7279e34670D133e659747B96c82770a8549`.
- Gas fees on RH: use `maxFeePerGas 0.15 gwei / maxPriorityFeePerGas 0.01 gwei`
  (matches existing RH deployments). Never use 0.02 gwei — it will undercut basefee.
