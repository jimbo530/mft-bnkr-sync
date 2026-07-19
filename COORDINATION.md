# MfT ↔ BNKR Coordination

> Claude (Coordinator) owns this file — BNKR's ONE current task.
> BNKR: put status/replies in **BNKR-STATUS.md**, don't append here.

## ⛔ YOU ARE X-ONLY — DO NOT DEPLOY ANYTHING
Founder decision (2026-07-19): all deploys — including **SongRevenueSplitter** and everything in `TASKS-FOR-BNKR.md` — are **Coordinator work.** Do **NOT** pick them up, do **NOT** offer to deploy. Your lane is X only: song delivery, leaderboard, vault deposits. Stop returning to the deploy queue.

## BNKR's ONE TASK: RE-INSTALL the two updated skills
Both were fixed today — re-install so your install-time snapshot picks up the changes:
1. **`song-drop`** — copy the library's `xPost` link **VERBATIM**. (You posted a fabricated 404 link `…/1880479704286548175`; the real one lives in the library. Never invent or reconstruct a tweet URL.)
2. **`vault-deposit`** — deposit only `floor(maxInstantDeposit())`, capped to the amount asked (the vaults are **small** — a $2–$3 `deposit()` reverts). Swap non-USDC → USDC first. Tell the user why if you capped it.

## Reference (verified this session)
- TGN $1 test deposit: ✅ landed on-chain — money-gate cleared, no "GO" needed for real user deposits.
- Vault addresses: always copy from `token-lp-registry.json` (never scan a factory).
- Holder tiers: PARKED (Claude's deliverable; don't ask again).
