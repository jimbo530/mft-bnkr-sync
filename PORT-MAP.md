# RH Port Map — MfT/Unrugable Base Machinery to Robinhood Chain (4663, Uniswap V4)
# Generated 2026-07-16 from mftusd-build sources (read/grep only; no deploys)

## Canonical RH V4 Addresses (from mftusd-build/rh-v4-addresses.json, verified 2026-07-12)

| Role | Address |
|------|---------|
| PoolManager | 0x8366a39CC670B4001A1121B8F6A443A643e40951 |
| PositionManager | 0x58daec3116aae6D93017bAAea7749052E8a04fA7 |
| UniversalRouter (canonical) | 0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77 |
| Permit2 | 0x000000000022D473030F116dDEE9F6B43aC78BA3 |
| USDG | 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168 |
| FTP (Feed the People) | 0x873739aeD7b49f005965377b5645914b1D78Ccd3 |
| GST (Grow Some Trees) | 0x95eD511Dbdd7b52795e1F515314bE8d888Ea4F3F |
| MfT twin on RH | 0x6ae576608725677Bf8D05EA7796849E6F8F57608 |
| BURGERS on RH | 0xf796e42EA375bcD592c892FE64968Ba06188bbA3 |
| RH Meme Reactor Prime | 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D |
| Morpho Vault (FTP/GST) | 0xBeEff033F34C046626B8D0A041844C5d1A5409dd |

---

## DEPLOYED ON RH ALREADY — no port work needed

| Contract | RH Address | Source artifact |
|----------|-----------|-----------------|
| Shillwood factory (launcher) | 0xbc275E1B91d03716846A7a83513f1E47929dEF46 | mftusd-build/shillwood-deploy.json |
| ShillwoodReactor impl | 0xFc3A7EeB3eCE87358A2950F3b96eCc4908132348 | mftusd-build/shillwood-deploy.json |
| RH FTP Peg Community Vault v2 | 0x7562593D18e47aA40EfCd04468b3D5222A40bbf3 | bankr-impact-network.csv |
| RH BURGERS Community Vault v2 | 0x261F76D20983f299962b1481d7968d2F27b79BB1 | bankr-impact-network.csv |
| RH FTP Holding Vault | 0xA194450EE2Bb6663B5DFd1A2277BEed8527d6D64 | bankr-impact-network.csv |
| RH Fryer Tuck Reactor | 0x90125c8C3103556c3cdc2cbC9B508A84F52497fA | _sweep-vps.md |
| RH Burgers Reactor | 0x3dB6BF508060b51FFC2622b81B888442e7B60458 | _sweep-vps.md |
| MfT-RH Bridge (RH vault) | 0xa819b6D99135222f604047A3304ba53424D4779d | bankr-impact-network.csv / _sweep-vps.md |

---

## MAIN PORT TABLE

All contracts below are NOT yet deployed on RH and require work to port/deploy.

### KEY: V4 adaptation column
- **No** = pure Solidity, no LP/swap interface dependency; deploy bytecode as-is after updating hardcoded addresses
- **Yes** = uses Uniswap V3 interfaces (V2Factory, V2Router, SwapRouter02, NonfungiblePositionManager, V3Factory); these must be replaced with RH V4 equivalents
- **N/A** = contract does not touch DEX at all

---

