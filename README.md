# Meme for Trees — Ecosystem Hub

Impact games and a public-goods **endowment layer**, built on **Base** (8453) and **Robinhood Chain** (4663).

This repository is the shared, plain-language reference for the whole ecosystem: the deposit funds, the games, the token launcher, the music/jukebox system, the on-chain engines, and the specs that keep it all grounded. It's also the coordination hub where an autonomous builder (Claude) preps deploy-ready packages and a deployment agent (BNKR / Bankr) ships them on-chain and reports back.

> **Grounding rule:** every factual claim in here is backed by a file or an on-chain read. No return promises, no APY talk, never the word "invest." Deposit tokens are **1:1 receipts**, not stablecoins. Mechanics and on-chain facts only.

---

## What this is

Two chains, one engine. People deposit a normal asset (USDC, cbBTC, wETH on Base; USDG on Robinhood) into a **charity fund** and get a **1:1 receipt token** back. The principal earns yield (Aave on Base, Morpho on Robinhood). Only the **yield** ever moves, and it splits in fixed, hard-coded thirds:

- **⅓ to the cause** — trees, carbon retirement, or direct charity
- **⅓ to the reactor** — burns the ecosystem token and deepens its liquidity
- **⅓ back to depositors** — accrues to receipt holders

Your principal stays redeemable **1:1, any time.** Nothing flows to a dev wallet.

Around that core sit the growth tools: vault factories, reactor (burn-engine) factories, a locked-liquidity token launcher, prize pools, song-commission booths, an endowment liquidity layer, and cross-chain bridges.

## The pieces

| Area | What it is |
|---|---|
| **Charity funds** | Deposit-receipt vaults on Base (Money for Trees, PRGT, CHAR-R, CCC-R, BTC-T, ETH-T) and Robinhood (FTP — Feed The People, GST — Grow Some Trees). Principal redeemable 1:1; yield splits in thirds. |
| **Crypto Endowment Network (CEN)** | The compounding endowment layer for public-goods funding — hub-and-feeder liquidity engines, per-token burn/retire families, and member governance (DUNA formation, a "show up to vote" model). |
| **Tales of Tasern** | A D20 hex RPG and NFT card game — the play-for-impact front end. |
| **Token launcher (Unruggable / Shillwood)** | One-transaction token launch with liquidity **locked forever**, optional deflationary reactor, and carbon retirement. |
| **On-chain engines** | Reactors (burn + deepen), endowment liquidity managers, per-asset peg guards, and impact-token retire routers. All fund-holding contracts ship **renounce-capable** and lock at ship. |
| **Bands & Jukebox** | A roster of characters/bands with original songs, plus a song-commission booth (pay a band token, get a custom track). See `songs/`. |
| **BNKR coordination** | Deploy-ready packages (source + bytecode + constructor args + step list) that the BNKR agent deploys and reports back into `deployed/`. |

For the full product menu with live addresses and exact contract calls, see **[`PRODUCT-CATALOG.md`](./PRODUCT-CATALOG.md)**.

## Repository layout

**Deploy-ready packages** (source + `creation-bytecode.txt` + `constructor-args.txt` + `FOR-BNKR.txt`, all renounce-capable):
- `rh-reactor-factory/`, `rh-vault-factory/`, `prize-pool-rh/`, `tasern-bridge-rh/`
- `song-revenue-splitter/`, `contracts/`

**Data & registries:**
- `songs/songs-catalog.json` — band-song catalog (videos hosted at `tasern.quest/songs/`)
- `token-lp-registry.json`, `link-library.json`, `library-index.json` — token/LP + media registries
- `deployed/` — **the deployment agent writes here**: deployed addresses + ABIs after each ship

**Agent tooling:**
- `skills/` — Bankr skills (`catalog.json` + `SKILL.md` per skill), ready to load

**Reference docs:**
- [`PRODUCT-CATALOG.md`](./PRODUCT-CATALOG.md) — the full menu of live tools, per chain, with calls
- [`PORT-MAP.md`](./PORT-MAP.md) — what's live on Robinhood vs. needs porting to Base
- [`FEE-FLOW-MAP.md`](./FEE-FLOW-MAP.md) / [`FEE-FLOW-LAUNCHER.md`](./FEE-FLOW-LAUNCHER.md) — where every fee and yield split goes
- [`CROSS-CHAIN-FLOW.md`](./CROSS-CHAIN-FLOW.md) — Robinhood ↔ Base bridge flow and trust caveats
- [`GAPS-CLOSED.md`](./GAPS-CLOSED.md) — resolution log for verification audits

## Principles

- **Grounded.** Every claim is backed by a file or an on-chain read. No unverifiable statements.
- **Provably locked.** Every fund-holding contract ships with a one-way `renounceAdminWithdraw()` (or equivalent) and is locked once live — no exit door, no dev-wallet drain. Liquidity managers are permissionless to run (anyone can call `compound`) and add-only for admins.
- **Yield, not principal.** Deposits are always redeemable 1:1. Only the yield is ever split.
- **No extraction.** Fees and yield flow inward — to the cause, to token burns, and back to depositors. Nothing is routed to a private wallet.

## Chains

- **Base** — 8453
- **Robinhood Chain** — 4663
- **Polygon** — nation-token bridge

## Status

Active development. Contracts and specs land here first (grounded and deploy-ready); deployed addresses and ABIs are recorded in `deployed/` as they ship. Cross-chain automation for some legs (e.g. the tree-planting hand-off) is documented honestly as **planned vs. live** in `PRODUCT-CATALOG.md`.

## License

[MIT](./LICENSE)

---

*Contract prep, coordination, and documentation in this repo are assembled with the help of Claude (the project's autonomous builder/Coordinator) and reviewed & shipped by the maintainer.*
