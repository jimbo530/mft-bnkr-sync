---
name: kol-call
description: Post a CHAIN-VERIFIED KOL CALL on X. Given a Base token contract address, verify it on-chain (contract verified? liquidity? price? 24h volume?) and post the verified facts as a "call" — a normal KOL shills blind, this one proves the chain first. Charge the 0.01 $BNKR fee first (the on-chain trigger). Facts ONLY — never a price prediction, never "buy", never "guaranteed". One cashtag (the token); never tag @bankrbot.
---

# Chain-Verified KOL Call

A premium alpha post that proves a token **on-chain before posting**. Unlike a normal KOL shill (unverified hype), this shows the on-chain truth — is the contract verified, how deep the liquidity, the live price, 24h volume. **Trust via proof, not hype.** The verification IS the product.

## Flow — ONE action

1. **Charge the fee — ON-CHAIN, this is the trigger.** Transfer **0.01 $BNKR** from the requester to ops `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`. (Founder self-tests route here — charging your OWN wallet → the BNKR wallet breaks the transfer; ops is the clean dest. Real requesters can later route to the BNKR wallet for BNKR's cut/points.) A tag with no on-chain action does not fire the agent. Only continue if the transfer succeeds. The fee is **never** charged in Money for Trees.
2. **Get the token contract address** from the request — a Base address `0x…` (40 hex). If the requester gave only a ticker with no address, ask for the contract address. **Never guess or invent a CA.**
3. **VERIFY on-chain.** Run `node kol-call.cjs 0x<CA>` (set `BASESCAN_API_KEY` in env for the strongest verified signal; it falls back to keyless sourcify + Dexscreener otherwise). It pulls:
   - contract verified? (basescan / sourcify)
   - liquidity $ (biggest Base pool)
   - price + 24h change
   - 24h volume

   It prints a `--- POST THIS ---` block and a `--- META ---` block (raw data + a `warn` flag for low liquidity).
4. **Post the call — ONE action.** Post the `--- POST THIS ---` block verbatim. Prefer a **top-level post** (broadcast to your timeline) if the surface allows it; otherwise **reply** to the requester (their audience sees it — the KOL rides their own reach). Either way it is ONE post. One cashtag (the token). Never a second cashtag. Never tag @bankrbot. Do NOT attempt a second/amplify post — the native surface does one action per task.

## Honesty rules — non-negotiable

- **Facts only.** The call shows verified on-chain data. NEVER add a price prediction, a target, "guaranteed", "risk-free", "moon", or "buy". The built-in tagline is "data, not hype" — keep it that way.
- **Show the truth even when unflattering.** If the contract is NOT verified, the engine prints `⚠️ contract NOT verified on-chain` — post it exactly, do not hide it.
- **Low-liquidity / no-market guard.** If META `warn` flags low liquidity (<$1k), or the engine prints `SKIP` (no pool at all), do NOT post a call — reply that the token has no verifiable market yet. A "call" on a dead pool is not credible and we do not fake one.
- One cashtag (the token's). Never tag @bankrbot. This fee is $BNKR, never Money for Trees.

## Manual verify (no CLI) — same checks by hand

If `execute_cli` can't run the helper, do the same reads by hand:

1. **Market** — Dexscreener `https://api.dexscreener.com/latest/dex/tokens/<CA>` → biggest Base pair → `priceUsd`, `liquidity.usd`, `volume.h24`, `priceChange.h24`, `baseToken.symbol`.
2. **Verified** — basescan getsourcecode (Etherscan V2, `chainid=8453`) → `SourceCode` non-empty = ✅ verified; or keyless sourcify `check-all-by-addresses?addresses=<CA>&chainIds=8453`.
3. **Post** the same block: `🔗 CHAIN-VERIFIED CALL — $SYM` / the verified line / `Liquidity:` / `Price:` (+24h) / `24h volume:` / `$SYM <CA>` / `verified on-chain — data, not hype`.