| # | Contract | What it is | Source path | V4 adapt needed? | RH dependency exists? | Constructor args (from source) | Priority × usefulness |
|---|----------|-----------|-------------|------------------|-----------------------|-------------------------------|----------------------|
| 1 | **Shillwood** (factory + reactor) | The Unrugable token launcher ported to RH V4; deploys LaunchToken + ShillwoodReactor clone per launch; 3-wall charity split (TOKEN/ETH, TOKEN/GST, TOKEN/FTP); reactor burns core fees, compounds paired, fuels prime | `contracts/Shillwood.sol` | **No** — already written for V4; uses PoolManager/PositionManager/UniversalRouter/Permit2 natively | **Yes — DEPLOYED** (factory 0xbc275E…, impl 0xFc3A7E…; from shillwood-deploy.json) | `factory(pm, posm, universalRouter, permit2, mft[twin], money[FTP], trees[GST], usdg, upstreamReactor, ethUsdgFee, ethUsdgTickSpacing)` | **HIGH** — the core product; already live, zero port work remaining |
| 2 | **MfTVaultFactory** | One-click Money (FTP) community vault creator; pulls USDG+TOKEN, mints FTP 1:1 via FTP.deposit(), seeds V2 pair FTP/TOKEN, burns seed LP to dead, deploys CommunityLPVaultV3Init clone | `contracts/MfTVaultFactory.sol` | **Yes** — hardcodes USDC=Base addr and FUND=Base Money addr; calls IUniswapV2Factory + IUniswapV2Router02; RH has no canonical V2 (venue is V4); FUND must be FTP; requires porting vault factory to use V4 pool creation or a V2-compat layer | Does RH have a V2 factory/router? Unknown from files read. RH V4 PoolManager is confirmed. No rh-v2-factory.json found in repo. | `constructor(_v2Factory, _v2Router, _implementation)` where implementation = CommunityLPVaultV3Init clone target | **HIGH** — enables community vault creation on RH; blocks all public vault growth; biggest unlock after launcher |
| 3 | **MfTVaultFactoryFOT** | Identical to MfTVaultFactory but measures tokenReceived by balance delta (safe for fee-on-transfer tokens) | `contracts/MfTVaultFactoryFOT.sol` | **Yes** — same V2 dependency as MfTVaultFactory; same USDC/FUND address hardcode | Same as #2 | `constructor(_v2Factory, _v2Router, _implementation)` | **HIGH** — needed for any FOT launch tokens on RH; deploy alongside #2 |
| 4 | **FundVaultFactory** | Generic vault creator for ANY CharityFund-style deposit token (CHAR-R, CCC-R, BTC-T, ETH-T etc.); same shape as MfTVaultFactory but underlying+FUND are constructor params; auto-registers LP with fund via fund.registerV2Pool() | `contracts/FundVaultFactory.sol` | **Yes** — same V2 dependency; also calls ICharityFund.registerV2Pool() which is a V2-pool registry; RH funds (FTP/GST) use Morpho not Aave+Synthetix, so registerV2Pool semantics must be verified against their ABI | V2 router/factory unknown on RH | `constructor(_underlying, _fund, _minSeed, _v2Factory, _v2Router, _implementation)` | **MED** — unlocks multi-fund community vaults; blocked by same V2 question |
| 5 | **BTCTVaultFactory** | BTC-T public vault creator; pulls cbBTC+TOKEN, mints BTC-T 1:1, seeds BTC-T/TOKEN V2 LP, burns LP, deploys clone | `contracts/BTCTVaultFactory.sol` | **Yes** — same V2 dependency; BTC-T (0x839B…) is a Base address; no BTC-T or cbBTC confirmed on RH from files read | No BTC-T on RH; cbBTC not confirmed on RH | `constructor(_v2Factory, _v2Router, _implementation)` with hardcoded CBBTC=0xcbB7C0… and FUND=0x839B… | **LOW** — no RH cbBTC/BTC-T; park until BTC-T exists on RH |
| 6 | **ETHTVaultFactory** | wETH-backed ETH-T vault creator; same shape; pulls wETH+TOKEN | `contracts/ETHTVaultFactory.sol` | **Yes** — hardcodes WETH=0x4200…0006 (Base canonical); RH has ETH native but wETH address may differ; same V2 dependency | RH WETH address not confirmed in files read | `constructor(_v2Factory, _v2Router, _implementation)` with hardcoded WETH=0x4200…0006 and FUND=0x80d1… | **LOW** — park until RH WETH + ETH-T confirmed |
| 7 | **PRGTVaultFactoryFOT** | PRGT (Poly Raiders) variant of MfTVaultFactoryFOT; hardcodes USDC=Base and FUND=PRGT Base addr | `contracts/PRGTVaultFactoryFOT.sol` | **Yes** — same V2 dependency; PRGT is Base-only; no RH analog exists from files read | No PRGT on RH | `constructor(_v2Factory, _v2Router, _implementation)` with hardcoded FUND=0xEe6fB5… | **LOW** — PRGT is Base-only; skip unless PRGT bridge launched on RH |
| 8 | **CharityFundFactory** | Deploys EIP-1167 clones of CharityFund (the Aave-backed 1:1 receipt token); each clone is a new charity fund | `contracts/CharityFundFactory.sol` | **Yes — major** — CharityFund requires Aave V3 Pool + aToken; harvest() calls aavePool.supply()/withdraw() and then calls IMftUsdV2.depositFor() pointing at a reactor; also calls V3 PM + V3 factory for position registry. RH uses Morpho (0xBeEff0…) not Aave for FTP/GST. The underlying architecture is a full rewrite to a Morpho-backed receipt token (which FTP/GST already ARE — they are deployed, not factory-spawned) | FTP and GST are the RH CharityFund analogs and are already LIVE; a factory to deploy MORE Morpho-backed charity clones would require a Morpho vault-cloning API not present in repo | `constructor(impl, usdc, aavePool, aUsdc, mftUsdV2, reactor, v3pm, v3factory, serviceBps)` — 9 args | **LOW** — FTP+GST cover the RH charity-fund need; new charity funds on RH would need a Morpho-clone factory, not this Aave-specific one |
| 9 | **CharityFund (impl)** | The underlying implementation that CharityFundFactory clones; Aave-backed USDC receipt token with Synthetix yield distributor | `contracts/CharityFund.sol` | **Yes — same as #8** — full Aave dependency; harvest() calls V2 router; V3 position registry | Same — Morpho replaces Aave on RH | `initialize(name, symbol, usdc, aavePool, aUsdc, charityWallet, mftUsdV2, reactor, v3pm, v3factory, charityBps, serviceBps)` via factory | **LOW** — RH analog already exists (FTP/GST on Morpho) |
| 10 | **V4ReactorPrime** (V4ReactorSuite.sol) | Aggregator prime for RH V4 reactors; accepts upstream fuel from children; per-token routing: burn (meme) or hold/compound (reserve); harvest own V4 positions | `contracts/V4ReactorSuite.sol` | **No** — already written for V4; uses PoolManager extsload, PositionManager, UniversalRouter, Permit2 | LIVE on RH: 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D is the prime (confirmed in bankr-impact-network.csv + rh-v4-addresses.json) | `constructor(_core, _pm, _router, _permit2, _poolManager)` — no upstream | **HIGH** — already deployed; document only |
| 11 | **V4BurgersReactor** (V4ReactorSuite.sol) | Child reactor; core=BURGERS; burns BURGERS fees, compounds paired, sends 10% upstream to prime | `contracts/V4ReactorSuite.sol` | **No** — written for V4 | LIVE on RH: 0x3dB6BF508060b51FFC2622b81B888442e7B60458 (bankr-impact-network.csv) | `constructor(_core=BURGERS, _pm, _router, _permit2, _prime, _poolManager)` | **HIGH** — already deployed; document only |
| 12 | **V4FryerTuckReactor** (V4ReactorSuite.sol) | Child reactor; core=FRYER; burns FRYER, compounds paired, upstream to prime | `contracts/V4ReactorSuite.sol` | **No** — written for V4 | LIVE on RH: 0x90125c8C3103556c3cdc2cbC9B508A84F52497fA (bankr-impact-network.csv) | `constructor(_core=FRYER, _pm, _router, _permit2, _prime, _poolManager)` | **HIGH** — already deployed; document only |
| 13 | **TasernBridgeBase** + **TasernBridgePolygon** | Lock/mint cross-chain bridge for nation tokens (POL↔Base); relayer-gated; replay-protected by nonce; TasernBridgeBase deploys BridgedToken twin contracts | `contracts/TasernBridge.sol` | **No** — no DEX dependency; pure token lock/mint/burn with nonce-based relay | Bridge is Base↔Polygon only (both chains live: Base 0x492Ae…, Polygon 0xBB62…). A new RH bridge vault would mean a **third** TasernBridge instance that is Base↔RH (separate lock on Base + mint on RH), copying the existing Base vault pattern. MfT-RH bridge (TasernBridge analog) already deployed: Base 0xD793…, RH 0xa819… | TasernBridgeBase: `constructor()` (owner = deployer). TasernBridgePolygon: `constructor()`. Wiring: deployTwin(polyToken, name, sym, dec, cap) per token; setRelayer(relayerAddr); addToken(token) | **MED** — needed to bring nation tokens (EGP/PKT/DDD etc.) to RH; template is proven; new deploy for each new chain leg |
| 14 | **PrizePool** | Holds cbBTC prize pot; pays out for configurable achievements (FIXED or BPS_OF_POOL); ADMIN_ATTESTED or ONCHAIN eligibility mode; add-only admin; no principal withdrawal | `PrizePool.sol` (repo root, not contracts/) | **No** — no DEX dependency; pure token receipt + claim logic | Not deployed on RH from files read. RH has no cbBTC confirmed. Prize pools are Base-only (15 deployed: GOLD/ETH/cbBTC lines, per bankr-impact-network.csv + _sweep-vps.md). An RH prize pool would need an RH prize token (USDG or FRYER or a game token). | `constructor(_cbBtc, _admin)` — but _cbBtc is any IERC20; can use USDG or any RH token | **MED** — can deploy on RH with USDG as prize token when game expands there; no blocker except prize token choice |
| 15 | **CourtEndowment** | Permanent per-tier court endowment; USDC supplied to Aave grows forever; keeper harvests yield → swaps USDC→cbBTC via V3 0.05% pool → sends 100% to PrizePool | `CourtEndowment.sol` (repo root) | **Yes** — calls IAaveV3Pool (supply/withdraw) and ISwapRouter02 (V3 exactInputSingle); both are Base-specific; RH uses Morpho for yield and V4 for swaps | Not deployed on RH. RH has no Aave V3. A RH CourtEndowment would need: Morpho for yield, V4 UniversalRouter for USDG→prize token swap. Full rewrite of harvest(). | `constructor(tierName, usdc, aavePool, aUsdc, cbBtc, v3Router, poolFee, prizePool, wirer, keeperA, keeperB, keeperC)` | **LOW** — blocked on RH Aave/Morpho yield surface + RH prize token; park until RH game economy live |
| 16 | **MoneyForTreesV2** (legacy Base vault impl) | Original MfT Money V2; Aave-backed USDC receipt; 1/3 yield to admin/charityWallet as USDC, 2/3 buys MfT via V2 router and distributes to holder+reactor | `contracts/MoneyForTreesV2.sol` | **Yes** — hardcodes Aave, V2 router, V3 PM+factory; the RH analog is FTP (Morpho-backed) already LIVE; this is the Base implementation, not the RH one | FTP is the RH equivalent and is LIVE (0x873739…) | `constructor(usdc, aavePool, aUsdc, mft, router, weth, v3pm, v3factory, reactor, admin)` — 10 args | **LOW** — superseded on RH by FTP; document for reference only |
| 17 | **CommunityLPVaultV4** (impl) | V4-native community LP vault implementation for RH; the clone target for any V4 vault factory | `contracts/CommunityLPVaultV4.sol` | **No** — this file IS the V4 variant | Status on RH: unknown from files read. The live RH vaults (FTP-PEG-V2, BURGERS-V2, FTP-HOLD) are deployed instances (bankr-impact-network.csv); their implementation address is not confirmed in repo artifacts. Check rh-ftp-vault-v2.json on VPS. | `initialize(...)` — clone init, params depend on CommunityLPVaultV4 source (not read; file exists at contracts/CommunityLPVaultV4.sol) | **HIGH** — the impl that all RH vault clones point at; must be deployed before any RH vault factory |
| 18 | **CommunityLPVaultFOTInit** (impl) | FOT-safe vault implementation (fee-on-transfer token variant); clone target for MfTVaultFactoryFOT and BTCTVaultFactory | `contracts/CommunityLPVaultFOTInit.sol` | **No** — V3/V2 calls are in the factory not the vault impl (vault only calls a V2 Router for exit swaps) | Not confirmed on RH | `initialize(usdc, fund, token, lp, v2Router, maxImpactBps, owner)` — from ICommunityLPVaultFOTInit interface in factory sources | **HIGH** — precondition for any vault factory deploy |
| 19 | **MfT-RH Bridge** (TasernBridge pattern) | Lock/mint bridge for MfT token between Base and RH; Base vault locks MfT, RH vault mints MfT twin | VPS only: `/root/mft-robinhood-bridge/robinhood-bridge-deployed.json` | **No** — same pattern as TasernBridge (no DEX) | **DEPLOYED**: Base vault 0xD793…, RH vault 0xa819…, MfT twin 0x6ae5… (bankr-impact-network.csv + _sweep-vps.md) | Same TasernBridge constructor pattern + setRelayer + addToken | **HIGH** — already live; document only |

