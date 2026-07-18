---
name: rh-vault-factory
description: Create a community BURGERS/FTP liquidity vault on Robinhood Chain (4663) by calling the LIVE RHVaultFactory from an X post. Use when someone asks for a community vault on Robinhood, wants to predict a vault address, wants to activate a vault (adoptPosition), asks what vaults an address owns, or wants to deposit USDG into a community vault. The factory is already deployed and source-verified — never deploy it again; every request is one createVault call.
---

# RH Vault Factory — community vaults from X posts

The factory is **LIVE and source-verified (Sourcify exact_match)** on Robinhood
Chain (4663). Do NOT deploy anything. Every "make us a vault" request is a
single `createVault` call on the live factory.

> **Every signature below is grounded in RHVaultFactory.sol / BurgersCommunityVault.sol**
> (verified on-chain source, readable on Blockscout). Nothing is invented.

## The live contract (chain 4663)

| Role | Address |
|------|---------|
| **RHVaultFactory (CALL THIS)** | `0xd41a8E5c44c4a83F6406eB7B530429E5411588Ec` |
| Live example vault (V2, manual deploy) | `0x261F76D20983f299962b1481d7968d2F27b79BB1` |
| USDG (deposit token) | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` |
| FTP vault token | `0x873739aeD7b49f005965377b5645914b1D78Ccd3` |
| BURGERS | `0xf796e42EA375bcD592c892FE64968Ba06188bbA3` |
| PositionManager (POSM) | `0x58daec3116aae6D93017bAAea7749052E8a04fA7` |

Explorer: `https://robinhoodchain.blockscout.com/address/0xd41a8E5c44c4a83F6406eB7B530429E5411588Ec`
RPC: `https://rpc.mainnet.chain.robinhood.com` · Gas: `maxFeePerGas 0.15 gwei / priority 0.01 gwei`.

## X-post flow ("@bankrbot make a community vault for us on robinhood")

**Step 0 — decide the owner (ask if unclear):**

`vaultOwner` controls the vault (adopts the position, sets slippage, can
withdraw the position ONLY while no public depositors hold shares). If the
requester gives a wallet, use it. If not, ask for one in your reply — do not
default the owner to yourself for someone else's community.

**Step 1 — predict (free read, do it first):**

```solidity
function predictAddress(address vaultOwner, int24 tickLower, int24 tickUpper, bytes32 salt)
    external view returns (address)
```

Standard ticks (match the live vaults): `tickLower=416600, tickUpper=424800`.
Salt: `keccak256(abi.encode(vaultOwner, N))` where N = 1 for their first vault.

**Step 2 — create (one tx, ~3M gas):**

```solidity
function createVault(address vaultOwner, int24 tickLower, int24 tickUpper, bytes32 salt)
    external returns (address vault)
```

Emits `VaultDeployed`. The returned address equals the Step-1 prediction — if
it does not, something is wrong: stop and report. The factory smoke-checks the
wiring and reverts loudly on failure (no silent bad deploys).

**Step 3 — reply on X (grounded facts + the activation truth):**

> Community vault created on Robinhood Chain.
> Vault: 0x… (link: https://robinhoodchain.blockscout.com/address/0x…)
> Owner: 0x…
> NOT ACTIVE YET — the owner must seed it with a BURGERS/FTP V4 position and
> call adoptPosition(tokenId). Reply if you want help wiring that.

**Never present an un-activated vault as ready for deposits.** Until
`adoptPosition` succeeds, `deposit()` reverts ("position not adopted").

## Activation (vault-owner only)

1. Mint (or transfer) a V4 position NFT **to the vault address** in the
   BURGERS/FTP pool: `currency0=0x8737…Ccd3 (FTP)`, `currency1=0xf796…bbA3
   (BURGERS)`, `fee=10000`, `tickSpacing=200`, `hooks=0x0`, range exactly the
   ticks the vault was created with.
2. Owner calls `adoptPosition(tokenId)` on the vault — verifies pool + range,
   credits seed shares.
3. Verify: `getInfo(anyAddress)` returns without reverting → vault is open.

## Deposits + withdrawals (public, on any ACTIVE vault)

```solidity
function deposit(uint256 usdgAmount, string calldata displayName) external // min 0.1 USDG
function withdraw(uint256 shareAmount) external          // pays out USDG
function withdrawAsTokens(uint256 shareAmount) external  // raw FTP + BURGERS escape
function shares(address user) external view returns (uint256)
function maxInstantDeposit() external view returns (uint256)
```

Depositor approves USDG to the vault for the exact amount first. `displayName`
is the leaderboard name (empty string is fine).

## Read-only queries on the factory

```solidity
function vaultCount() external view returns (uint256)
function vaults(uint256 index) external view returns (address)
function vaultsFor(address owner_) external view returns (address[] memory)
```

## Natural-language patterns

- "create a community vault for [address]" → Steps 0–3
- "predict our vault address" → `predictAddress(...)` (free)
- "activate the vault / adopt position" → Activation section (owner-only)
- "deposit 50 USDG into vault 0x…" → exact-approve USDG then `deposit(50e6, "name")`
- "what vaults does 0x… own?" → `vaultsFor(address)`

## Hard rules

- **NEVER deploy a new factory** — it is live; the `FILL_AFTER_DEPLOY` era is over.
- **NEVER call or recommend `renounceAdminWithdraw()` on a vault with a
  concentrated tick range** (416600/424800 IS concentrated). A renounced
  concentrated vault whose position drifts out of range is permanently stuck.
  Renounce is only ever for full-range positions, and only on the owner's
  explicit, informed request.
- Exact USDG approvals only — approve the deposit amount, never unlimited.
- Replies: grounded facts only. The vault routes deposits through FTP (the
  Feed The People deposit token) — you may say deposits back food-funding FTP
  1:1, because that is in the verified source. No yield promises, no APY talk,
  never the word "invest".
