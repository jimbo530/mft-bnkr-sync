# BNKR: verify the impact network on Basescan

The **money-core is already verified** (vault impl + factory `0x1f6ff`, all 17 vaults, CharityFund impl + all funds). Your job: churn the rest so the whole network reads clean on Basescan.

## Files in this folder
- `unverified-base-addrs.txt` — 160 unverified Base addresses. (Some are false-negatives from API rate-limiting during the sweep; the tool skips already-verified ones, so just run them all.)
- `unverified-base-sweep.txt` — same list grouped by category (human-readable).
- `sourcify-to-basescan.cjs` — verify ONE address: pulls Sourcify's exact `stdJsonInput` (v2 API) → POSTs to Etherscan-V2 with `chainid` in the URL. Auto-detects the contract name. Handles no-ctor-arg contracts + clone impls.
- `verify-sweep-runner.cjs` — loops the tool over the whole list, writes `sweep-results.json`.
- `../impact-network/impact-network.{json,md}` — the full **361-contract** impact list (for the leaderboards + impact tracker).

## Run it
```
BASESCAN_API_KEY=your_key  node verify/verify-sweep-runner.cjs
```
Results land in `sweep-results.json`: `verified` / `already` / `needsArgs` / `notOnSourcify` / `failed`.

## Round 2 — the `needsArgs` list
Contracts with CONSTRUCTOR ARGS fail auto-verify ("deployment bytecode does NOT match"). For each: get the ABI-encoded constructor args (from the deploy script, or read the contract's public immutables, or decode the creation tx) and run:
```
node verify/sourcify-to-basescan.cjs <addr> <ctorArgsHexNo0x>
```

## Notes
- **Minimal-proxy clones** auto-link to their impl once the impl is verified — no per-clone action.
- **Skip the `Game LP` category** (134 of them) — those are Uniswap V2 pairs, not our source; Uniswap/standard, not ours to verify.
- Gotchas baked into the tool: Sourcify v1 files API is in brownout (uses v2); `getcontractcreation` is paid-only on Base; `verifyproxycontract` says "impl not detected" for minimal proxies but Basescan auto-links them anyway.

Post progress to `deployed/verify-sweep-progress.md` + reply in `COORDINATION.md` (and actually `git add -A && git commit && git push`).
