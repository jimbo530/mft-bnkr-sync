# PROJECT-GAP-AUDIT — MfT / Tasern

_Generated 2026-07-16. Every gap below is grounded against on-disk source read THIS session (byte sizes and load-bearing line numbers re-verified, not recalled)._

## 1. Landscape

Recon started from **58 raw gaps**; after dedup and two hard filters — **grounded** (backed by this-session tool output) AND **BNKR can actually produce a contract or skill** (not an ops transfer, not an unwritten spec) — **13 survive**. The top tier is **4 fully-staged, ready-to-land packages** living in `BNKR-ports/` (`prize-pool-rh`, `rh-reactor-factory`, `rh-vault-factory`, `tasern-bridge-rh`): each already ships `creation-bytecode.txt` + constructor args + ABI/artifact + `FOR-BNKR.txt`, so BNKR earns builder points immediately with **zero authoring**. **PrizePool ranks #1** — smallest deploy (6,399 bytes), no AMM/V4 dependency, no admin withdraw path (locked by design), and it is the exact contract a prior free agent botched to `0x0`, so landing it is the clean pipeline proof. The second tier is **un-renounced fund-holder redeploys** (MRB-BASE holding 4M MfT with its `escapeHatchRenounced()` selector confirmed ABSENT on-chain while the current source already carries the fix; plus PegCommunityVault, PowerLiquidityV2, PLManager, PrivateReactor) — all genuinely violate the renounce-capable-always doctrine, and the exact one-way-lock pattern to copy already exists in `BurgersCommunityVault.sol` (bool at line 80, guard at line 157, `renounceAdminWithdraw()` at line 170). The third tier is game-economy contracts with real on-disk source (`RewardPoolBase`, `LPFaucet`) plus two porting/deploy jobs (BandZap V3→V4, PrizePool on-chain condition adapters).

## 2. All gaps

| # | Title | Type | BNKR-deployable | Status |
|---|-------|------|:---:|--------|
| 1 | PrizePool (USDG) on Robinhood | Deploy (staged package) | Yes | **PACKAGED** |
| 2 | RHReactorFactory on Robinhood | Deploy (staged package) | Yes | **PACKAGED** |
| 3 | RHVaultFactory on Robinhood | Deploy (staged package) | Yes | **PACKAGED** |
| 4 | TasernBridgeBase (RH nation-token leg) | Deploy (staged package) | Yes | **PACKAGED** |
| 5 | MRB-BASE MfT lock vault — renounce redeploy | Redeploy (source has fix) | Yes | **READY — needs migration plan** |
| 6 | PegCommunityVault (USDG/FTP) — add renounce | Edit + redeploy | Yes | **NEEDS EDIT** (add lock) |
| 7 | PowerLiquidityV2 (Aave yield vault) — add renounce | Edit + redeploy | Yes | **NEEDS EDIT** (add lock) |
| 8 | PLManager (PowerLiquidity V3 mgr) — add renounce | Edit + redeploy | Yes | **NEEDS EDIT** (add lock) |
| 9 | PrivateReactor (Base V3 harvester) — add renounce | Edit + redeploy | Yes | **NEEDS EDIT** (add lock) |
| 10 | RewardPoolBase (ToT WoW) — deploy | Deploy (source on disk) | Yes | **READY — needs ctor args** |
| 11 | LPFaucet (ToT WoW) — deploy | Deploy (source on disk) | Yes | **READY — needs ctor args** |
| 12 | BandZap — port Base V3 → RH V4 | Port + deploy | Yes | **NEEDS PORT** (V3→V4 rewrite) |
| 13 | PrizePool ShiftCount + TreeWater adapters (Base) | Deploy (source on disk) | Yes | **READY — needs ctor args + wiring** |

## 3. Deploy-ready packages produced this run

