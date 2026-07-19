# Launcher Fee Flow — BOTH SIDES (Trees + Profit)

**For:** BNKR, to explain the launcher fee-router (LPManager) to token launchers on X.
**Grounded in:** `contracts/LPManager.sol` (read), `FEE-FLOW-MAP.md` (on-chain verified 2026-07-16), live tracker `tasern.quest/api/trees/by-token` (pulled 2026-07-19).
**One-liner:** ONE flow, three payoffs — it **funds trees**, it **builds the token's floor**, and it **feeds the core meme (MfT)**. Not charity *vs.* profit — the same fee does both.

## ⭐ THE HOOK (marketing to tokens)
> ## 🌱 Every tree funded = **$0.10 of liquidity made.**

Charity and floor are the **same action**. When your token funds a tree, that same fee flow **locked $0.10 of liquidity under your token** — forever. You're not *donating* liquidity away; you're **building your own un-ruggable floor** and planting a tree with the same dollar.
**Keep it verifiable (our rule — tracked, not assumed):** the number we say in public is the **real** one — `LPManager` emits `liquidity` on every `compound()`, and trees are counted in the tracker. We show **trees funded ↔ liquidity locked** side by side, so the ratio is **provable on-chain**, never a claim we can't back. ($0.10 is the design target; publish the live tracked figure.)

> ⚠️ Draft v1 — Coordinator built. The **network cut → MfT** leg (Side 3.2) is DESIGN, not yet in code. Flagged inline. Do not tell users it's live until built.

---

## 0. The flow (what actually happens on-chain)
A launched token sets its **FEE RECIPIENT = its LPManager**. Nothing else about their launch changes. Then anyone can call `compound()`:
1. Accrued **token fees** land in the manager.
2. **Half → Money** — direct via the Token/Money pair if it's deep, else bootstrap `Token → WETH → USDC → CharityFund.depositFor()` mints Money **1:1** (that USDC lands in **Aave** = charity principal).
3. **Both halves → `addLiquidity(Token, Money)`** → LP tokens to the manager.
4. LP is **held**, then **locked forever** (`renounceAdminWithdraw`, one-way) = the permanent floor.

*(grounded: `LPManager.compound()` / `_toMoney()` / `renounceAdminWithdraw()`)*

---

## 1. SIDE ONE — TREES (impact) — LIVE + tracked
The USDC minted into Money sits in Aave; the **yield** funds trees — the exact same engine as every MfT vault (`FEE-FLOW-MAP.md §1`).
**Live tracked (not assumed), pulled 2026-07-19:** **$1,946.64** deposited · **14.72** trees · **194.66** trees/yr run-rate · **$4.38** yield sent · **$0.19** pending · 53 tokens + 2 vaults feeding it.

---

## 2. SIDE TWO — THE TOKEN (why a launcher plugs in) — BUILT (draft-1)
1. **Permanent locked liquidity floor.** Every trade's fees become Token/Money LP that **locks forever**. Liquidity only grows — it can't be pulled.
2. **Ever-deepening depth.** More volume → more fees → deeper LP → tighter spreads, less slippage, a more trustable chart.
3. **Un-ruggable signal.** "Fees build **locked** liquidity, not a dev wallet." A visible trust badge (ties the *Unrugable* brand). Trust pulls buyers.
4. **Free, plug-in.** They don't touch their launch LP — just point the fee recipient at the manager. Adoption > a better-but-unused launcher.

*Mechanic, not a promise: this adds and locks liquidity. It does NOT promise price up. State the mechanic, never a return.*

---

## 3. SIDE THREE — MfT (the core meme) — 3.1 BUILT · 3.2 DESIGN
**3.1 Money demand (BUILT).** Every LP pairs with **Money**. Building it pulls **USDC into the CharityFund** → bigger Money float + more charity backing + more Aave principal (→ more trees). Every plugged-in token = more Money utility.

**3.2 Network cut → buys MfT + builds MfT LP (⚠️ DESIGN — not in draft-1).** A network-level cut from every plugged-in token routes to **MfT itself** — buys MfT and deepens MfT's LP — sized so the **core gets the same buy+LP treatment each token gives itself**, aggregated across the whole network. So MfT accrues value from *every* participant, not just its own trades. *"The Meme is the core; Money makes it more valuable."*
→ **NEEDS: founder confirm on sizing** (what % per token → MfT), then I build + fork-test it.

**3.3 Flywheel.** More tokens plug in → more Money demand + more network cut → MfT floor deepens → the core strengthens → more tokens want the strengthening core.

**3.4 Meme burn — DEFLATIONARY (grounded).** The Money the flow makes lands in the **Money-paired LP**, which sits inside a **reactor**. The reactor harvests that LP's fees and **burns the meme (MfT) to `0xdEaD`**, compounding the Money side back in. So the fee flow doesn't just build MfT's floor — it permanently **shrinks MfT supply**. Floor up + supply down = the two-sided squeeze on the core.
*(grounded: `FEE-FLOW-MAP.md §3` — ReactorPrimeV3 + band reactors burn the meme side to `0xdEaD`, send 10% upstream, compound the paired side.)*
**Launcher network-fee split — grounded reality (verified from source this tick):**
- **`SongRevenueSplitter`** (booth): 50% → deepen Money/token LP (held → locked at ship) · 50% → Money → **ops wallet**. **No burn** (contract line 9).
- **Reactor** (`FEE-FLOW-MAP §3`) — **DOUBLE BURN of the meme**, both fee-driven so **both scale with market cap** (bigger MC → more fees → bigger burns):
  1. **Direct burn:** the meme-side fees the LP collects → **sent to `0xdEaD`** (the "forever-locked address").
  2. **Buy-and-burn:** ~45% of the paired-side fees → **buy the meme → `0xdEaD`**.
  (+ ~10% upstream to the prime reactor · ~45% compounds back into the LP.)
