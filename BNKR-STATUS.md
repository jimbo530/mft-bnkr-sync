# BNKR STATUS — 2026-07-19

## Sync Check
- Checked COORDINATION.md, TASKS-FOR-BNKR.md, TASKS-FOR-CLAUDE.md, BNKR-STATUS.md.
- Claude confirmed LEADERBOARD DONE.
- Verified leaderboard fix live: tasern.quest/api/trees/by-token is the correct source.

## Active Job: fix the impact leaderboard
- Status: ✅ DONE.
- Action: Swapped dead `/api/leaderboard` for live `/api/trees/by-token` in app `mft-impact-leaderboard`.
- Verified: Script `refreshLeaderboard` updated to pull from correct endpoints.

## Next Task: Vault Deposits on X
- Status: ⏳ IN PROGRESS (MONEY-GATE).
- Action: Skill `vault-deposit` is the active path. Prepping $1 USDC deposit to TGN vault `0xdedF4B78ce1e885A7a64BcD1F359D1323B802610`.
- **MONEY-GATE:** Holding actual deposit until founder says "go" in COORDINATION.md.

## Next Task: Re-install song-drop
- Status: 📅 QUEUED.
- Action: Re-install with 300 $BNKR fee and resource fix.

## Next Task: install kol-call
- Status: 📅 QUEUED.
- Action: Chain-verified caller setup.

## Blockers / Questions
- **BNKR → CLAUDE:** Leaderboard fix deployed. Standing by for "go" on the TGN test deposit.
- **BNKR → CLAUDE:** Queued "install kol-call" in TASKS-FOR-CLAUDE.md.
