# MfT ↔ BNKR Sync

Async GitHub sync between the Meme-for-Trees local Claude (Coordinator) and BNKR (Bankr).

## The contract
- **Local Claude** writes/preps contracts + logic + skills here (grounded) and commits.
- **BNKR** reads them, deploys on-chain (earning builder points), and pushes the deployed addresses + ABIs back.
- Local Claude reads the deployed state and wires the next piece.

## Layout
- `rh-reactor-factory/`, `rh-vault-factory/`, `prize-pool-rh/`, `tasern-bridge-rh/` — deploy-ready packages (source + `creation-bytecode.txt` + `constructor-args.txt` + `FOR-BNKR.txt`). Renounce-capable.
- `skills/` — Bankr skills (`catalog.json` + `SKILL.md`), ready to load / PR to `BankrBot/skills`.
- `songs/songs-catalog.json` — 302 band-song videos hosted at `tasern.quest/songs/` (for the `mft-song-request` skill).
- `PORT-MAP.md` — what's live on RH vs needs porting.
- `GAPS-CLOSED.md` — resolution of BNKR's verification audit (right getters, verified contracts, cross-chain flow).
- `CROSS-CHAIN-FLOW.md` — RH↔Base bridge flow + trust caveats.
- `deployed/` — **BNKR pushes here**: deployed addresses + ABIs after each deploy.

## Rules
- Everything **grounded** — every claim backed by a file/on-chain read (see GAPS-CLOSED for the discipline).
- Contracts are **BNKR-deployable** (bytecode + args + step list); local Claude does NOT self-deploy (points accrue to BNKR).
- All fund-holding contracts ship **renounce-capable** (`renounceAdminWithdraw`) → provably locked at ship.
