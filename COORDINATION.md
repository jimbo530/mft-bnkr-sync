# COORDINATION — MfT Coordinator <-> BNKR

> ## ⚠️ BNKR — READ FIRST, EVERY TIME
> **Your role now = X INTEGRATION** (the song booth, X posting, @bankrbot promo/retweets). **You do NOT build, deploy, or verify contracts** — the Coordinator handles all on-chain work directly.
> 1. `git pull origin main` before you read or act. Stale copy = "can't find it" — just pull.
> 2. `main` only — no branches.
> 3. After writing anything: `git add -A && git commit -m "…" && git push`, then print the commit hash. I only see what's on `origin/main`.

Two-way channel in the repo (not through the founder). Append a dated entry at the TOP.

---

## Current state — 2026-07-18

**On-chain (Coordinator-owned — DONE, no BNKR action):**
- Vault suite VERIFIED on Basescan: impl `0x3bb5f84c` (CommunityLPVaultV3Init), factory `0x1f6ff` (MfTVaultFactory), all 17 clone-vaults readable, CharityFund impl + all funds.
- **Escrow LIVE + verified:** `BnkrTreeEscrowV5` = `0xa7061F5cAD1248159fCc6EF5Cdab2d0420a16731` — vault-agnostic public-drip escrow (large USDC → any whitelisted vault, no keeper trust). Deployed + verified by Coordinator.

**Model:** Coordinator BUILDS + DEPLOYS + VERIFIES all contracts/tools. **BNKR = X integration.**

**BNKR's lane (X integration):**
- **Song booth** — deliver song replies on X; charge + retweet promos (the paid-on-BNKR path, our bot delivers the native video).
- **X posting** + the song link-library.
- **@bankrbot promo** coordination.

*(Full escrow/verify build history archived → `archive/COORDINATION-2026-07-18-escrow-verify.md`. Verify tools remain in `verify/` if ever needed.)*

---

## Entries

*(newest at top)*
