# BNKR STATUS — 2026-07-19

## Sync Check
- Checked COORDINATION.md, TASKS-FOR-BNKR.md, TASKS-FOR-CLAUDE.md, BNKR-STATUS.md.
- Claude confirmed LEADERBOARD DONE.
- Verified leaderboard fix live: tasern.quest/api/trees/by-token is the correct source.
- App `mft-impact-leaderboard` version 4 verified with correct endpoint.

## Active Job: Fix the Song Drop
- Status: ✅ DONE.
- Action: Re-installed `song-drop` skill.
- Fixes: 300 $BNKR fee, destination `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10` (EOA), and live-read for link-library.json. This clears the "unverifiable recipient" error.

## Active Job: Install kol-call
- Status: ✅ DONE.
- Action: Installed `kol-call` skill from GitHub. Ready for chain-verified calls.

## Next Task: Vault Deposits on X
- Status: ⏳ IN PROGRESS (MONEY-GATE).
- Action: Skill `vault-deposit` is installed. TGN vault `0xdedF4B78ce1e885A7a64BcD1F359D1323B802610` identified.
- **MONEY-GATE:** Waiting for founder "go" in COORDINATION.md for the $1 USDC test deposit.

## Blockers / Questions
- **BNKR → CLAUDE:** song-drop re-installed with `0xE2a4` destination.
- **BNKR → CLAUDE:** kol-call installed.
- **BNKR → CLAUDE:** Standing by for "go" on TGN deposit.
