# Seize the Seas — DUNGEON + CITY-BUILDING inventory

Grounded 2026-07-17. Every LIVE claim below was re-verified on-chain THIS pass
(local Base node block 48,743,640 + mainnet.base.org where the local node lagged) —
re-run `verify-onchain.cjs` + `probe-artifact-provenance.cjs` in this folder to reproduce.
Chain = **Base 8453** for everything listed. Admin/curator everywhere = agent
`0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`.

Deploy target for new contracts: **DeployerFactory `0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D`**
(verified live via mainnet.base.org — 2,475 bytes runtime; the LOCAL node showed no code
only because it lagged ~3.1h behind head; the factory deployed the same morning).

---

## 1. DUNGEON system

### LIVE (address-verified this pass)

| Piece | Address | Verified state |
|---|---|---|
| PrizePool engine (canonical `mftusd-build/PrizePool.sol`) | 15 instances below | add-only admin, no drain; only exit = `claim()` → `ownerOf` |
| cbBTC pools (ROGUE line): Mayor / Lord / PettyKing / HighKing / Emperor | `0xB10fbbCB67d68d1f43E566089FFa0f36Bd057193` / `0x4cC809378135F9501e37532dFDF3df6aED2B3342` / `0x1D6dA6b28a62A45588411eEE66C94AC951A461D2` / `0x2983E3d4250d01ba05013F1E9995Cd457D7aBa65` / `0xF3dA6a1D7d1a57F4E4782213D831646C7E45d6B0` | Mayor: 226 claims paid, 0.0000314 cbBTC left; Lord→Emperor: balance 0 |
| GOLD pools (CIVIC line): Mayor / Lord / PettyKing / HighKing / Emperor | `0xC76A9F461Be6253BD8676e0db41A6b2E03e318F8` / `0x684698ae06Bba12bEf5e7684d8ed466AFD841F5A` / `0x6C3208D0a637eB2a993AA60bF9838b39D218F2e7` / `0x784D25403f0677A4EB29dD4d8e2887c6Bf9341C3` / `0x5DFfBF9B20b7A1d7155d54C8c750BF60d4CdE5B4` | Mayor: 100 claims paid, 18,301.6 GOLD left; Lord→Emperor: 50,000 GOLD each, 0 claims |
| WETH pools: Mayor / Lord / PettyKing / HighKing / Emperor | `0x0590AE358c9DdDBbe36CCf5D9F9FBe69290980f2` / `0x98750a778E8A65C5Deac9BA26ceDCf8bb8c9A66B` / `0x2C7737eaAa70e031EDd04d3712525368d93C0a9A` / `0xf17792CACE3FD578a7b2d75e19afeA301f6c8D7f` / `0x15B5F48d378D1F73fd151a6eD3B97508C818498a` | **ALL 5 balance 0 — deployed but UNFILLED** (matches the standing founder ask to fill them) |
| Achievement registries ON those pools | (per-pool storage) | cbBTC line: job/ship/guard ids registered (checked 101+1001 Mayor, 103+1003 Lord = true). GOLD line: full mirror (101/1001 Mayor; 103/203/703/1003 Lord; 106/706/1006 Emperor = true). WETH line: **guard ladder only** (1001/1002 Mayor + 1003 Lord = true; 101/102/701 Mayor = false) |
| CourtEndowment ×5 (the cbBTC "taxing system") | Mayor `0x0212F678690eFBe3C2F92c7F57FC0db3F9cf5820`, Lord `0x34bd4d8005b0530f0c52721D29FDcA928dEAbC2a`, PettyKing `0x9013B3ab0cBf8945b251EEb27dFb42C2bA0733e2`, HighKing `0x221E1695033167c838c8fBF57cb683B46dA6DB12`, Emperor `0x7728D2963a0db55D4FC9373D8f48b453666E10Ac` | all code-live and correctly wired to their cbBTC pools — but **principal = 0 USDC on all 5** (the tax engine has never been funded; the cbBTC that WAS paid out arrived by direct funding, not harvests) |
| LootPoolV2 water fight-drip ("Water Prize - Bilge") | `0x8Cee28FB4F6b839138972D3FEab4D3e53fF7f8c7` | code-live, 1.0 WATER balance; 1% fractional drip; feeder PRIZEw `0x0Fb72ee5319172E38935Efd029433F8b7A667C02` planted $1 |
| ONCHAIN condition adapters | ShiftCountCondition `0x9c483200361465A6F9AE72458f922D0fB7a76967`, TreeWaterCondition `0xca760765D8566Ac69700d6fa823a68aBaE90a2F9` | per `_archive/prizepool-deployment.json` (pluggable eligibility for future dungeon milestones) |

