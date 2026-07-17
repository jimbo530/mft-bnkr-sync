# TEXT RPG — flow, revenue, and BNKR signals (founder spec 2026-07-16)

The play-by-text RPG on X. Roles (see COORDINATION.md): **GPT = story + art**,
**Claude = stats + coordination**, **BNKR = payment, tracking, prize payouts**.

## 1. Character start — new OR returning
- **At game start the player identifies their NFT.** If they **already hold** an eligible character
  NFT (or a legacy TTRPG / POL NFT), they name it ("play with NFT #X") — that's their character and the
  stats-engine reads its LPs. This is how legacy players "call in" an existing character.
- **New players** write a **character prompt** (fantasy race + concept: dwarf / elf / goblin, etc.),
  handed to **GPT** for (1) character **art** and (2) **story start** (opening scene), then mint.
- Claude's **stats-engine** (`game/stats-engine/`) derives D20 stats from the NFT's **LP positions**.
  Reuse the engine on existing NFTs before minting new infra (Kardov's-Gate style).

## 2. Main story + posting (revenue)
- **WE write the main story** and **post it on X ourselves** — same mechanism as the song booth:
  we post the native content, so **we capture the X creator revenue** (founder: revenue hypothesis,
  "maybe" — treat as unproven upside, not a promise).
- The story posts are therefore **ours**, not BNKR's.

## 3. BNKR in the loop — two signals it needs
1. **"Don't-reply" signal on posts** — story posts are ours; BNKR must **not auto-reply** to them.
   BNKR only acts when explicitly invoked (a payment or a prize command) — same hand-off shape as the
   song-booth **Option B** (BNKR doesn't post; we do). Needs a clear convention/marker so BNKR skips them.
2. **"Pay-the-prize" command** — BNKR pays a game prize **on-chain** on command. Wire to the existing
   **Prize Pool system** (canonical `PrizePool.sol` + tier pools — see `reference_prize_pool_system`).
   Quest/turn resolves → pay-prize command → BNKR pays the winner from the right pool.
   - **Rewards path → NFTs (GROUNDED, nft-paths):** stats move ONLY from **registered LP-pair tokens
     held at the character's address** — a raw ERC20 transfer does nothing. So "prize into the NFT" =
     **add liquidity on a registered pair and send the LP to the character address** (an LP-zap rail,
     `powerUp`-style router — next package). Because stats come from those LPs, **winning grows the
     character** — reward == progression. Cash prizes keep using the live **PrizePool.claim() → wallet**.

## 4. Pricing — the game is PAID (hosting cost is real)
- Each post costs us **~0.01–0.02** (X posting / hosting).
- **$1 = 50 turns** (≈0.02/turn) — covers cost. Players **buy turns**.
- Turn credits: player pays (pay-anything, routed like the booth: → WETH → USDC → **mint Money**
  → …), gets 50 turns; each story post/reply **decrements one**. **BNKR tracks turns.**
- Payment **mints Money** on the way in → funds trees (same flywheel as the song booth). Mint, never buy.

## 5. Build order (pipeline)
1. Character-NFT mint + stats-engine read  ← nft-paths builder is on this now.
2. Turn-credit accounting ($1 / 50 turns) — BNKR-tracked, or a small contract. **Venue TBD.**
3. BNKR "don't-reply" convention + "pay-prize" wiring to the Prize Pool.
4. GPT hand-off: character prompt → art + story start.

## Open decisions for founder (flag in morning)
- **Which chain** the character NFTs + turn-credits live on — **Base vs Robinhood Chain**.
- **Turn tracking on-chain (contract) vs BNKR-side** (COORDINATION says BNKR = tracking).

Ties: `game/PAID-SONG-BOOTH.md` (same payment/post/revenue pattern), `game/stats-engine/`,
`game/DM-PROMPT.md`, `reference_prize_pool_system`.
