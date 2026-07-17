# Seize the Seas — DUNGEON + CITY-BUILDING: the ordered plan

Companion to INVENTORY.md (grounded 2026-07-17). Rule of the whole plan: **deploying
empty engines is free and locks nothing; FUNDING anything here is one-way** (PrizePool
has no withdraw, CourtEndowment principal is forever, seal() is forever). So the order
is always: deploy empty → wire/register (add-only config) → founder paces the funding.

Chain: **Base 8453** throughout — every dependency (GOLD/Money/USDC/Aave/coin-waters/
watcher) is live on Base. An RH twin is a separate future port, not part of this plan.

---

## Phase A — BNKR deploys (via DeployerFactory `0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D`, ready now)

**A1. Dungeon coin pools — 3 txs.** Package `dungeon-coin-pools/` (PrizePool ×3:
COPPER, SILVER, GOLD; bytecode proven identical to the 15 live pools). Zero value at
risk — pools deploy empty. Unblocks every later dungeon step.

**A2. WETH CourtEndowments — 5 txs.** Package `weth-court-endowments/` (the founder's
standing "fill the WETH pools with the same taxing system" ask; tier pool wired at
construction, so no post-deploy wiring exists). Inert until the founder funds them.

Both packages: normal txs, `to = factory`, `data =` the calldata file, value 0, one at
a time, each far under the Base per-tx gas cap (no staging needed). BNKR pushes the
deployed addresses to `deployed/` (file names in each FOR-BNKR.txt).

## Phase B — Coordinator wiring (admin key `0xE2a4…aC10`, add-only config, after A1)

**B1. Register the 6 dungeon-clear achievements** on the new coin pools
(id = dungeon id; repeatable ADMIN_ATTESTED, BPS_OF_POOL 100 = 1%; per
`game/lib/dungeons.js` TIER_COINS: dungeons 1-2 → COPPER+SILVER, 3-4 → SILVER+GOLD,
5-6 → GOLD). Same pattern as `register-guard-ladder.cjs`.

**B2. Point the game module at the pools** — `dungeons.js` poolId → deployed addresses,
and raise `COOLDOWN_MS_PER_HOUR` to real hours (3,600,000) before any payout wiring.

**B3. Teach the watcher dungeon clears** — extend `seas-ladder/seas-watcher.cjs` to
attest cooldown-respecting clears (the backend-signer flow `dungeons.js` already
shapes with `finishRun()`), then `claim()` fires via the existing keeper pattern.

**B4. Commit/push the Seas combat + dungeon game-layer waves** — the content the pools
pay for is sitting in ~495 uncommitted MfT-Launch files. Nothing on-chain depends on
it, but players can't reach dungeons until it ships.

## Phase C — the self-feeding loop (build task, after B)

**C1. Keeper reroute** — implement the `jobRerouteTarget(pawnId)` consumer: while a pawn
grinds a dungeon, its harvested job yield routes to that dungeon pool's `fund()`.
This is the founder's designed feed; without it pools only drain.

**C2. Register monster kill-ladders as content ships** (208 derived ladders in
`monster-achievements.js`, add-only, batched; includes the founder's Emperor-tier
"slay a monster" compounding bounty). Pace: register alongside each content drop,
never all at once.

## Phase D — city-building ignition (founder-gated, cheap once decided)

**D1. addKind for the 8 TREASURY kinds** (stall, warehouse, workshop, brickworks,
kitchen, smelter, smithy, mansion) — wireable TODAY: their endowment vaults are the
LIVE coin-waters (COPPER `0x0749c5…`, GOLD `0x24eb9C…`). Owner-key txs on the live
StructureFactory `0x98D43060…`; `structure-kinds.js` already generates the exact args.
This opens building (and the mansion rank-sink) without solving the resource-water
question. Also fix the one-liner: sandstone/granite prices in `structure-kinds.js`
(tokens are live at 7g/10g in `commodity-tokens.csv`).

**D2. Per-good RESOURCE-waters** — blocked on decision F4 below. When decided: deploy
the per-good WaterV2 vaults, then addKind the 7 producer kinds (logging-camp,
forage-bunk, fishing-dock, lumber-mill, farm, vineyard, mine).

**D3. Un-gate ManufacturingPool** (HOLD package staged in `manufacturing-pool/`) —
founder-go + first-instance wiring (decision F5). Then player businesses deploy
per-instance via the factory (a natural Bankr skill: "open a business at hex N").

**D4. Build flow + TownRegistry** — `build.js` (GOLD exit-liquidity gate, town gate,
material haul/burn) + the game-layer town derivation from `StructureBuilt` events.
Build tasks, no contracts.

## Dependency graph (compressed)

```
A1 ──► B1 ──► B2/B3 ──► C1 ──► (dungeon loop LIVE)
A2 ──► F2 (fund?) ──► keepers on ──► WETH pools fill
B4 is parallel (content ship)     C2 rides content drops
D1 (now, founder says go) · F4 ──► D2 · F5 ──► D3 · D4 parallel
```

---

## Founder decisions needed (F#)

- **F1 — Seed the dungeon coin pools?** How much COPPER/SILVER/GOLD per pool, when.
  One-way once in (claims are the only exit). Coins are treasury-minted (~$0 external
  market today) so the real cost is game-economy pacing, not dollars. Related: confirm
  the 3-shared-coin-pool layout (packaged, per the recorded design "PrizePool instances
  funded in gold/silver/copper") vs one-pool-per-dungeon — more instances can always be
  added later; nothing in A1 forecloses it.
- **F2 — Fund the WETH endowments?** `tribute()` is permanent principal. Amount per tier,
  or skip endowments and direct-fund the WETH pools (also permanent), or leave empty.
- **F3 — What deeds pay WETH?** The WETH line currently carries ONLY the guard ladder
  (ids 1001-1003 verified). Wallet-scope/elf-area/regional-currency ideas are recorded
  but unregistered. Needed before the WETH line means anything to players.
- **F4 — Resource-water shape.** Producer kinds need per-good vaults, but LOGS/LUMBER/
  WHEAT have no two-sided buy market (the harvest can't buy the good yet). Options:
  (a) deploy them anyway — endowments grow, goods flow later when buy routes exist;
  (b) run producer output through keeper-side injection like today's mills until
  markets exist; (c) hold producers, open treasury kinds first (D1 works regardless).
- **F5 — ManufacturingPool go.** When do player businesses open, who gets the first
  lines, keeper + gameSigner wallets, inputSink (dead address vs game treasury).
- **F6 — Rogue-deed catalog (standing, low-urgency).** The cbBTC line's ROGUE_IDS set is
  still empty; cbBTC Mayor is nearly drained (226 claims, 0.0000314 left) — refill and/or
  add rogue deeds only by founder call (the line is lore-assigned to the dark side).

## Premature-lock watchlist (things this plan deliberately does NOT do)

- No funding/seeding of any pool or endowment (F1/F2 own that).
- No `seal()` of any structure, no `tribute()`, no water planting.
- No registration on the cbBTC (rogue) line — lore-assigned, founder-curated.
- ManufacturingPool stays HOLD until F5 — the package exists so the go is one tx away.