---

## WHAT DOES NOT EXIST ON RH AND NEEDS PORT DECISIONS

| Item | Gap | Decision needed |
|------|-----|-----------------|
| V2 Factory/Router on RH | All vault factories (MfTVaultFactory, FOT, FundVault, BTCT, ETHT) use V2 pairs as the seed LP. No V2 factory confirmed on RH from any file read. | Confirm whether RH has a V2 deployment; if not, vault factories must be re-architected to seed V4 pools instead of V2 pairs. This is a substantial rewrite — the seed-LP-and-burn pattern in V4 requires minting a V4 position (via PositionManager), not creating a V2 pair. |
| Aave V3 on RH | CharityFundFactory, CourtEndowment, and MoneyForTreesV2 all require Aave's supply()/withdraw(). FTP/GST use Morpho instead. | Use Morpho vault API for any new RH charity funds; or deploy directly (no factory) as FTP/GST were. |
| cbBTC on RH | PrizePool and CourtEndowment are cbBTC-denominated on Base. | Pick RH prize token (USDG or a game token) for any RH PrizePool deploy. |
| CommunityLPVaultV4 impl address | Needed as the `_implementation` arg for any RH vault factory. Confirmed at VPS: check rh-ftp-vault-v2.json for the live impl address used by the existing RH vaults. | Read `/root/ftp-boards/rh-ftp-vault-v2.json` on VPS to extract the impl address. |
| Unrugable launched-token char-reactor pattern | On Base, each Shillwood launch gets a pair (token reactor + char reactor). The char-reactor burns CHAR. CHAR does not exist on RH. | Decide if Shillwood RH launches get a second reactor for a RH carbon-credit token, or if the single ShillwoodReactor (three-wall, fueling prime) is sufficient. |

