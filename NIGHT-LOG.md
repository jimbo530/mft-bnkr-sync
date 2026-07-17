# OVERNIGHT LOG — 2026-07-16 → 07-17 (Coordinator; founder asleep ~7h)

## #1 BLOCKER — BNKR cannot deploy contracts (creation-tx wall)
BNKR's send-transaction can't send a contract-CREATION tx (empty `to`); it defaults to
`to: 0x0`, which deploys NOTHING (tx succeeds, contractAddress=null). This blocks the ENTIRE
queue — song booth, RH bridge, character factory. BNKR understands the bug but is stuck.
- **22:34:** asked BNKR to report its real deploy tooling (a create-contract action? can send-tx
  omit `to`?). Awaiting reply — next check 22:50.
- **If BNKR truly can't deploy arbitrary bytecode → FOUNDER DECISION (morning):** fallback = agent
  wallet `0xE2a4` deploys (works, FORFEITS BNKR builder points) or a Bankr CLI / x402 path.

## Packages READY in staging — I reviewed + gated each; ALL HELD pending the deploy-fix
- **song-revenue-splitter/** — song booth (TOP priority). Ready earlier. HELD.
- **staging/rh-national-bridge/** (`d132a28`) — 7 national tokens → Robinhood Chain. 1:1 port of the
  live bridge; twins grounded live off the Base node; bytecode proven 1:1; `to=null` + full wiring. Gated. HELD.
- **staging/gamified-nfts/character-nft/** (`d38e875`) — TasernCharacters factory (text-RPG mint).
  34/34 local tests, ~2.3M gas deploy / 1.2M mint, `to=null`, admin `0xE2a4`, fleet-wide one-way renounce.
  Agent's own HOLD banner (chain decision). Gated. HELD.

## Big inventory finding (nft-paths)
Stats engine + registry are **already LIVE**: **209 character NFTs on-chain** (27 Base + 182 Polygon,
incl. Kardov's Gate + all legacy POL). "Call in your existing character" = a wallet scan, ZERO new infra.
New characters just need the factory above. Registry is Supabase-first (no game redeploy).

## Rewards-into-NFT — GROUNDED design correction
Stats move ONLY from **registered LP-pair tokens at the character's address** — a raw ERC20 does
nothing. So prize-into-NFT = **add LP on a registered pair, send the LP to the character address**
(an LP-zap rail, powerUp-style — the next package). Cash prizes = live **PrizePool.claim() → wallet**.

## Useful ref
RH RPC = `https://rpc.mainnet.chain.robinhood.com` (chain 4663) — for my on-chain verification.

## DECISIONS / FLAGS for founder (morning)
1. **Deploy fallback** if BNKR can't create-contract — builder points vs unblocking. Biggest.
2. **Character NFTs + turn-credits chain** — Base vs RH. Agent's grounded lean: **Base** (engine reads
   only Base+Polygon LP pairs; an RH character reads all-1 stats until an RH pair registry exists).
3. **Turn tracking venue** — BNKR-side ledger vs a small on-chain credits contract. Turn credits ($1=50) still to build.
4. **Mint access** — factory ships allowlist-only (`setOpenMint(true)` later, no redeploy). When to open?
5. **PR25 on the RH bridge?** Left off per "7 nations"; add-only later.
6. **Memory to VERIFY + fix:** `feedback_renounce_capable_always.md` says the `0xD79360` lock vault
   "lacks the renounce selector" — rh-bridge agent found `escapeHatchRenounced()` exists on-chain
   (renounce-capable, not renounced). I'll verify, then correct.
7. **Renounce timing:** renounce the character-factory hatch BEFORE real prize value flows into
   characters (pre-renounce, build admin can recover from children — fine for test, a rug surface after).

## Invariants held
Browser open (never closed), jukebox playing (10), nothing deployed / seeded / locked,
TASKS-FOR-BNKR.md untouched (no promotion while the deploy path is blocked).
