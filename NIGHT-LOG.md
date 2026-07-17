# OVERNIGHT LOG — 2026-07-16 → 07-17 (Coordinator; founder asleep ~7h)

## #1 BLOCKER — BNKR cannot deploy contracts (creation-tx wall)
BNKR's send-transaction can't send a contract-CREATION tx (empty `to`); it keeps
defaulting to `to: 0x0`, which deploys NOTHING (tx succeeds, contractAddress=null).
This blocks the ENTIRE deploy queue — song-booth SongRevenueSplitter, RH bridge,
NFTs. BNKR confirmed it understands the bug but is stuck on the whole list.
- **22:34 action:** asked BNKR to report its real deploy tooling — does it have a
  create-contract/deploy action, or can send-tx omit `to` entirely? Awaiting reply (next check 22:50).
- **If BNKR genuinely can't deploy arbitrary bytecode → FOUNDER DECISION (morning):**
  fallback = agent wallet `0xE2a4` deploys (works, but FORFEITS BNKR builder points),
  or a Bankr CLI / x402 deploy path. Nothing deploys until this is resolved.

## Packages READY in staging (I reviewed + gated them; HELD pending the deploy-fix)
- **staging/rh-national-bridge/** (`d132a28`) — 7 national tokens → Robinhood Chain. 1:1 port
  of the live Tasern bridge; twins grounded live off the Base node; bytecode proven 1:1; gas
  far under cap; `to=null` rule + full relayer/owner wiring in FOR-BNKR.txt. Reviewed, sound. HELD.
- **song-revenue-splitter/** — song booth (TOP priority). Ready earlier. HELD (same blocker).

## Still running
- **nft-paths** builder — gamified-NFT inventory + character-NFT package (briefed with the full TEXT-RPG flow).

## Useful ref
- RH RPC = `https://rpc.mainnet.chain.robinhood.com` (chain 4663) — for my on-chain verification.

## DECISIONS / FLAGS for founder (morning)
1. **Deploy fallback** if BNKR truly can't create-contract — points vs unblocking. Biggest one.
2. **PR25 on the RH bridge?** Left off per the "7 nations" spec; add-only later (addToken+deployTwin).
3. **Character NFTs + turn-credits chain** — Base vs RH; and **turn tracking** — on-chain vs BNKR-side.
4. **Memory to VERIFY + fix:** `feedback_renounce_capable_always.md` says the `0xD79360` lock vault
   "lacks the renounce selector" — the rh-bridge agent found `escapeHatchRenounced()` DOES exist
   on-chain (returns false = renounce-capable, not renounced). I'll verify myself, then correct it.

## Invariants held
Browser open (never closed), jukebox playing (10 procs), nothing deployed / seeded / locked,
TASKS-FOR-BNKR.md untouched (no premature promotion while the deploy path is blocked).