---

## DEPLOY ORDER (when unblocked)

```
1.  CommunityLPVaultV4 impl          — prerequisite for all vault factories
2.  CommunityLPVaultFOTInit impl     — prerequisite for FOT vault factories
3.  Confirm V2 factory/router on RH  — gate for steps 4-7
4.  MfTVaultFactory (RH FTP version) — update USDC→USDG, FUND→FTP, hardcodes to RH addrs
5.  MfTVaultFactoryFOT               — same updates
6.  FundVaultFactory (FTP instance)  — same updates; verify registerV2Pool on FTP
7.  FundVaultFactory (GST instance)  — same updates; verify registerV2Pool on GST
8.  PrizePool (USDG-denominated)     — zero dependencies; choose prize token
9.  TasernBridge (RH leg)            — when nation tokens needed on RH
10. CourtEndowment (RH)              — needs Morpho yield + RH prize token decision
```

---

## SOURCE FILE LOCATIONS (absolute paths)

| File | Path |
|------|------|
| MfTVaultFactory.sol | C:\Users\bigji\Documents\mftusd-build\contracts\MfTVaultFactory.sol |
| MfTVaultFactoryFOT.sol | C:\Users\bigji\Documents\mftusd-build\contracts\MfTVaultFactoryFOT.sol |
| FundVaultFactory.sol | C:\Users\bigji\Documents\mftusd-build\contracts\FundVaultFactory.sol |
| BTCTVaultFactory.sol | C:\Users\bigji\Documents\mftusd-build\contracts\BTCTVaultFactory.sol |
| ETHTVaultFactory.sol | C:\Users\bigji\Documents\mftusd-build\contracts\ETHTVaultFactory.sol |
| PRGTVaultFactoryFOT.sol | C:\Users\bigji\Documents\mftusd-build\contracts\PRGTVaultFactoryFOT.sol |
| CharityFundFactory.sol | C:\Users\bigji\Documents\mftusd-build\contracts\CharityFundFactory.sol |
| CharityFund.sol | C:\Users\bigji\Documents\mftusd-build\contracts\CharityFund.sol |
| V4ReactorSuite.sol | C:\Users\bigji\Documents\mftusd-build\contracts\V4ReactorSuite.sol |
| Shillwood.sol | C:\Users\bigji\Documents\mftusd-build\contracts\Shillwood.sol |
| TasernBridge.sol | C:\Users\bigji\Documents\mftusd-build\contracts\TasernBridge.sol |
| PrizePool.sol | C:\Users\bigji\Documents\mftusd-build\PrizePool.sol |
| CourtEndowment.sol | C:\Users\bigji\Documents\mftusd-build\CourtEndowment.sol |
| MoneyForTreesV2.sol | C:\Users\bigji\Documents\mftusd-build\contracts\MoneyForTreesV2.sol |
| CommunityLPVaultV4.sol | C:\Users\bigji\Documents\mftusd-build\contracts\CommunityLPVaultV4.sol |
| CommunityLPVaultFOTInit.sol | C:\Users\bigji\Documents\mftusd-build\contracts\CommunityLPVaultFOTInit.sol |
| RHReactorFactory.sol | C:\Users\bigji\Documents\mftusd-build\contracts\RHReactorFactory.sol |
| BandZap.sol | C:\Users\bigji\Documents\mftusd-build\contracts\BandZap.sol |
| rh-v4-addresses.json | C:\Users\bigji\Documents\mftusd-build\rh-v4-addresses.json |
| shillwood-deploy.json | C:\Users\bigji\Documents\mftusd-build\shillwood-deploy.json |
| bankr-impact-network.csv | C:\Users\bigji\Documents\mftusd-build\bankr-impact-network.csv |
| _sweep-vps.md | C:\Users\bigji\Documents\mftusd-build\_sweep-vps.md |

