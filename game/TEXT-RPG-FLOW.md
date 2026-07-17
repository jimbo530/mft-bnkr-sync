# TEXT RPG — flow, revenue, and BNKR signals (founder spec 2026-07-16)

The play-by-text RPG on X. Roles (see COORDINATION.md): **GPT = story + art**,
**Claude = stats + coordination**, **BNKR = payment, tracking, prize payouts**.

**SINGLE-PLAYER (founder 2026-07-17):** the RPG is one-player — you vs the DM / story, no PvP. So
**pay-to-win is a FEATURE, not a fairness problem** — buying power is fine when no one else is racing you.

## 1. Character start — new OR returning
- **Bring ANY NFT, or mint new.** At start the player either gets a **new character NFT** (mint) OR brings
  **any NFT they own** — not just a pre-registered character. For a brought NFT, a **vault-spinner skill**
  (they call @bankrbot) deploys a **stat-vault** for it via the DeployerFactory + links it to the NFT (registry
  entry: vault = that NFT's stats, Supabase-first); the stats-engine then reads that vault's LPs as the NFT's
  stats. (Legacy Tasern/POL character NFTs that ARE their own contract need no vault — the engine reads them
  directly, Kardov's-Gate style.) The player provides the **NFT's CA** — first time = **register** (spin the
  vault + registry entry); returning = **play again** (load the existing vault, no re-spin).
- **New character (mint) path (founder 2026-07-17):** player writes a **character description** → **GPT** makes
  the **art + story** → hands it to **us (Claude)** → we hand it to **BNKR**, which **mints the NFT (with the art)
  and posts the debut on X.** (BNKR posts the NEW-character *debut*; the ongoing *story* posts stay ours per §3's
  don't-reply signal.)
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

## 3b. Pay-to-win — BUY stat boosts via @bankrbot (founder 2026-07-17)
Single-player → selling power is fine. Players **buy water / endowment tokens through @bankrbot** to boost stats:
- Player tags **@bankrbot** ("boost my \<character\>'s strength" / "buy a water for #X") → BNKR **debits their
  Bankr wallet** (same charge rail as the song booth) → acquires the water/endowment token → **LP-zaps it into
  the character's address** → stats jump (the stats-engine reads the new LP).
- This is the PAID version of "rewards = LP into the NFT" (§3): winning *earns* the LP, paying *buys* it — same rail.
- Bonus: gives the **water + CourtEndowment tokens a real demand source** (the dungeon/city inventory found them
  deployed-but-unfunded — players buying stat boosts are the buyers).
- Reuses everything: the LP-zap rail (reward path) + the @bankrbot-charge loop (song booth).

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
4. GPT hand-off: **description → GPT (art + story) → us → BNKR mints the NFT + posts the debut** on X.
5. **Vault-spinner skill** — player gives an NFT's **CA** → @bankrbot deploys a **stat-vault** via the factory +
   registers it (vault = that NFT's stats); returning players just load it. Makes ANY NFT playable; deploys
   through the deploy-any-contract skill.

## Open decisions for founder (flag in morning)
- **Which chain** the character NFTs + turn-credits live on — **Base vs Robinhood Chain**.
- **Turn tracking on-chain (contract) vs BNKR-side** (COORDINATION says BNKR = tracking).

Ties: `game/PAID-SONG-BOOTH.md` (same payment/post/revenue pattern), `game/stats-engine/`,
`game/DM-PROMPT.md`, `reference_prize_pool_system`.