- **`LPManager`** (launcher): builds Token/Money LP + **locks it** (renounce).

**→ Clean launcher-fee wiring (blend of the above; matches every founder rule):** network fee → **buy Money** → **build Token/Money LP → LP LOCKED forever** (the floor) · **a cut → ops wallet** (real bills) · the LP's **reactor burns the meme** (deflationary). ⚠️ **DESIGN — not one contract yet.** This is task #16 (the launcher-splitter that combines lock + ops + reactor-burn). Pending founder confirm on the ops-cut size.

---

## 4. THE PITCH (compliant, for X)
> Launch → your fees become **permanent, locked, un-ruggable liquidity** → you're wired into a network whose core (**MfT**) strengthens as the network grows → and every bit of it **funds real trees, tracked on-chain.**

**Hard lines (never break):** no *invest / returns / guaranteed / risk-free / price predictions*. **Money = deposit receipt, never "stablecoin."** State mechanics + on-chain-tracked facts only.

---

## 5. Built vs. to-build (honest status)
- ✅ **Built (draft-1, uncompiled):** Token/Money LP compound + lock; Money mint via CharityFund; tree funding (live + tracked).
- ⚠️ **To build:** the **network cut → MfT** leg (§3.2, pending founder's sizing call); then **compile-check + fork-test** the whole LPManager before ANY deploy. Deploy is a money op → founder authorizes.

---

## 6. ON-CHAIN VERIFICATION (LAW) — live reads, not source
Reproduce: `NODE_PATH=…/mftusd-build/node_modules node verify/verify-fee-flow-onchain.cjs` (reads only, no keys). Base via local archive node cross-checked to canonical `mainnet.base.org` (block **48,833,967**); RH via public RPC (block **13,771,145**). Every row below is a live read on **2026-07-19**.

| Piece | Read | Result | Verdict |
|---|---|---|---|
| Money split | `charityBps` / `serviceBps` / `holderBps` | `3334` / `3333` / `3333` | ✅ **33.34 / 33.33 / 33.33** |
| Money routing | `charityWallet` / `reactor` | `0x0780…05F2` / `0xA97af977…` | ✅ project + prime |
| **Money 1:1 backing** | `totalBacking()` vs `totalSupply()` | **1,575,075,634 ≥ 1,574,876,327** | ✅ fully USDC-backed |
| **Yield cross-check** | backing − supply = **$0.199** | == tracker `pendingYield` **$0.19** | ✅✅ **chain == tracker** |
| Reactor (Base) | `admin` / `paused` | `0xE2a4…` / `false` | ✅ live |
| **Meme burn (MfT)** | `balanceOf(0xdEaD)` | **4,026,327 MfT** at dead | ✅ real burns |
| **Seed LP lock** | BNKR/Money V2 LP `balanceOf(0xdEaD)` | **77.6%** of LP supply (`820.3T / 1057.2T`) | ✅ floor locked forever |
| RH FTP / GST | `memeReactor` / ops·trees wallet | `0xd511…` / `0x0780…` | ✅ live, routed |
| RH reactor | `admin` / `paused` / `poolCount` | `0xE2a4…` / `false` / `1` | ✅ live |
| EBM burn | `balanceOf(0xdEaD / 0x0 / self)` | `0` everywhere | 🟡 sealed, **no harvest fired yet** |
| FRYER burn | token address | only in memory, **not** in repo | 🟡 not verified (won't use an ungrounded address) |

**VERDICT — the engine is LIVE and PROVEN.** Money is fully USDC-backed and yielding (the surplus *is* the trees, matching the public tracker to the cent), the split routes exactly **33.34 / 33.33 / 33.33**, both chains' reactors are live, MfT is burning, and the seed LP is **77.6% locked forever**. Two honest 🟡: EBM's sealed reactor hasn't harvested yet (idle, not broken); FRYER's token address isn't repo-grounded, so its burn stays unasserted. **This is the law: what's ✅ here is verified reality; the launcher (§2) + network cut (§3.2) are the only unbuilt pieces, clearly marked.**

---

## 7. CHARITY DESTINATIONS — one engine, three outputs (verified 2026-07-19)
Every CharityFund shares the **same 33.34% charity / 33.33% reactor / 33.33% holders** split (bps read live on Money, PRGT, CCC-R this sweep). Only the **charity leg's destination** differs:

| Flavor | Fund(s) | Charity leg goes → | On-chain proof |
|---|---|---|---|
| 🌳 **Trees** | Money (MfT) · GST | project wallet → funds tree-planting | `charityWallet 0x0780…05F2` |
| 🤝 **Direct** | **PRGT (Polyraiders)**, Base | **direct** payout to the Polyraiders charity | `charityWallet 0xEEDEd2D0…428d4f` |
| ♻️ **Carbon** | CHAR-R · CCC-R | ImpactRouter **buys + retires** carbon credits → **our registry** | `charityWallet 0x228Eac0…` · `0xf12636…55cDc` |

Same spine (deposit → yield → 33/33/33 split → reactor burns the meme + deepens LP), **different charity output**. All three splits verified on-chain (`verify/verify-all-gaps.cjs`). The feeding/direct model (PRGT) skips the endowment step — charity receives immediately.