---

## ADDITIONAL CONTRACTS IN mftusd-build/contracts (grounded from directory listing)

The coordinator requested game-economy factories. After grepping all three local repos
(mftusd-build, Tales-of-Tasern, ToT-World-of-War, Baselings), the following candidates
from memory notes were searched: ItemTokenFactory, LocationLPFactory, StructureFactory,
ManufacturingPool. NONE exist as .sol files in any local repo. They are chat-stage/planned
designs not yet committed to disk. Port map entries below are grounded in files that DO exist.

| # | Contract | What it is | Source path | V4 adapt needed? | RH dependency exists? | Constructor args (from source) | Priority × usefulness |
|---|----------|-----------|-------------|------------------|-----------------------|-------------------------------|----------------------|
| 20 | **RHReactorFactory** | Stamps V4 child reactors (V4BurgersReactor-pattern) on RH; takes child bytecode as constructor arg so any V4ReactorBase-child can be stamped; one reactor per core token; admin = deployer; registry token→reactor | `contracts/RHReactorFactory.sol` | **No** — already written for RH V4; all addresses are constructor params | V4 infrastructure LIVE on RH. Prime LIVE at 0xd51125e2. Factory itself not deployed per any artifact in repo. | `constructor(_positionManager, _universalRouter, _permit2, _poolManager, _prime, _childCreationCode bytes)` | **HIGH** — enables permissionless reactor creation for every Shillwood launch token; natural complement to Shillwood factory; deploy next |
| 21 | **BandZap** | One-tx band token buy on Base; ETH/USDC/Money→band token in 1 atomic hop; holds no balance; sweep-only owner power | `contracts/BandZap.sol` | **Yes** — hardcodes Base USDC=0x833589, WETH=0x4200, Money=0xe3dd38, SwapRouter02=0x2626664; uses V3 exactInputSingle; RH uses V4 UniversalRouter + USDG as the fund analog; a RH variant would be: ETH/USDG→GST→band-token via V4 exactInputSingle in UniversalRouter | No RH deploy of BandZap; SwapRouter02 not confirmed on RH | `constructor(usdc, weth, money, v3Router, wethUsdc_fee, moneyUsdcFee)` — inferred from hardcoded Base references in source | **MED** — nice UX for RH band buys; not urgent but small contract; port after V4 swap path validated by Shillwood |
| 22 | **CommunityLPVaultFOTInit** (impl) | EIP-1167 clone impl for FOT vault factories; `initialize()` replaces constructor; identical mechanics to CommunityLPVaultV4 (despite the V4 name, that contract is also V2-AMM based — both use IUniswapV2Router02) | `contracts/CommunityLPVaultFOTInit.sol` | **Yes** — uses IUniswapV2Router02 (addLiquidity, removeLiquidity, swapExactTokensForTokensSupportingFOT); must be re-targeted to V4 position manager + UniversalRouter if no V2 on RH | V2 Router not confirmed on RH | `initialize(_usdc, _fund, _token, _lp, _v2Router, _maxImpactBps, _owner)` | **HIGH** — clone target for MfTVaultFactoryFOT; must deploy before factory; V4 port needed |

