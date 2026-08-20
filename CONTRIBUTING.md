# Contributing

Thanks for looking. This repo is the coordination hub and public reference for the Meme for Trees ecosystem. A few house rules keep it trustworthy.

## Ground rules

- **Ground every claim.** Anything factual (an address, a fee split, a status) must be backed by a file in this repo or an on-chain read. If it isn't verified, mark it clearly as planned / recorded-only.
- **No return promises.** No "invest", no APY talk. Deposit tokens are **1:1 receipts**, not stablecoins. Describe mechanics, not upside.
- **Renounce-capable, always.** Any contract that can hold funds ships with a one-way lock (`renounceAdminWithdraw()` or equivalent) and is locked at ship — no exit door, no dev-wallet drain.
- **Don't move BNKR's read-paths.** The deployment agent reads specific paths (`songs/`, `skills/`, `deployed/`, the deploy-ready package folders). Add and improve freely, but don't relocate those without updating the agent.

## Deploy-ready packages

Contracts land here as complete packages before they ship:

- `SourceContract.sol`
- `creation-bytecode.txt`
- `constructor-args.txt`
- `FOR-BNKR.txt` — plain-English deploy steps

The deployment agent deploys them and records addresses + ABIs in `deployed/`.

## Reporting issues

Open an issue with what you observed, the file or address involved, and how to reproduce (a call, a tx, or a doc reference). Grounded reports get fixed fastest.
