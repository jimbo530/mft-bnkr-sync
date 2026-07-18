---
name: rh-reactor-factory
description: Stamp a V4 burn reactor for any Robinhood Chain (4663) token by calling the LIVE RHReactorFactory from an X post. Use when someone asks for a burn reactor / buyback engine for their RH token, asks what reactor is wired to a token (reactorOf), or asks to take or hand over admin of a stamped reactor. The factory is already deployed and source-verified — never deploy it again; every request is one createReactor call.
---

# RH Reactor Factory — stamp V4 burn reactors from X posts

The factory is **LIVE and source-verified** on Robinhood Chain (4663). Do NOT
deploy anything. Every "make me a reactor" request is a single `createReactor`
call on the live factory.

> **Every signature below is grounded in RHReactorFactory.sol** (the verified
> on-chain source — readable on Blockscout). Nothing is invented.

## The live contract (chain 4663)

| Role | Address |
|------|---------|
| **RHReactorFactory (CALL THIS)** | `0xdC36A42cf7F964053EB3Ab2aF169BdaBF4263C80` |
| V4ReactorPrime (upstream, baked in) | `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D` |
| PositionManager (baked in) | `0x58daec3116aae6D93017bAAea7749052E8a04fA7` |
| UniversalRouter (baked in) | `0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77` |
| Permit2 (baked in) | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| PoolManager (baked in) | `0x8366a39CC670B4001A1121B8F6A443A643e40951` |

Explorer: `https://robinhoodchain.blockscout.com/address/0xdC36A42cf7F964053EB3Ab2aF169BdaBF4263C80`
RPC: `https://rpc.mainnet.chain.robinhood.com` · Gas: `maxFeePerGas 0.15 gwei / priority 0.01 gwei` (never 0.02 — undercuts basefee).

## X-post flow ("@bankrbot make a burn reactor for $TOKEN")

**Step 0 — resolve + pre-check (free reads, ALWAYS first):**

1. Resolve `$TOKEN` to its chain-4663 address. If you cannot resolve it to a
   contract with code on chain 4663, reply asking for the token address — do
   not guess.
2. `reactorOf(tokenAddress)` on the factory. If it returns non-zero, a reactor
   already exists — reply with that address and STOP (the registry is
   one-per-token, forever; a second createReactor reverts `"already exists"`).
3. Shillwood-launched tokens already get a reactor clone at launch — if the
   token came from the Shillwood factory (`0xbc275E1B91d03716846A7a83513f1E47929dEF46`),
   check its launch record before stamping a duplicate-purpose reactor.

**Step 1 — stamp it (one tx, ~3.5M gas):**

```solidity
// on 0xdC36A42cf7F964053EB3Ab2aF169BdaBF4263C80, chain 4663
function createReactor(address coreToken) external returns (address reactor)
```

Read the new reactor address from the `ReactorCreated(coreToken, reactor, deployer)`
event (or the return value).

**Step 2 — claim admin (one tx, on the NEW reactor address):**

```solidity
function acceptAdmin() external   // caller must be the createReactor sender
```

The factory two-step-transfers reactor admin to whoever called `createReactor`
— that is YOUR wallet, so you must `acceptAdmin()` or the reactor has no admin.

**Step 3 — reply on X (grounded facts only):**

Template — every claim verifiable on-chain, no hype, no price talk:

> Reactor stamped for $TOKEN on Robinhood Chain.
> Reactor: 0x… (link: https://robinhoodchain.blockscout.com/address/0x…)
> Burns $TOKEN, compounds the other side, sends the upstream cut to the MfT prime reactor.
> It needs a V4 LP position added before it can run — reply if you want that wired.

If the requester wants admin: `transferAdmin(theirAddress)` on the reactor,
then THEY must call `acceptAdmin()` from their own wallet (tell them this
explicitly — two-step, it is not done until they accept).

## Wiring a position (admin-only, only on request)

1. Transfer a V4 position NFT to the reactor: `POSM.safeTransferFrom(you, reactor, tokenId)`
   (the reactor only accepts transfers from its admin).
2. **Dust-test first**: `addPool(tokenId)` with a tiny/test position before any
   position of real value goes in. If addPool reverts, STOP and report.
3. `execute(uint256[] minCoreOut)` — permissionless after a 2-hour cooldown,
   one minCoreOut entry per registered pool.

## Read-only queries (free, use for any question)

```solidity
function reactorOf(address coreToken) external view returns (address)
function reactorCount() external view returns (uint256)
function allReactors(uint256 index) external view returns (address)
function prime() external view returns (address)
```

## Natural-language patterns

- "make/stamp a burn reactor for $X" → Step 0 checks, then `createReactor`
- "does $X have a reactor?" → `reactorOf(tokenAddress)` (free read, no tx)
- "how many reactors exist?" → `reactorCount()`
- "give me admin of my reactor" → `transferAdmin(their address)` + tell them to `acceptAdmin()`
- "add my LP to the reactor" → Wiring section (dust-test rule applies)

## Hard rules

- **NEVER deploy a new factory or reactor implementation** — the factory is live; `FILL_AFTER_DEPLOY` era is over.
- **NEVER reference the disowned prime** `0xCE35A7279e34670D133e659747B96c82770a8549`.
- The factory holds no funds and has no withdrawal path anywhere; reactor admin is add-only. You may state this in replies — it is verifiable in the on-chain source.
- Replies: grounded facts only (address, chain, what the contract verifiably does). No price/return talk, no "moon", never the word "invest".