---

## NAMING NOTE: "CommunityLPVaultV4" is V2-AMM-based

Despite its name, `CommunityLPVaultV4.sol` (constructor-deployed) and
`CommunityLPVaultFOTInit.sol` (clone-compatible) BOTH use IUniswapV2Router02 internally.
The "V4" in the name refers to a generation number within this codebase, NOT to
Uniswap V4. Both files call addLiquidity / removeLiquidity / swapExactTokensForTokens
on a V2 Router. If RH has no V2 AMM, both implementations need a V4 AMM rewrite
before any vault factory can be deployed on RH.

---

## GAME-ECONOMY FACTORIES — NOT YET COMMITTED TO DISK

The following contracts are described in memory notes but have no .sol source in any
local repo (mftusd-build, Tales-of-Tasern, ToT-World-of-War, Baselings). They cannot
be ported yet — they must be written first.

| Contract | Memory reference | Status |
|----------|-----------------|--------|
| ItemTokenFactory | project_seas_location_lp_factory.md — items=ERC20s (ItemTokenFactory) | PLANNED, not written |
| LocationLPFactory | project_seas_location_lp_factory.md — deployed on Base at 0x54868729… per _sweep-vps.md | DEPLOYED on Base (VPS ref), no source .sol found locally |
| StructureFactory | project_seas_camp_to_town.md — StructureFactory LIVE 0x98D4306 | DEPLOYED on Base (VPS ref), no source .sol found locally |
| ManufacturingPool | project_seas_boats_and_crafting.md — ManufacturingPool built+fork-verified (gated) | BUILT (VPS ref), no source .sol found locally |

These may exist on the VPS at /root/seas-contracts/ or similar path not captured in
_sweep-vps.md. To port them: (1) locate source on VPS or recover from deployed bytecode,
(2) assess V4 adaptation (LocationLPFactory and ManufacturingPool almost certainly use
V2 pool creation — same gap as vault factories), (3) add to this map with grounded entries.