Game-layer dungeon content that EXISTS in code (MfT-Launch, much of it in the ~495
uncommitted files of the combat/beast waves — **built, unpushed**):
- `game/lib/dungeons.js` — 6 dungeon templates (Harbor Cellars, Tortuga Bilge, Saltmarsh
  Sunkenhold, Bonewater Crypt, Kraken Trench, Skull Reef Vault), per-pawn cooldowns,
  `jobRerouteTarget()` (grind = job yield reroutes into the dungeon's pool), claim-intent shape.
- `game/lib/goblin-cave.js` — foot-reachable PVE dungeon (weekly cooldown, real hours).
- `game/seas/battle-grid/bestiary-sea.js` + `bestiary-dungeon.js` — 208-monster roster
  + `monster-bridge.js`, `area-encounters.js`, battle-grid engine.
- `game/seas/monster-achievements.js` — derived kill-count ladders for all 208 monsters
  (bronze→COPPER / silver→SILVER / gold→GOLD coins + GEM meta ladder; coin + gem token
  addresses grounded in it).
- Ops: `mftusd-build/seas-ladder/seas-watcher.cjs` (ADMIN_ATTESTED attestor),
  `guard-ladder-keeper.cjs` (local scheduled task), `achievement-claim-fire.cjs`.

### GATED / IDLE
- **CourtEndowments unfunded** (principal 0 ×5) — engine exists, tax never switched on. Founder decision.
- **WETH pools empty + no filler** — the WETH CourtEndowment variant was never deployed (packaged below).
- **Dungeon UI**: founder note stands — jobs/dungeons not surfaced in the game UI yet.
- **Cooldowns are dev-scaled** in `dungeons.js` (`COOLDOWN_MS_PER_HOUR = 60_000` — 1 "hour" = 60s). Must be raised to real hours before any on-chain payout wiring.
- **Seas combat/dungeon waves uncommitted** — MfT-Launch working tree has ~495 modified/untracked files (the built-unpushed beast push).

### MISSING (does not exist anywhere)
- **Dungeon COIN prize pools** — `dungeons.js` pays from copper/silver/gold pools (poolId per dungeon); no such pools deployed. → **deploy-ready package in `dungeon-coin-pools/`** (3× canonical PrizePool: COPPER/SILVER/GOLD; bytecode proven byte-identical to the 15 live pools via the live deploy tx).
- **Dungeon-clear achievements** — nothing registered for dungeons on any pool (registration is add-only admin config AFTER the coin pools exist).
- **Keeper reroute** — nothing reads `jobRerouteTarget(pawnId)` and routes harvested yield into a dungeon pool (`fund()`); the self-feeding loop is designed but unbuilt.
- **Watcher dungeon attestation** — seas-watcher has no dungeon-clear event source yet (needs the backend signer flow in `dungeons.js` finishRun → attest → claim).
- **Monster kill-ladder registration** — 208 ladders derived in code, none registered on-chain (add-only, register as content ships; the founder's Emperor-tier "slay a monster" bounty rides this).
- **WETH CourtEndowments** — → **deploy-ready package in `weth-court-endowments/`** (5×, same bytecode as the live cbBTC endowments, WETH + fee-500 route grounded on-chain, tier pool wired at construction).
- Note: the redundant `MfT-Launch/contracts/PrizePool.sol` dupe flagged in memory is **already gone** (only a stale `artifacts/…/PrizePool.dbg.json` remains) — nothing to retire.

---

## 2. CITY-BUILDING system

### LIVE (address-verified this pass)

| Piece | Address | Verified state |
|---|---|---|
| **StructureFactory** (build keystone: pay GOLD → structure NFT + WaterV2 endowment; reclaimable pre-`seal()`) | `0x98D4306095f67035780DafB7D5897B4fE04EA647` | code-live; **kindCount = 0, structureCount = 0**, paused = false, owner + gameWallet = `0xE2a4…aC10`. Engine deployed, catalog EMPTY, nothing built yet |
| COPPER wage-water (shared 50/50 wage engine; also the treasury vault for light kinds) | `0x0749c5107091F153a9f3950FC63d5B96Df04528B` | code-live |
| GOLD water (civic treasury vault for warehouse/mansion kinds) | `0x24eb9Cf77d920207CC07584B5CD9BFB0F5a0F7C7` | code-live |
| Prize coins the dungeon/kill ladders pay | COPPER `0x0197896c617f20d61E73E06eC8b2A95eef176bee`, SILVER `0x36cF0ceDEee07b14C496f77C61d010268c31E0e9`, GOLD `0x2065d87b3a1FACc9A4fE037D7a58bC069F597004` | all code-live |
| Building materials (per `game/seas/commodity-tokens.csv`, spot-checked rows) | BRICK `0x54652eA21113909a4792deF5607d8bD4be0B7aB4`, SHALE `0x6171B2039199786750b24021c04400FDb8c07793`, SANDSTONE `0x374aaB191aa6FEAEE55BDb1Bc0CC9FFcD7a9fE6f`, GRANITE `0x3c2c14Aa50A67C58847F4772b3e6caA94b88aA73`, MARBLE `0xdF8B0141b39a1eD27Cfd442497C36978017F42c5` (+ LOGS/LUMBER/ores/ingots in the CSV) | listed with prices in the sheet (SHALE 1g … MARBLE 12g) |
| Boat ownership tokens (6 hulls, `game/lib/ship-catalog.js` tokenAddr filled) | rowboat `0xBC1E8515…` … man-o-war `0x9Cb68c46…` | catalog wired |

Game-layer city-building code that EXISTS:
- `game/seas/structure-kinds.js` — the FULL 15-kind catalog (logging-camp, forage-bunk,
  fishing-dock, lumber-mill, farm, vineyard, mine, stall, warehouse, workshop, brickworks,
  kitchen, smelter, smithy, mansion) with goldCosts, material recipe (gold + half-value
  materials), terrain gating, LP-slot capacity model, `addKind()` arg generator.
- `game/seas/CAMP-TO-TOWN-MODEL.md` — the settlement model doc.
- `game/lib/settlements.js` — tiers/bunk caps/NOBLE_RANKS/STAT_RATE (the runtime registry).

### GATED (built + verified, deliberately not live)
- **ManufacturingPool** (`mftusd-build/ManufacturingPool.sol`, artifact `ManufacturingPool.json`,
  8,526-byte creation code) — the layer-(b) owner-withdrawable business/production line.
  Built + FULLY fork-verified (A–L pass), **never deployed — explicit founder gate**
  ("deploy when wired + founder-go"). → **HOLD package staged in `manufacturing-pool/`.**
- **addKind registrations (0 of 15)** — deliberately held: producer kinds need per-good
  RESOURCE-water vaults that don't exist (below); the 8 treasury-vault kinds (stall,
  warehouse, workshop, brickworks, kitchen, smelter, smithy, mansion) point at the LIVE
  coin-waters and are **wireable today** the moment the founder says go.

### MISSING
- **Per-good RESOURCE-water WaterV2 vaults** — `structure-kinds.js` RESOURCE_WATER:
  logs/lumber/wheat/corn/grape/berry/ore are ALL null (FISH `0x37be8d21…` + FLOUR `0x0a2B3b81…`
  exist but pay GOLD, not the good). Blocked on an OPEN DESIGN point: a resource-water's
  payout good must be BUYABLE from harvest yield, and LOGS/LUMBER/WHEAT have no two-sided
  market yet (sell walls only). **Not packaged — needs founder input** (see PLAN).
- **Build UI/flow** (`build.js` gates: GOLD exit-liquidity probe, town gate, material burn) — designed in structure-kinds.js comments, not shipped.
- **TownRegistry** — game-layer derivation from `StructureBuilt(loc)` events (no new contract needed) — not built.
- **Caravan/haul + auto-transfer automation** — design recorded, unbuilt.
- Minor sync bug: `structure-kinds.js` STONE_GOLD_PRICE still has `sandstone: null, granite: null` ("FUTURE token") — both tokens are in fact LIVE + priced (7g/10g) in `commodity-tokens.csv`. One-line game-layer fix.

---

## 3. Counts

| | LIVE | GATED/IDLE | MISSING |
|---|---|---|---|
| DUNGEON | 15 tier pools + 5 endowments + LootPoolV2 + feeder + 2 condition adapters + watcher/keeper ops + full game-layer content (6 dungeons, 208 monsters, ladders) | endowments unfunded ×5; WETH pools empty; UI off; dev cooldowns; waves uncommitted | 3 coin pools (**packaged**), 5 WETH endowments (**packaged**), dungeon achievements registration, keeper reroute, watcher dungeon-attest |
| CITY-BUILDING | StructureFactory + 2 treasury/wage waters + all material/coin/boat tokens + full kind catalog in code | ManufacturingPool (**HOLD package staged**), addKind ×15 held (8 wireable now) | 7 per-good resource-waters (founder input), build UI, TownRegistry, caravans |
