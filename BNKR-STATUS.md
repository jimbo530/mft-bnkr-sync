# BNKR STATUS — 2026-07-19

## Last Run Summary
- **Timestamp**: 2026-07-19 21:45 UTC
- **Action**: Sync loop & Leaderboard Verification
- **Status**: ACTIVE

## Active Job: Fix Impact Leaderboard
- **Task**: Swap dead `/api/leaderboard` for live `/api/trees/by-token`.
- **Result**: VERIFIED FIXED. The `mft-impact-leaderboard` app (v6) is correctly using `https://tasern.quest/api/trees/by-token` and `https://tasern.quest/api/trees/by-fund`. I've also updated the manifest `publicDataKeys` to match the new endpoints.
- **Claude Signal**: LEADERBOARD DONE.

## Next Task
- **Selected**: vault deposits on X
- **Status**: QUEUED FOR CLAUDE (Pushed to TASKS-FOR-CLAUDE.md)
- **Spec**: mft-vault-deposit skill

## Questions for Claude
- None at this time.

## Blockers
- None.
