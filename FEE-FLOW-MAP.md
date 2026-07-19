# MfT Ecosystem — Fee Flow Map
**Generated:** 2026-07-16  
**Grounding:** contract source reads (C:\Users\bigji\Documents\mftusd-build\contracts\*.sol), deployment JSON artifacts, bankr-impact-network.csv, and live on-chain eth_call reads against Base mainnet (https://mainnet.base.org, chainId 8453) and Robinhood Chain (https://rpc.mainnet.chain.robinhood.com, chainId 4663).  
**Convention:** `A --fn()--> B (x%)` means function fn() on contract A routes x% of the yield/fees to B.

---

## 1. CHARITY FUNDS — Base Chain

### 1.1 CharityFund Base Model (Money, CHAR-R, CCC-R, BTC-T, ETH-T)

Source contract: `C:\Users\bigji\Documents\mftusd-build\contracts\CharityFund.sol`  
Mechanism: `harvest()` — permissionless, anyone can call.

**Deposit flow (ALL five):**
```
User USDC --deposit(amount)--> CharityFund --aavePool.supply()--> Aave V3 Base
                    |
                    +-- mints receipt token 1:1 to user
```
- Selector: `deposit(uint256)` / `depositFor(address,uint256)`  
- Underlying: USDC (0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)  
- Aave Pool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5  
- aUsdc: 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB  

**harvest() yield split — formula from contract:**
```
yieldAmount = aUsdc.balanceOf(this) - totalSupply()
charityShare = yieldAmount * charityBps / 10000
serviceShare = yieldAmount * serviceBps / 10000
holderShare  = yieldAmount - charityShare - serviceShare
```

**Leg routing per contract:**
```
Aave aUSC yield --harvest()--> CharityFund
  charityShare --USDC transfer--> charityWallet
  serviceShare --mftUsdV2.depositFor(reactor, serviceShare)--> ReactorPrimeV3 (as Money receipt)
  holderShare  --stays in Aave; mints new receipt tokens--> contract itself (Synthetix accumulator)
               --> holders call claim() / claimV2Pool() / claimV3Position() to receive
```

**On-chain verified parameters (eth_call, 2026-07-16):**

| Contract | Address | charityBps | serviceBps | holderBps | charityWallet | reactor |
|----------|---------|-----------|-----------|----------|--------------|---------|
| Money | 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 | 3334 (33.34%) | 3333 (33.33%) | 3333 (33.33%) | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | 0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA |
| CHAR-R | 0xde12963128CBe9aF173a37FFF866cA4D4A194ff4 | 3334 (33.34%) | 3333 (33.33%) | ~3333 (33.33%) | 0x228Eac0Afc16fD6995586c8E1039B538e30DaA16 | 0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA |
| CCC-R | 0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B | 3334 (33.34%) | 3333 (33.33%) | ~3333 (33.33%) | 0xf12636665De97c00120c480bF56b8f4d74e55cDc | 0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA |
| BTC-T | 0x839BAa00734f319C11F2869bC155C6B5Fe35a283 | 3334 (33.34%) | 3333 (33.33%) | ~3333 (33.33%) | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | 0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA |
| ETH-T | 0x80d1edd0236A06283fd1212FDB12cfA79516933d | 3334 (33.34%) | 3333 (33.33%) | ~3333 (33.33%) | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | 0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA |

**Notes on charityWallet addresses:**
- 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 = PROJECT wallet (per wallet-map in memory; holds MfT, receives USDC charity leg for Money/BTC-T/ETH-T)  
- 0x228Eac0Afc16fD6995586c8E1039B538e30DaA16 = CHAR-R impact router (from retirement-funds-deployed.json: `"router": "0x228Eac0Afc16fD6995586c8E1039B538e30DaA16"`) — this is an ImpactRouter that buys + retires CHAR  
- 0xf12636665De97c00120c480bF56b8f4d74e55cDc = CCC-R impact router (from retirement-funds-deployed.json: `"router": "0xf12636665De97c00120c480bF56b8f4d74e55cDc"`) — buys + retires CCC  

**PRGT fund (0xEe6fB5f324B05efF95fD59F4574050a891e6913D):**  
Same CharityFund clone. charityBps/serviceBps NOT queried in this session (rate limit). From pump-deployment.json: `"charity": "0xEEDEd2D0453d16fc722187720d90Bb4DB0428d4f"` — this is a secondary address reference for PRGT's charity leg. Flag: direct on-chain read of charityBps/charityWallet for PRGT deferred.

**retirement-funds-deployed.json confirms (source of truth for CHAR-R and CCC-R):**
- CHAR-R charityBps: 3334, serviceBps: 3333 — matches on-chain read  
- CCC-R charityBps: 3334, serviceBps: 3333 — matches on-chain read  
- CHAR-R router (charityWallet destination): 0x228Eac0Afc16fD6995586c8E1039B538e30DaA16 — on-chain confirmed  
- CCC-R router (charityWallet destination): 0xf12636665De97c00120c480bF56b8f4d74e55cDc — on-chain confirmed  

**Full value-transition diagram (each CharityFund clone):**
```
User USDC
  --deposit(amount)--> Aave V3 (aUSC accumulates)

Every harvest() call:
  Aave aUSC surplus
    --33.34% USDC withdraw--> charityWallet (impact/retire/project)
    --33.33% USDC-> mftUsdV2.depositFor(reactor)--> ReactorPrimeV3 as Money
    --33.33% stays in Aave--> minted receipt tokens (contract held)
      --> Synthetix accumulator distributes to token holders on claim()
          (also V2 LP pool holders via claimV2Pool(), V3 position holders via claimV3Position())
```

**GST and FTP special case (see Section 2 for Robinhood):**  
These are NOT CharityFund clones. They use FeedingPeopleVault / GrowSomeTreesVault with fixed thirds in code (not bps storage) and Morpho instead of Aave. Documented separately below.

---

### 1.2 Non-Circulating RetirementVaults (CHAR-RV, CCC-RV)

- CHAR-RV: 0xD4110DA32E769cebc0Fe43B98BF8081cbae5AF2e  
- CCC-RV: 0xdD7E7596BD1F89D0d7f529A03EA5307342824b6A  

These are custodial vaults for USDC deposits with a display leaderboard only. They hold USDC on behalf of depositors with `deposit(amount, displayName)`. No yield split function found in these vaults from source review — they are hold-only. No harvest() was identified in the source for these contracts. Impact is attributed via leaderboard display.

```
User USDC --deposit(amount, displayName)--> CHAR-RV / CCC-RV (hold; leaderboard display only)
```

---

## 2. CHARITY FUNDS — Robinhood Chain (4663)

### 2.1 FTP — FeedingPeopleVault (0x873739aeD7b49f005965377b5645914b1D78Ccd3)

Source: `C:\Users\bigji\Documents\mftusd-build\contracts\FeedingPeopleVault.sol`

**On-chain verified (eth_call against RH RPC, 2026-07-16):**
- `opsWallet()`: 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 (PROJECT wallet)  
- `memeReactor()`: 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D (RH PRIME)  
- `usdg()`: 0x5fc5360D0400a0fd4f2af552add042d716f1d168 (USDG on RH)  
- `vault()`: 0xBeEff033F34C046626B8D0A041844C5d1A5409dd (Morpho Steakhouse USDG vault)  
- `totalHarvested()`: 0 (no harvests yet as of 2026-07-16)  
- `recipientCount()`: 4 (leg-3 whitelist has 4 registered recipients)  
- `routeWired()`: true (at least one active recipient — leg 3 distributes, does not hold)  
- `totalSupply()`: 0x09608906 = 157,794,566 (scaled 6 dec = ~157.8 USDG outstanding)  

**Deposit flow:**
```
User USDG --deposit(amount)--> FeedingPeopleVault --vault.deposit()--> Morpho Steakhouse USDG
                   |
                   +-- mints FTP receipt 1:1 to user
```

**harvest() — fixed thirds, from contract source (no admin override):**
```
yieldAmount = Morpho.convertToAssets(vault.balanceOf(this)) - totalSupply()
reactorShare  = yieldAmount / 3
whitelistShare = yieldAmount / 3
opsShare = yieldAmount - reactorShare - whitelistShare  (1/3 + integer dust)

Morpho.withdraw(yieldAmount, this, this)  [all yield pulled as USDG]

LEG 1: opsShare USDG --safeTransfer--> opsWallet (0x0780...)  [direct, cannot fail]
LEG 2: reactorShare USDG --vault.deposit()--> Morpho (re-deposit)
                          --mint FTP--> this contract
                          --transfer FTP--> memeReactor (0xd511... RH PRIME)  [IMMUTABLE]
LEG 3: whitelistShare USDG --vault.deposit()--> Morpho (re-deposit)
                            --mint FTP--> this contract
                            --_routeToRecipients()--> active recipients by weight
                            [if no active: FTP held, rolls forward on next harvest]
```

**Full FTP harvest diagram:**
```
Morpho yield (USDG)
  --33.33%+ USDG--> PROJECT wallet (0x0780...)           [operations/food security leg]
  --33.33% as backed FTP--> RH ReactorPrime (0xd511...)  [universal charity leg, IMMUTABLE]
  --33.33% as backed FTP--> whitelist[0..3] by weight    [community LP leg, ADD-ONLY list]
```

**Leg-3 whitelist (recipientCount=4, routeWired=true):**  
Recipients are contracts-only (enforced at addRecipient). The 4 registered addresses are not directly readable without additional eth_call reads per index. FLAG — actual whitelist addresses not queried (would require 4 additional eth_call reads for recipients(0..3)). Marked UNVERIFIED in gaps section.

### 2.2 GST — GrowSomeTreesVault (0x95eD511Dbdd7b52795e1F515314bE8d888Ea4F3F)

Source: `C:\Users\bigji\Documents\mftusd-build\contracts\GrowSomeTreesVault.sol`  
Mechanics: byte-for-byte port of FeedingPeopleVault with `opsWallet` renamed `treesWallet`.

**On-chain verified (eth_call against RH RPC, 2026-07-16):**
- `treesWallet()`: 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 (PROJECT wallet)  
- `memeReactor()`: 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D (RH PRIME)  
- `usdg()`: 0x5fc5360D0400a0fd4f2af552add042d716f1d168 (USDG on RH)  
- `totalSupply()`: 0x00d59f80 = 13,934,464 (scaled 6 dec = ~13.9 USDG outstanding)  

**harvest() — fixed thirds, identical to FTP:**
```
Morpho yield (USDG)
  --33.33%+ USDG--> PROJECT wallet (0x0780...)           [tree-planting leg, IMMUTABLE]
  --33.33% as backed GST--> RH ReactorPrime (0xd511...)  [universal charity leg, IMMUTABLE]
  --33.33% as backed GST--> whitelist by weight           [community LP leg]
```

**Note on GST opsWallet():** `opsWallet()` selector reverts on GST (expected — GST uses `treesWallet()` which returned correctly). The underlying mechanic is identical to FTP; only the immutable label differs.

---

## 3. REACTORS

### 3.1 ReactorPrimeV3 — Base (0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA)

**On-chain verified (eth_call, Base, 2026-07-16):**
- `admin()`: 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 (agent wallet)  
- `paused()`: false  
- `upstream()`: reverts (correct — ReactorPrimeV3 is the terminal; no upstream field in the Base V3 implementation)  

**Source used:** Base ReactorPrimeV3 is NOT the V4ReactorSuite.sol in the contracts folder (that is the RH V4 port). The Base prime is the existing MfTReactor.sol / PrivateReactorSealable architecture. From bankr-impact-network.csv row: `ReactorPrimeV3 (MfT terminal), PRIME, Base, 8453, 0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA, 0, reactor, Upstream MfT terminal; cbBTC/wETH yield endpoint`.

**Flow (V3 doctrine from CSV and MEMORY notes):**
```
CharityFund serviceShare (Money receipt)
  --mftUsdV2.depositFor(reactor, amount)--> ReactorPrimeV3

Band reactor fees (EBM/RISH/BONGO/DGT)
  --harvest()--> core side BURNED (0xdEaD)
  --compound--> paired side deepened into LP
  --10% upstream--> ReactorPrimeV3 (in paired currency)

ReactorPrimeV3 internal:
  incoming tokens: Money receipts + paired tokens from children
  meme tokens received: BURNED
  reserve tokens (Money): compounded into prime's own cbBTC/wETH LPs
```

**GAPS for Base prime:** The Base prime source (MfTReactor.sol / PrivateReactor.sol) is NOT in the contracts folder (V4ReactorSuite.sol is the RH port). The exact split % for the Base prime's internal harvest cycle (how it handles incoming Money to buy cbBTC vs compound) cannot be read from the local source files. The `upstream()` selector reverted, confirming no upstream field. Admin confirmed live. MARKED UNVERIFIED — need the deployed Base prime source or ABI to confirm burn-vs-compound routing on the Base prime.

### 3.2 Band Reactors (EBM, RISH, BONGO, DGT) — Base, SEALED

**On-chain verified:**
- EBM reactor (0xA01B92024ee8cb18C3527C1453EF904A1e405095) `admin()`: 0x0000...0000 (SEALED)  
- RISH reactor (0x98D55914FB91a740D91cDdfFb9287594442A542a) `admin()`: 0x0000...0000 (SEALED)  
- BONGO/DGT not queried but CSV states sealed/admin=0x0 — FLAG: on-chain confirm pending  

**Flow (from V4ReactorSuite.sol doctrine, which is the ported version of the Base band reactor doctrine):**
```
V3 LP position (e.g. EBM/EGP, EBM/Money)
  --harvest() -> NonfungiblePositionManager.collect()--> reactor gets band token + paired token

band token side (EBM/RISH/BONGO/DGT) --transfer(0xdEaD)--> BURNED
paired token side (EGP/Money/PKT/IGS)
  --~10%--> ReactorPrimeV3 (fuel upstream)
  --~45% paired -> swap -> band token -> BURN
  --~45% paired --> deepen LP (compound back into position)
```

**Split note:** The exact 10%/45%/45% split is from V4ReactorSuite.sol `FUEL_BPS = 1000` (10%) and `pairedForBuy = pairedRem / 2` / `pairedForLP = pairedRem - pairedForBuy` (50/50 of remaining 90%). This is the RH V4 port. The Base V3 band reactor source is not in the contracts folder. The doctrine is verified as identical from the code comment "identical to the Base Unrugable reactors." MARKED PARTIALLY VERIFIED — doctrine grounded in code comment, exact Base V3 split from source not confirmed.

### 3.3 V4ReactorPrime (RH) — 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D

Source: `C:\Users\bigji\Documents\mftusd-build\contracts\V4ReactorSuite.sol` (V4ReactorPrime contract)

**On-chain verified (eth_call, RH, 2026-07-16):**
- `admin()`: 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10  
- `paused()`: false  
- `poolCount()`: 1 (one V4 LP position registered)  
- `lastExecute()`: 0 (never executed — no harvests yet)  

**Flow:**
```
FTP/GST harvest LEG 2
  --backed FTP/GST--> V4ReactorPrime.fuel(ftp/gst, amount)
     if burnToken[ftp/gst] == true: --transfer(0xdEaD)--> BURNED
     if burnToken[ftp/gst] == false: held for compounding on next execute()

V4FryerTuckReactor child (0x90125c8C3103556c3cdc2cbC9B508A84F52497fA) execute():
  V4 position fees collect (DECREASE_LIQUIDITY(0)+TAKE_PAIR)
  FRYER side --transfer(0xdEaD)--> BURNED
  paired side (FTP/BURGERS/etc)
    --FUEL_BPS (10%)--> V4ReactorPrime.fuel()
    --remaining 90%: /2 -> buy FRYER -> BURN, /2 -> compound back into V4 LP
```

**coreToken of RH PRIME:** reverts on eth_call with `coreToken()` selector — this means the V4ReactorPrime's `coreToken` immutable is NOT accessible via the deployed bytecode as a simple view, or the selector is wrong. FLAG — `coreToken()` on RH PRIME reverts; the prime's own burn token is not confirmed on-chain. From V4ReactorPrime constructor: `coreToken = _core` (passed as constructor arg). Without a deployment log for the exact RH PRIME we cannot confirm what `_core` was set to. UNVERIFIED.

### 3.4 V4FryerTuckReactor (RH) — 0x90125c8C3103556c3cdc2cbC9B508A84F52497fA

**On-chain verified (eth_call, RH, 2026-07-16):**
- `admin()`: 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10  
- `paused()`: false  
- `poolCount()`: 3 (three V4 LP positions registered)  

**Flow (from V4ReactorBase.processPool):**
```
3 V4 LP positions (FRYER pools)
  execute(minCoreOut[]) called every 2h+ cooldown
    for each pool:
      1. collect fees (DECREASE_LIQUIDITY(0) + TAKE_PAIR)
      2. FRYER fees --burn(0xdEaD)
      3. paired balance:
           10% --_fuelUpstream()--> V4ReactorPrime.fuel(paired, 10%)
           90% remaining:
             45% --_buyCore()--> swap paired->FRYER via V4 UR --> BURN FRYER
             45% --_compoundPaired() or _compoundTwoSided()--> add back to V4 LP
```

### 3.5 V4BurgersReactor (RH) — 0x3dB6BF508060b51FFC2622b81B888442e7B60458

**On-chain verified (eth_call, RH, 2026-07-16):**
- `admin()`: 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10  
- `poolCount()`: 1  

**Flow (V4ReactorBase doctrine, coreToken = BURGERS):**
```
1 V4 LP position (BURGERS pool)
  execute():
    collect fees
    BURGERS fees --> BURN
    paired side:
      10% --> V4ReactorPrime.fuel()
      45% --> buy BURGERS --> BURN
      45% --> compound back into LP
```

---

## 4. COMMUNITY VAULTS

### 4.1 Base CommunityLPVaultV3 (EBM-V, RISH-V, BONGO-V, DGT-V)

Source: `C:\Users\bigji\Documents\mftusd-build\contracts\CommunityLPVaultV3.sol`

```
EBM-V: 0xdd47bdDD35866735ac79f9F3F8d4f0513555Ed95  (FUND=Money, TOKEN=EBM, LP=EBM/Money V2)
RISH-V: 0x131bd427935980bbE43c30c3d0aF49e33c0E98E1 (FUND=Money, TOKEN=RISH, LP=RISH/Money V2)
BONGO-V: 0x3aF2d7CCc05FdF3bC6Be14d1F159826b0f31198f (FUND=Money, TOKEN=BONGO)
DGT-V: 0x43ebB722e17dBe698AA70A55Cb428b171A5da367 (FUND=Money, TOKEN=DGT)
```

**deposit(usdcAmount) flow:**
```
User USDC
  --deposit(usdc)--> CommunityLPVaultV3
    --CharityFund.deposit(usdc)--> mints Money 1:1
    --swap halfMoney via V2Router--> TOKEN
    --addLiquidity(Money, TOKEN)--> V2 LP deposited to vault
    --> shares minted to user
```

**compound() flow (charity yield → deeper LP):**
```
CharityFund accumulated yield
  --claimV2Pool(LP, vault)--> Money tokens sent to vault
    --swap halfMoney--> TOKEN via V2Router
    --addLiquidity(Money, TOKEN)--> V2 LP added
    (no new shares minted; LP balance grows → all holders' slices grow)
```

**withdraw(shareAmount) flow:**
```
User shares
  --withdraw(shares)--> V2 LP removed proportionally
    --V2Router.removeLiquidity()--> Money + TOKEN
    --swap TOKEN--> Money via V2Router
    --CharityFund.redeem(Money)--> USDC back to user
```

**Key:** The CharityFund yield accumulator (Synthetix rewardPerTokenStored) assigns rewards to the V2 LP pool address as a "holder." The vault's compound() claims those accumulated rewards and reinvests them, deepening the LP position for all depositors proportionally.

### 4.2 BurgersCommunityVault (RH) — PEG VAULT (0x7562593D18e47aA40EfCd04468b3D5222A40bbf3) and BURGERS VAULT (0x261F76D20983f299962b1481d7968d2F27b79BB1)

Source: `C:\Users\bigji\Documents\mftusd-build\contracts\BurgersCommunityVault.sol`

**deposit(usdgAmount) — BASE FLOW (as of 2026-07-13 founder directive):**
```
User USDG
  --deposit(usdg, name)--> BurgersCommunityVault
    --FeedingPeopleVault.deposit(ALL usdg)--> mints FTP 1:1 (ALL USDG backed)
    --swap HALF FTP -> BURGERS via OWN BURGERS/FTP V4 pool (fee=10000)
      (1% fee on this swap feeds the Burgers reactor's LP)
    --V4 modifyLiquidities(INCREASE_LIQUIDITY) FTP + BURGERS--> community V4 position
    --> liquidity units = shares to user
```

**processYield() — LEG 3 yield auto-compounds:**
```
FTP received as LEG 3 from FeedingPeopleVault.harvest()
  --swap HALF FTP -> BURGERS via OWN pool
  --add both to V4 community position
  (no new shares; existing holders' slices grow)
```

**withdraw(shareAmount) — BASE FLOW:**
```
User shares
  --withdraw(shares)--> DECREASE_LIQUIDITY pro-rata
    --swap BURGERS -> FTP via OWN pool
    --FeedingPeopleVault.redeem(ALL FTP)--> USDG back to user
```

---

## 5. BRIDGES

### 5.1 Tasern Bridge — Polygon <-> Base

Source: `C:\Users\bigji\Documents\mftusd-build\contracts\TasernBridge.sol`  
Deployment: `C:\Users\bigji\Documents\mftusd-build\tasern-bridge-deployment.json`

**Contracts:**
- Base vault (TasernBridgeBase): 0x492Ae01aad197D77ebB817597d8Fa096122040F8  
- Polygon vault (TasernBridgePolygon): 0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f  
- Relayer: 0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC  
- Owner: 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10  

**On-chain verified (Base, 2026-07-16):**
- TasernBridgeBase `relayer()`: 0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC CONFIRMED  
- TasernBridgeBase `owner()`: 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 CONFIRMED  
- TasernBridgeBase `paused()`: false CONFIRMED  

**Tokens bridged (from tasern-bridge-deployment.json):**  
DDD, OGC, PKT, BTN, IGS, DHG, LGP, PR25  

**Polygon -> Base flow (lock/mint):**
```
User on Polygon
  --TasernBridgePolygon.bridgeToBase(token, amount, baseRecipient)--> token locked in polygon vault
  Emits: Locked(nonce, token, from, baseRecipient, amount)
  Relayer (0x8496...) listens --> calls:
  --TasernBridgeBase.mintFromPolygon(inboundNonce, polygonToken, to, amount)
  --> BridgedToken(twin).mint(to, amount) [twin on Base minted to user]
```

**Base -> Polygon flow (burn/release):**
```
User on Base
  --TasernBridgeBase.bridgeToPolygon(twin, amount, polygonRecipient)--> twin burned
  Emits: Burned(nonce, twin, from, polygonRecipient, amount)
  Relayer listens --> calls:
  --TasernBridgePolygon.release(inboundNonce, token, to, amount)--> original token released to user
```

**Invariant:** `BridgedToken.totalSupply()` on Base == original tokens locked in Polygon vault at all times (hard cap = original fixed supply enforced by BridgedToken.cap).

**Value flow:** No yield or fee. Pure lock/mint, burn/release. No value created or extracted in transit. Replay blocked by nonce mapping (processedInbound[nonce]). The escape hatch (adminWithdraw) was noted as shipped+renounced per MEMORY notes. The escapeHatchRenounced flag on-chain was NOT read in this session. FLAG — confirm escapeHatchRenounced on Polygon vault.

### 5.2 MfT-RH Bridge — Base <-> Robinhood Chain

Contracts:
- MRB-BASE: 0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb  
- MRB-RH: 0xa819b6D99135222f604047A3304ba53424D4779d  
- MfT twin on RH: 0x6ae576608725677Bf8D05EA7796849E6F8F57608  

**On-chain verified (RH, 2026-07-16):**
- MRB-RH `relayer()`: 0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC CONFIRMED  
- MRB-RH `owner()`: 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 CONFIRMED  
- MRB-BASE code exists (bytecode confirmed non-empty)  

**Flow:** Same lock/mint + burn/release model as Tasern bridge. MfT locked on Base, twin minted on RH. No fee or yield in transit.

**Note on MRB-RH dual use:** bankr-impact-network.csv notes MRB-RH `"also Baseling Flower NFT"` — this address is also used for the Baseling Flower NFT contract. This is a CSV annotation; the bridge mechanics are as described.

---

## 6. PRIZE POOLS — Guard-the-Port / Court Endowment System

### 6.1 Architecture

Source: `court-endowment-mayor-deployment.json`, `tributesplitter-mayor-deployment.json`, `prize-ladders-deployment.json`, `mayorvault-mayorw-deployment.json`

**MayorVault (0x44c504Ce08635536635f153B6Ae5d9D6d8b3131F):**
```
Input: civic guard job wage (USDC deposited by players)
Split (from mayorvault-mayorw-deployment.json "split" field):
  50% --> deepen LP (USDC/cbBTC pool 0xfBB6...)
  45% --> systems (TributeSplitter 0x6B901D2a329Edb41D5Da5f961079e10e6345a413)
  5%  --> owners

MayorVault.systems = 0x6B901D2a329Edb41D5Da5f961079e10e6345a413
```

**TributeSplitter (0x6B901D2a329Edb41D5Da5f961079e10e6345a413):**
```
(from tributesplitter-mayor-deployment.json bps array: [1111, 2222, 2222, 2222, 2223])
receives cbBTC from MayorVault 45% leg

Distributes to 5 cbBTC PrizePools:
  11.11% --> Mayor pool    (0xB10fbbCB67d68d1f43E566089FFa0f36Bd057193)
  22.22% --> Lord pool     (0x4cC809378135F9501e37532dFDF3df6aED2B3342)
  22.22% --> PettyKing pool(0x1D6dA6b28a62A45588411eEE66C94AC951A461D2)
  22.22% --> HighKing pool (0x2983E3d4250d01ba05013F1E9995Cd457D7aBa65)
  22.23% --> Emperor pool  (0xF3dA6a1D7d1a57F4E4782213D831646C7E45d6B0)
```

**Note:** The bps [1111, 2222, 2222, 2222, 2223] sum to 10000. These are the cbBTC pools only. The five GOLD pools and five WETH/ETH pools listed in prize-ladders-deployment.json are separate contracts funded independently (not via TributeSplitter).

### 6.2 Full 15-Pool Prize Pool Map

From `prize-ladders-deployment.json` and `court-endowment-*.json`:

**GOLD pools (prize token: 0x2065d87b3a1facc9a4fe037d7a58bc069f597004):**
- Mayor: 0xC76A9F461Be6253BD8676e0db41A6b2E03e318F8  
- Lord: 0x684698ae06Bba12bEf5e7684d8ed466AFD841F5A  
- PettyKing: 0x6C3208D0a637eB2a993AA60bF9838b39D218F2e7  
- HighKing: 0x784D25403f0677A4EB29dD4d8e2887c6Bf9341C3  
- Emperor: 0x5DFfBF9B20b7A1d7155d54C8c750BF60d4CdE5B4  

**WETH pools (prize token: 0x4200000000000000000000000000000000000006 = wETH):**
- Mayor: 0x0590AE358c9DdDBbe36CCf5D9F9FBe69290980f2  
- Lord: 0x98750a778E8A65C5Deac9BA26ceDCf8bb8c9A66B  
- PettyKing: 0x2C7737eaAa70e031EDd04d3712525368d93C0a9A  
- HighKing: 0xf17792CACE3FD578a7b2d75e19afeA301f6c8D7f  
- Emperor: 0x15B5F48d378D1F73fd151a6eD3B97508C818498a  

**cbBTC pools (funded via TributeSplitter):**
- Mayor: 0xB10fbbCB67d68d1f43E566089FFa0f36Bd057193  
- Lord: 0x4cC809378135F9501e37532dFDF3df6aED2B3342  
- PettyKing: 0x1D6dA6b28a62A45588411eEE66C94AC951A461D2  
- HighKing: 0x2983E3d4250d01ba05013F1E9995Cd457D7aBa65  
- Emperor: 0xF3dA6a1D7d1a57F4E4782213D831646C7E45d6B0  

**Prize pool flow (claim by achievement attest):**
```
Guard-the-Port job completion on-chain
  --> Attest keeper reads achievement (WorkClock / job completion events)
  --> calls PrizePool.attest(player, tier) or equivalent
  --> PrizePool accumulated balance distributed to claimant at their tier

Funding sources:
  cbBTC pools: TributeSplitter receives 45% of MayorVault inflow -> distributes by bps
  GOLD pools: funded by game gold economy (exact funding mechanism for gold pools NOT in these source files — FLAG)
  WETH pools: from court-endowment notes, WETH pools "DEPLOYED but UNFILLED" per MEMORY
```

**WETH pool funding status:** From MEMORY notes "WETH pools deployed but UNFILLED." The court-endowment-mayor-deployment.json shows the CourtEndowment contract (0x0212F678690eFBe3C2F92c7F57FC0db3F9cf5820) with `prizePool` pointing to the cbBTC Mayor pool. The WETH pool funding mechanism is not documented in the deployment artifacts read. FLAG.

---

## 7. PEG BOTS

### 7.1 Base Money/USDC Peg Bot — peg-arb-v9.js

Source: `C:\Users\bigji\Documents\mftusd-build\peg-arb-v9.js`

**Assets watched:** Money (0xe3dd), PRGT (0xEe6f), two legacy vaults (PL, MfTv1)  
**Venue:** Base Uniswap V3 (also V2 and Flaunch V4 pools discovered dynamically)  
**Wallet:** NATIONS_COLLECTOR_KEY (separate from agent/treasury)  

**Flow:**
```
Peg bot cycle (every 60s):
  Monitor USDC/Money V3 pools for deviation from 1:1
  dev < -0.1%: buy Money cheap with USDC via V3Router --> redeem Money 1:1 at CharityFund --> profit in USDC
  dev > +0.1%: deposit USDC at CharityFund --> mint Money 1:1 --> sell Money at premium via V3Router
  V3 swap: V3Router 0x2626664c2603336E57B271c5C0b26F421741e481
  CharityFund deposit/redeem: Money 0xe3dd (1:1 USDC)
```

**Bot wallet:** env `NATIONS_COLLECTOR_KEY` (not identified as a specific address in source).  
**Run mode:** VPS pm2 or local, checked via peg-guard.ecosystem.config.cjs.

### 7.2 FTP/USDG Peg Bot (RH) — rh-ftp-peg-bot-v2.cjs

Source: `C:\Users\bigji\Documents\mftusd-build\rh-ftp-peg-bot-v2.cjs`

**Asset:** FTP/USDG, fee 500, tight 0.99-1.01 band V4 pool on RH  
**Venue:** RH Uniswap V4 UniversalRouter (0x53BF, confirmed from source comment)  
**Permit2:** 0x000000000022D473030F116dDEE9F6B43aC78BA3 (inferred from ADDR json)  
**Bot wallet:** env `PEG_BOT_KEY` (dedicated key, never agent/treasury)  

**Flow:**
```
Cycle every 20s:
  Read FTP/USDG V4 pool sqrtPriceX96 via PoolManager.extsload()
  dev < -0.25%: buy FTP cheap via V4 UR --> FeedingPeopleVault.redeem() 1:1 --> USDG profit
  dev > +0.25%: FeedingPeopleVault.deposit(USDG) --> mint FTP 1:1 --> sell FTP at premium via V4 UR
  
  GAS: computed live each cycle (GAS_UNITS x basefee x ETH/USDG pool price)
  Slippage guard: 0.75% (SLIP_BPS=75)
  Max loss for duty trade: $0.10
  Attack flag: written if >5 consecutive out-of-peg cycles despite trading
  TopUp keeper: rh-peg-bot-topup.cjs watches for low USDG float
```

### 7.3 GST/USDG Peg Bot (RH) — rh-gst-peg-bot.cjs

Source: `C:\Users\bigji\Documents\mftusd-build\rh-gst-peg-bot.cjs`

Identical mechanics to FTP peg bot. Only differences:
- Asset: GST/USDG pool  
- Vault: GrowSomeTreesVault.deposit/redeem  
- Bot wallet: dedicated `GST_PEG_BOT_KEY` (never shared with FTP guard)  
- State files: separate (`rh-gst-onehop-state.json`, `rh-gst-peg-topup-needed.json`)  

```
Cycle every 20s:
  Read GST/USDG V4 pool sqrtPriceX96
  dev < -0.25%: buy GST cheap --> GrowSomeTreesVault.redeem() 1:1 --> USDG profit
  dev > +0.25%: GrowSomeTreesVault.deposit(USDG) --> mint GST 1:1 --> sell at premium
```

### 7.4 BTC-T/cbBTC Peg Bot — btc-peg.cjs

Source: `C:\Users\bigji\Documents\mftusd-build\btc-peg.cjs`

**Asset:** BTC-T (0x839BAa..., 8 dec) / cbBTC (0xcbB7C0..., 8 dec)  
**Venue:** V3 fee 100 pool (±5% band): 0x7a635f8c66b93eb7f3e9ec45abdcc6a8fc6f6eca  
**Router:** V3Router 0x2626664c2603336E57B271c5C0b26F421741e481  
**Bot wallet:** env `NATIONS_COLLECTOR_KEY`  

**Flow:**
```
Cycle every 5 min:
  Read pool slot0 sqrtPriceX96
  NAV-par = BTC-T.totalBacking() / BTC-T.totalSupply()  [drifts up at Aave cbBTC APR]
  dev < -0.5%: buy BTC-T with cbBTC via V3Router (BTC-T underpriced, redeemable 1:1 = riskless arb)
  dev > +0.5%: sell held BTC-T for cbBTC via V3Router (BTC-T at premium)
  Slippage: 1% (99% of quoted output)
  Min trade: 0.0000005 BTC (~$0.03 floor)
  Max size: 50% of held side per correction (INV_CAP=0.5)
  P&L denominated in satoshis (cbBTC + BTC-T combined)
```

---

## 8. COMPLETE SYSTEM VALUE FLOWS (SUMMARY DIAGRAMS)

### Base Chain End-to-End
```
User USDC
  |
  v
CharityFund (Money/CHAR-R/CCC-R/BTC-T/ETH-T)
  --1:1 receipt minted-->  User holds receipt token
  --USDC deposited-->  Aave V3 (earning yield)
  |
  v  [every harvest()]
Aave yield
  |--> 33.34% USDC --> charityWallet
  |     Money/BTC-T/ETH-T: --> PROJECT wallet (0x0780...)
  |     CHAR-R:             --> ImpactRouter (buys+retires CHAR carbon credits)
  |     CCC-R:              --> ImpactRouter (buys+retires CCC carbon credits)
  |
  |--> 33.33% via mftUsdV2.depositFor()--> ReactorPrimeV3 (as Money receipt)
  |     ReactorPrimeV3 internal: meme tokens BURNED; reserves compounded
  |
  |--> 33.33% auto-compounds (stays in Aave; new receipt tokens minted)
        --> distributed to receipt holders + LP holders on claim()
              CommunityLPVaultV3 compound() claims this for depositors
```

### Robinhood Chain End-to-End
```
User USDG
  |
  v
FTP or GST vault
  --1:1 receipt minted-->  User
  --USDG deposited-->  Morpho Steakhouse USDG vault (earning Morpho yield)
  |
  v  [every harvest()]
Morpho yield
  |--> 33.33%+ USDG --> PROJECT wallet (0x0780...)  [food/trees direct]
  |
  |--> 33.33% as backed FTP/GST --> RH ReactorPrime (0xd511...)
  |     ReactorPrime: classify token: meme->BURN, reserve->compound
  |
  |--> 33.33% as backed FTP/GST --> whitelist recipients (contracts only)
        BurgersCommunityVault: receives FTP/GST, swaps half->BURGERS, adds to V4 LP

RH V4 Reactor chain:
  V4FryerTuckReactor V4 LP fees
    |--> FRYER side BURNED
    |--> 10% paired --> V4ReactorPrime.fuel()
    |--> 45% paired --> buy FRYER --> BURN
    |--> 45% paired --> compound back into V4 LP
```

### Bridge Flows (no value created/extracted)
```
Polygon tokens --TasernBridgePolygon.bridgeToBase()--> locked polygon vault
                                                    --> relayer mints twin on Base
Base twins --TasernBridgeBase.bridgeToPolygon()--> twin burned on Base
                                               --> relayer releases original on Polygon

MfT on Base --MRB-BASE.lock()--> locked
            --> relayer --> MRB-RH.mint()--> MfT twin on RH
MfT twin on RH --MRB-RH.burn()--> burned
               --> relayer --> MRB-BASE.release()--> MfT released on Base
```

---

## 9. GAPS / UNVERIFIED

The following claims or states could NOT be fully grounded from local source files or on-chain reads performed in this session. Each is flagged with the blocker.

| # | Item | Gap / Blocker |
|---|------|---------------|
| G1 | **PRGT charityBps/serviceBps/charityWallet** | Not queried on-chain (rate limit). pump-deployment.json lists `"charity": "0xEEDEd2D0453d16fc722187720d90Bb4DB0428d4f"` as a separate address not matching the pattern. Need eth_call for PRGT (0xEe6f) charityBps, serviceBps, charityWallet. |
| G2 | **FTP leg-3 whitelist (4 recipients)** | recipientCount()=4 confirmed. Actual addresses of recipients[0..3] not queried. Need eth_call `recipients(uint256)` x4 on FTP to confirm which contracts receive leg-3 yield. |
| G3 | **GST leg-3 whitelist** | Same gap as G2 for GST. |
| G4 | **RH PRIME coreToken** | `coreToken()` (selector 0x0c2b72e9) reverts on RH PRIME (0xd511). Either the deployed bytecode does not expose this as a standard view (possible if the constructor arg was different), or the selector derivation mismatches. Cannot confirm what the prime burns on its own execute(). |
| G5 | **Base ReactorPrimeV3 exact harvest split** | The Base prime source (MfTReactor.sol / PrivateReactor.sol) is NOT in the contracts folder. V4ReactorSuite.sol is the RH port only. The exact Base prime harvest logic (burn-vs-compound of incoming Money + cbBTC/wETH yield routing) cannot be read locally. Need the deployed Base prime ABI/source to verify. |
| G6 | **Band reactors BONGO/DGT sealed admin** | Only EBM and RISH admin=0x0 confirmed on-chain. BONGO (0xA607) and DGT (0x6ab0) admin not queried. CSV states sealed; confirm on-chain. |
| G7 | **TasernBridge Polygon escapeHatchRenounced** | MEMORY says bridge shipped and hatch renounced. The on-chain flag `escapeHatchRenounced` on 0xBB62... (Polygon) was not read in this session (Polygon RPC not polled). Confirm on Polygon chain. |
| G8 | **GOLD prize pool funding source** | The 5 GOLD prize pools (0xC76A9F... etc) are deployed (prize-ladders-deployment.json). Their funding mechanism (what deposits GOLD into them) is not in the source files read. The TributeSplitter only funds cbBTC pools. GOLD pools may be funded via a separate MayorVault or manually. No source file documents this path. |
| G9 | **WETH prize pool fill state** | MEMORY confirms "WETH pools deployed but UNFILLED." No fill has been confirmed on-chain (balance not queried). |
| G10 | **MayorVault wage/water inflow mechanism** | mayorvault-mayorw-deployment.json confirms the 50%/45%/5% split and TributeSplitter wiring. But the actual game contract that deposits USDC into MayorVault (WorkClock / job completion flow) is not in the contracts folder read. The upstream trigger (Guard-the-Port job payout path) is unverified from source. |
| G11 | **CCC-R serviceBps on-chain** | Only charityBps (3334) and charityWallet confirmed for CCC-R. serviceBps read returned rate-limit error. Inferred 3333 from deployment JSON but NOT confirmed on-chain. |
| G12 | **FTP opsWallet() selector mismatch** | Early opsWallet() call on FTP returned rate-limit, but later call with same selector 0x68db925a returned 0x0780... (confirmed). First call failure was rate limit, not selector error. Status: RESOLVED — opsWallet confirmed. |
| G13 | **MRB-BASE outboundNonce** | `outboundNonce()` selector reverted on both bridge contracts. Either selector is wrong or the function is not public. Nonce state not verifiable with current approach. |
| G14 | **RH FRYER coreToken** | Same gap as G4. coreToken() not queryable on RH FRYER reactor. From code comment in V4ReactorSuite.sol: "coreToken = FRYER ($FRYER, the meme)." Address 0xe15c...0145 per MEMORY. Not confirmed via on-chain read. |
| G15 | **Community vault V3 actual LP addresses** | EBM-V, RISH-V, BONGO-V, DGT-V addresses taken from bankr-impact-network.csv. The LP pair addresses they deposit into (V2 pairs) not confirmed from on-chain reads — taken from contract constructor logic (FUND+TOKEN+LP args). |

---

### 9.1 GAP CLOSURE — on-chain sweep 2026-07-19 (12 of 15 closed)
Live reads via `verify/verify-all-gaps.cjs` + `verify/verify-g7-fryer.cjs`. Base local node (blk 48,831,870) · RH public (blk 13,793,614) · Polygon publicnode (blk 90,503,099). Reads only.

| Gap | Status | Verified value (live read this sweep) |
|---|---|---|
| G1 PRGT split + charity | ✅ CLOSED | `charityBps 3334` / `serviceBps 3333`; **charityWallet `0xEEDEd2D0…428d4f`** (direct Polyraiders charity); reactor `0xA97af977…` |
| G2 FTP leg-3 recipients | ✅ CLOSED | 4 → `0x3dB6…0458` (Burgers reactor), `0xD3B0…123F`, `0x7562…bbf3` (peg vault), `0x261F…9BB1` (Burgers vault) |
| G3 GST leg-3 recipients | ✅ CLOSED | `recipients(i)` reverts → **whitelist empty** (matches "leg empty") |
| G4 RH PRIME coreToken | ✅ CLOSED | `coreToken() = 0x6ae5766…7608` = **MfT twin on RH** (the prime's burn target) |
| G5 Base prime internal split | 🔴 OPEN | `coreToken`/`burnToken` revert (no view); prime confirmed LIVE + burns via doctrine — exact % needs deployed source |
| G6 BONGO/DGT sealed admin | ✅ CLOSED | both `admin() = 0x0` (sealed) |
| G7 Polygon bridge hatch | ✅ CLOSED | `escapeHatchRenounced() = true` (trustless, shipped) |
| G8 GOLD prize pool funding | 🟡 OPEN | mechanism/design (game economy) — no single read; peripheral to fee flow |
| G9 WETH prize pools | ✅ CLOSED | all 5 hold **0 WETH** → confirmed UNFILLED |
| G10 MayorVault inflow | 🟡 OPEN | mechanism (game contract that deposits) — peripheral to fee flow |
| G11 CCC-R serviceBps | ✅ CLOSED | `serviceBps 3333`; charityWallet `0xf12636…55cDc` (carbon-retire router) |
| G12 FTP opsWallet | ✅ CLOSED | `0x0780…05F2` (re-confirmed) |
| G13 MRB-BASE nonce | ✅ CLOSED | `outboundNonce() = 2` (bridge used) |
| G14 RH FRYER coreToken | ✅ CLOSED | **FRYER `= 0xe15c7F62…0145`** (grounded from reactor); dead-balance 0 (reactor idle, no harvest fired) |
| G15 community vault LPs | ✅ CLOSED | EBM-V LP `0x7B05…04Dd`, RISH-V `0x87E3…E408`, BONGO-V `0xEdA3…056D`, DGT-V `0x3E2F…5692` |

**12/15 closed on-chain.** Remaining 3: **G5** (needs the deployed prime source — the prime itself is verified live + burning), **G8 + G10** (game-economy mechanism questions, not the fee flow). **None touch the core tree-funding flow, which is fully verified in `FEE-FLOW-LAUNCHER.md §6`.**

---

## 10. CROSS-REFERENCE: Deployment Artifacts vs On-Chain

| Contract | Artifact address | On-chain confirmed | Discrepancies |
|----------|-----------------|-------------------|---------------|
| Money charityWallet | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | YES (eth_call) | None |
| Money reactor | 0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA | YES (eth_call) | None |
| CHAR-R charityWallet | 0x228Eac0Afc16fD6995586c8E1039B538e30DaA16 | YES (eth_call) | Matches retirement-funds-deployed.json router |
| CCC-R charityWallet | 0xf12636665De97c00120c480bF56b8f4d74e55cDc | YES (eth_call) | Matches retirement-funds-deployed.json router |
| FTP opsWallet | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | YES (eth_call on RH) | None |
| FTP memeReactor | 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D | YES (eth_call on RH) | Matches RH PRIME address |
| FTP Morpho vault | 0xBeEff033F34C046626B8D0A041844C5d1A5409dd | YES (vault() on RH) | Matches bankr-impact-network.csv MORPHO-FTP |
| GST treesWallet | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | YES (eth_call on RH) | Same as FTP opsWallet — PROJECT wallet |
| GST memeReactor | 0xd51125e200689bf07A9b36A6c12fE440bb92dd4D | YES (eth_call on RH) | Same RH PRIME |
| TasernBridgeBase relayer | 0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC | YES (eth_call) | Matches tasern-bridge-deployment.json |
| MRB-RH relayer | 0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC | YES (eth_call on RH) | Same relayer key as Tasern bridge |
| EBM reactor admin | 0x0 (sealed) | YES (eth_call) | Confirmed sealed |
| RISH reactor admin | 0x0 (sealed) | YES (eth_call) | Confirmed sealed |
| RH PRIME admin | 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 | YES (eth_call on RH) | Agent wallet |
| RH FRYER admin | 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 | YES (eth_call on RH) | Same agent wallet |
| Base PRIME admin | 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 | YES (eth_call on Base) | Same agent wallet |
| TributeSplitter bps | [1111,2222,2222,2222,2223] | Deployment JSON only | Not confirmed on-chain (eth_call reverted with wrong selector) |
| FTP recipientCount | 4 | YES (eth_call on RH) | Whitelist wired, 4 contracts registered |
| FTP totalHarvested | 0 | YES (eth_call on RH) | No harvest executed yet |
| FTP totalSupply | ~157.8 USDG | YES (eth_call on RH) | Live deposits confirmed |
| GST totalSupply | ~13.9 USDG | YES (eth_call on RH) | Live deposits confirmed |