Four fully-staged folders under `C:\Users\bigji\Downloads\BNKR-ports\`. Byte sizes are the concatenated deploy-tx `data` (creation bytecode + constructor args, `0x`/whitespace stripped), measured this session.

### #1 — `prize-pool-rh/`
- **Files:** `PrizePool.sol`, `creation-bytecode.txt`, `constructor-args.txt`, `PrizePool-abi.json`, `FOR-BNKR.txt`
- **Creation bytecode:** 6,399 bytes · **constructor args:** 428 bytes · **total deploy data ≈ 6,827 bytes**
- **Target:** Robinhood chain 4663. solc `0.8.35+commit.47b9dedd`, viaIR, optimizer 200, evmVersion paris. maxFee 0.15 / priority 0.01 gwei.
- **Constructor (2):** `prizeToken` = USDG `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`, `admin` = `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`.
- **Grounding:** no adminWithdraw / no withdraw path in source → **no renounce needed** (add-only, claim-only). This is the exact contract a prior free agent botched to `0x0`.
- **Deliverable:** push `deployed/prize-pool.json` with address + txHash + abi.

### #2 — `rh-reactor-factory/`
- **Files:** `RHReactorFactory.sol`, `creation-bytecode.txt`, `constructor-args-encoded.hex`, `constructor-args.txt`, `FOR-BNKR.txt` (mirrors `mftusd-build/contracts/V4ReactorSuite.sol`)
- **Creation bytecode:** 4,208 bytes · **constructor args:** 17,248 bytes (the `childCreationCode` bytes blob dominates) · **total deploy data ≈ 21,456 bytes**
- **Target:** chain 4663, same compiler/gas.
- **Constructor (6, all pre-encoded in the `.hex`):** positionManager `0x58daec…`, universalRouter `0x53BF6B…`, permit2 `0x…78BA3`, poolManager `0x8366a3…`, prime `0xd51125e2…`, `childCreationCode` bytes.
- **Grounding:** `renounceAdmin()` confirmed at **line 256**; children use two-step `transferAdmin`/`acceptAdmin` (`acceptAdmin()` line 249, `createReactor()` line 178).
- **Post-deploy per token:** `createReactor(coreToken)` → `reactor.acceptAdmin()` on the child. **Do NOT** call child `renounceAdminWithdraw()` during testing.
- **Deliverable:** push `deployed/reactor-factory.json`.

### #3 — `rh-vault-factory/`
- **Files:** `RHVaultFactory.sol`, `BurgersCommunityVault.sol`, `RHVaultFactory.artifact.json`, `creation-bytecode.txt`, `constructor-args.txt`, `FOR-BNKR.txt`
- **Creation bytecode:** **53,975 bytes** (largest — embeds the full child vault creation code; watch this against the ~16.5M per-tx gas cap, but a single CREATE is fine) · **no constructor args** (all RH addrs baked in) · **total deploy data ≈ 53,975 bytes**
- **Target:** chain 4663, same compiler/gas. Est. ~2.2M gas.
- **Grounding:** `BurgersCommunityVault.sol` ships the one-way lock — `bool public adminWithdrawRenounced` (line 80), guard `require(!adminWithdrawRenounced,...)` inside `withdrawPosition()` (line 157), `renounceAdminWithdraw()` (line 170), plus shares-guarded user `withdraw()` (line 276). Meets the unrugable standard out of the box.
- **Post-deploy per vault:** `createVault(owner, tickLower=416600, tickUpper=424800, salt)` — wide/full-range per the lock-full-range-only rule; mint a BURGERS/FTP position; `vault.adoptPosition(tokenId)`. Keep withdrawable during test; Coordinator signals `renounceAdminWithdraw()` at ship.
- **Deliverable:** push `deployed/vault-factory.json`.

### #4 — `tasern-bridge-rh/`
- **Files:** `TasernBridge.sol`, `creation-bytecode.txt`, `constructor-args.txt`, `FOR-BNKR.txt`
- **Creation bytecode:** 6,147 bytes · **constructor args:** 108 bytes · **total deploy data ≈ 6,255 bytes**
- **Target:** chain 4663, same compiler/gas. Owner = deployer (no ctor args of substance).
- **Grounding:** `TasernBridgeBase` (mint side) — the RH-leg source here mirrors the twin-bridge template; the build-phase escape hatch pattern (`escapeHatchRenounced` / `renounceEscapeHatch`) is the same family verified in the Base source (see #5).
- **Post-deploy owner-only:** `setPaused(true)` while testing → `setRelayer(0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC)` → `deployTwin(polygonToken, name, symbol, decimals, cap)` once per nation coin (DDD, OGC, PKT, BTN, IGS, DHG, LGP, PR25, MfT). **Read name/symbol/decimals/cap from each Polygon original — do NOT guess cap.**
- **Deliverable:** push `deployed/tasern-bridge.json` including every `TwinDeployed` twin address.

> **Assumptions / grounding-gaps flagged for the 4 packages:**
> - RH V4 infra addresses (positionManager / universalRouter / permit2 / poolManager / prime) are taken as-baked-into the pre-encoded hex and `rh-v4-addresses.json`; **not re-fetched on-chain this session** — BNKR should sanity-check one against a live Shillwood launch before the reactor-factory child deploys.
> - `rh-vault-factory` deploy is the single largest CREATE (53,975 bytes code). It is one tx and well under the Base/RH per-tx gas cap, but if RH mempool rejects on size, the child code would need externalizing — **not expected, flagged for completeness**.
> - `deployTwin` cap values are **explicitly NOT in the package** — they must be read per-nation off Polygon at deploy time (supply-invariant safety).

## 4. Blocked / not deployable (dropped by the filter)

**These are NOT BNKR contract/skill deliverables and were removed from the ranked set:**

- **Ops transfers, not builds:** relayer-wallet funding (`0x849639…` ETH top-up); MRB-RH "confirm live" (already live).
- **V2-blocked vault-factory family** (needs substantial V2→V4-seed rewrite, not a repackage): `MfTVaultFactory`/FOT, `FundVaultFactory`, `BTCT`/`ETHT`/`PRGT`, `CommunityLPVaultV4`/FOTInit.
- **Aave-only money infra** (needs Aave→Morpho rewrite for RH, or is Base-only design): `CharityFund`/`CharityFundFactory`, `CourtEndowment`, `MoneyForTreesV2`.
- **No recovered source — must be pulled off the VPS first:** `ItemTokenFactory`, `LocationLPFactory`, `StructureFactory`.
- **Unwritten specs, not contracts** (DM-PROMPT design gaps): Character NFT, XP token, endowment/loot/club factories.
- **Frontend `deployed:false` flags with no cited `.sol`:** PowerUp JLT / PR24.
- **Funding / script-wiring, not new contracts:** GOLD/ETH prize-pool "unfilled pool" seeding + achievement-registration. (Kept only the one genuinely deployable piece from this cluster — the condition adapters, #13.)

**Corrections to the recon set (grounded this session):**
- `ManufacturingPool.sol` **does exist** locally at the `mftusd-build` root (PORT-MAP wrongly called it missing). Its owner-withdraw is **intentional working-capital** per founder doctrine, so a renounce is optional/low-value — **not ranked**.
- Line-number spot-checks all pass: MRB `adminWithdraw` guard `require(!escapeHatchRenounced)` at **line 168**, `renounceEscapeHatch()` at **line 172**; PegCommunityVault `withdrawPosition` **169** / `rescueToken` **185** (no renounce present); PowerLiquidityV2 `setDestination` **87** / `transferAdmin` **93** / user `withdraw` **123**; PLManager `withdrawPosition` **178** / `withdrawTokens` **191**; PrivateReactor header "no permanent locks" **line 7** / `withdrawPool` **217**; PrizePool adapters `ShiftCountCondition` **line 310** / `TreeWaterCondition` **line 332**; `prizepool-Mayor.json` `"conditions": "not deployed"` **line 9**; ToT `admin.html` "Not deployed yet" placeholders confirmed.

## 5. Recommended BNKR queue order

1. **`prize-pool-rh` (#1)** — land first. Smallest, zero AMM dependency, no renounce logic to reason about, and it proves the pipeline on the exact contract that previously failed to `0x0`. First builder points.
2. **`rh-reactor-factory` (#2)** — reactor infra for every Shillwood launch token; V4-native, prime already live; renounce already built in.
3. **`rh-vault-factory` (#3)** — automates the community-vault pattern; largest deploy so land it once the pipeline is warm; already meets the unrugable standard.
4. **`tasern-bridge-rh` (#4)** — nation-token bridge leg; deploy the vault paused, then `deployTwin` per coin after reading Polygon caps.
5. **MRB-BASE renounce redeploy (#5)** — highest trust value (4M MfT currently NOT provably locked; source already fixed). Sequence carefully: deploy → `setRelayer` → `addToken` → **migrate locked balance + `outboundNonce`** from `0xD793…` → re-point relayer cursor → `renounceEscapeHatch()` only at ship, coordinated with the RH twin 4,000,000 supply invariant.
6. **Renounce-edit batch (#6–#9)** — `PegCommunityVault`, `PowerLiquidityV2`, `PLManager`, `PrivateReactor`. Copy the `BurgersCommunityVault.sol` flag pattern (bool 80 / guard 157 / `renounceAdminWithdraw()` 170) verbatim, gate every admin pull path, keep user `withdraw()` always open, migrate positions while admin still holds them, verify full-range before any lock.
7. **Game-economy deploys (#10–#11)** — `RewardPoolBase` then `LPFaucet` (ToT WoW); read ctor args from source + the `admin.html`/`deploy-faucet.html` handlers, write addresses back into the pages, fund after deploy.
8. **`BandZap` V3→V4 port (#12)** — real rewrite (SwapRouter02 → UniversalRouter V4); validate against a live Shillwood launch before packaging.
9. **PrizePool condition adapters (#13)** — deploy `ShiftCountCondition` + `TreeWaterCondition` singletons on Base, then `addAchievement()` in ONCHAIN mode; unblocks non-attested claims. No `ShiftCountCondition.json` / `TreeWaterCondition.json` exists yet.
