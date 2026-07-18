# Verify Booth — universal contract-verification skill

**Status:** SPEC — build the scaffold now, go live after our own 160-contract sweep proves the tool.

## What it does
A user hands BNKR a contract address + pays **0.01 $BNKR** → BNKR source-verifies it on the block explorer (Basescan / any Etherscan-V2 chain) → replies with the verified link. A paid, one-tap "get my contract verified" service.

## Why it's real (the trick)
Tons of contracts are verified on **Sourcify** but still show **"unverified" on Basescan** — because Hardhat-3 / Foundry + `viaIR` produce build-info source paths that don't match the deployed metadata hash, so Basescan rejects the standard build files with *"deployment bytecode does NOT match."* Our tool bridges it: **pull Sourcify's EXACT `stdJsonInput` (v2 API) → POST to Etherscan-V2 `verifysourcecode` with `chainid` in the URL.** One shot. (This is exactly how I cracked our own vault impl `0x3bb5f84c`.)

## Flow (mirror the song booth)
1. **User → BNKR:** "verify `0x<address>`" (+ optional chainid, default Base 8453) and sends **0.01 $BNKR** to the BNKR wallet `0xd7dfc7fe6c2b582b142dbc23ad172f735106b598`.
2. **BNKR confirms** the 0.01 $BNKR payment landed on-chain (never run before payment confirmed — customer pays, we never subsidize).
3. **BNKR runs** `verify/sourcify-to-basescan.cjs <address> [ctorArgsHexNo0x]` (the proven tool already in this repo).
4. **BNKR replies** with the outcome:
   - ✅ verified → the `basescan.org/address/<addr>#code` link
   - ⚠️ not on Sourcify → "we can only bridge Sourcify-verified contracts; get it on Sourcify first (free)"
   - ⚠️ needs constructor args → ask the user for the ABI-encoded args, then rerun with arg 2.

## Fee model
- **0.01 $BNKR → BNKR wallet.** Customer-pays-cost; never subsidize.
- A cut of accrued fees routes to **trees** via the charity flow.
- The value is **$BNKR volume + builder points + showcase**, not the per-use fee.

## Honest limits (bake into the copy)
- Works for contracts **already on Sourcify** (we bridge Sourcify → the explorer). NOT "verify from scratch" — that needs the source.
- **Constructor-args** contracts: the tool needs the ABI-encoded args as arg 2 (read public immutables, the deploy record, or ask the user).
- **API key:** a public service must NOT run on the founder's single free Basescan key (rate limits / terms). Use the **user's own** free Etherscan key per request (prompt for it — it's free at etherscan.io/apis), or put the booth on a paid plan.

## Prove-first
We're mid-sweep on our own 160 unverified contracts with this exact tool (`verify/verify-sweep-runner.cjs`). Build the skill scaffold now; flip it live once the sweep confirms the tool holds up at volume.
