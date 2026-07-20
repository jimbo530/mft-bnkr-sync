# MfT / Shillwood PRODUCT CATALOG + CALL LOG

**Generated:** 2026-07-20 by Builder (read-only research; no deploys, no txs).
**For:** bankrbot â€” the FULL menu of live tools on Base (8453) and Robinhood Chain (4663), each with a plain-English product line and the exact contract calls.
**Grounding:** bnkr-sync source docs (PORT-MAP, FEE-FLOW-MAP, FEE-FLOW-LAUNCHER, CROSS-CHAIN-FLOW, skills/), mftusd-build deploy JSONs + contract sources, and fresh Blockscout/RPC reads **this session (2026-07-20)**. Every address below was checked on-chain today unless marked RECORDED-ONLY.

**Verification flags:**
- âœ… **VERIFIED-ON-CHAIN** â€” contract code confirmed at the address today (Blockscout API `is_contract=true` or `eth_getCode` > 0). "+source" = explorer also shows verified source.
- ðŸ“„ **RECORDED-ONLY** â€” from a deploy artifact or doc; not re-checked on-chain this session.

**Hard language rules for anyone using this catalog:** no return promises, no APY talk, never the word "invest". Money/FTP/GST are **deposit receipts**, never "stablecoins". State mechanics and on-chain facts only.

**THE TREES LEG â€” current truth (founder 2026-07-20):** tree planting is funded through **Treegens**. Today that means the cause-leg funds accrue to the trees wallet and go out as **donations to Treegens** (a manual send, not an on-chain hop). Treegens' **live-trees product is coming**; once it's on-chain we will **auto-buy live trees** from the cause leg â€” planned, **NOT live yet**. Never describe the tree leg as fully automated end-to-end on-chain today.

---

## 1. THE MAP (one paragraph)

Two chains, one engine. On **Base**, people deposit USDC (or cbBTC/wETH) into **charity funds** (Money for Trees, CHAR-R, CCC-R, PRGT, BTC-T, ETH-T) and get a **1:1 receipt token** back; the principal earns Aave yield, and only the **yield** splits three ways â€” one third to the **cause** (trees, carbon retirement, or direct charity), one third to the **reactor** (which burns MfT and deepens LP), one third back to **depositors**. On **Robinhood Chain**, the same machine runs on Morpho instead of Aave: **FTP (Feed The People)** funds food and **GST (Grow Some Trees)** funds trees, both feeding the RH **prime reactor**. Around this core sit the growth tools: **vault factories** (anyone creates a community LP vault â€” yield auto-compounds, depositors keep the gains, no burns), **reactor factories** (anyone stamps an automated **burn engine** for their token), the **Shillwood launcher** (one-tx token launch with liquidity locked forever), **prize pools** (game achievements pay out, admin can never withdraw), **commission booths** (pay a band token, get a custom song), and **bridges** (Polygonâ†”Base for nation tokens, Baseâ†”RH for MfT). Fees and yield flow inward to the core (MfT burns + charity); nothing flows to a dev wallet.

---

## 2. PRODUCTS

### 2.1 Feed The People â€” FTP (public deposit vault, food funding)

- **CHAIN:** Robinhood (4663)
- **ADDRESS:** `0x873739aeD7b49f005965377b5645914b1D78Ccd3` â€” âœ… VERIFIED-ON-CHAIN +source (name: FeedingPeopleVault)
- **WHAT THE USER GETS:** Deposit **USDG**, get **FTP 1:1**. Your deposit is always **redeemable 1:1** â€” only the **yield** funds food. Holding FTP means your idle dollars are feeding people.
- **HOW TO USE IT:** `approve(FTP, amount)` on USDG, then `deposit(amount)` on FTP. `redeem(amount)` to exit 1:1. `harvest()` is permissionless.
- **WHERE THE MONEY FLOWS:** Principal â†’ Morpho USDG vault `0xBeEff033â€¦09dd` (âœ… verified). Yield splits in fixed thirds (hard-coded, no admin override): 1/3 USDG â†’ ops wallet `0x0780â€¦05F2` (food leg), 1/3 as backed FTP â†’ **RH prime reactor** `0xd511â€¦dd4D` (immutable), 1/3 as backed FTP â†’ the recipient **whitelist** (4 contracts registered, incl. the Burgers community vault + peg vault; add-only).

### 2.2 Grow Some Trees â€” GST (public deposit vault, tree funding)

- **CHAIN:** Robinhood (4663)
- **ADDRESS:** `0x95eD511Dbdd7b52795e1F515314bE8d888Ea4F3F` â€” âœ… VERIFIED-ON-CHAIN +source (name: GrowSomeTreesVault)
- **WHAT THE USER GETS:** Same machine as FTP, aimed at **trees**. Deposit **USDG**, get **GST 1:1**, redeem any time. Yield â€” not principal â€” funds tree planting.
- **HOW TO USE IT:** identical interface to FTP: `approve` â†’ `deposit(amount)` â†’ `redeem(amount)`; permissionless `harvest()`.
- **WHERE THE MONEY FLOWS:** 1/3 yield USDG â†’ trees wallet `0x0780â€¦05F2` (immutable), 1/3 as backed GST â†’ RH prime reactor `0xd511â€¦dd4D` (immutable), 1/3 â†’ whitelist â€” **currently EMPTY** (verified 2026-07-19: `recipients(i)` reverts), so that leg rolls forward inside the vault until recipients are added.

### 2.3 Base charity funds â€” Money, PRGT, CHAR-R, CCC-R, BTC-T, ETH-T

- **CHAIN:** Base (8453)
- **ADDRESSES (all âœ… VERIFIED-ON-CHAIN today):**
  | Fund | Deposit asset | Address | Cause leg goes to |
  |---|---|---|---|
  | **Money for Trees** (+source) | USDC | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` | project wallet â†’ trees |
  | **PRGT** (+source) | USDC | `0xEe6fB5f324B05efF95fD59F4574050a891e6913D` | direct charity EOA `0xEEDEd2D0â€¦428d4f` |
  | **CHAR-R** (+source) | USDC | `0xde12963128CBe9aF173a37FFF866cA4D4A194ff4` | ImpactRouter buys + retires CHAR carbon |
  | **CCC-R** (+source) | USDC | `0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B` | ImpactRouter buys + retires CCC carbon |
  | **BTC-T** | cbBTC | `0x839BAa00734f319C11F2869bC155C6B5Fe35a283` | project wallet â†’ trees |
  | **ETH-T** | wETH | `0x80d1edd0236A06283fd1212FDB12cfA79516933d` | project wallet â†’ trees |
- **WHAT THE USER GETS:** Deposit the asset, get a **1:1 receipt** token. **Redeemable 1:1 any time**, no deposit or exit fee. Only the Aave **yield** is split â€” your principal stays yours.
- **HOW TO USE IT:** two txs: `approve(fund, amount)` on the asset, then `deposit(amount)` (or `depositFor(to, amount)`). Exit: `redeem(amount)`. Wrapped by skill **base-charity-deposit** (`./scripts/deposit.sh <key> <amount>`).
- **WHERE THE MONEY FLOWS:** principal â†’ Aave V3 Base. Every `harvest()` (permissionless): **33.34%** USDC â†’ the cause wallet in the table, **33.33%** â†’ ReactorPrimeV3 `0xA97af977â€¦c9BA` as Money, **33.33%** â†’ stays in Aave and accrues to receipt holders (claim via `claim()` / `claimV2Pool()` / `claimV3Position()`). All splits read live on-chain (FEE-FLOW-MAP, re-verified 2026-07-19).

### 2.4 Community vault creation â€” Robinhood (RHVaultFactory)

- **CHAIN:** Robinhood (4663)
- **ADDRESS:** `0xd41a8E5c44c4a83F6406eB7B530429E5411588Ec` â€” âœ… VERIFIED-ON-CHAIN +source (name: RHVaultFactory; Sourcify exact_match per deploy record)
- **WHAT THE USER GETS:** A community gets its **own BURGERS/FTP liquidity vault** in one call. Community members deposit **USDG** and hold shares of a shared V4 LP position. **No burns here** â€” the FTP yield the vault receives **auto-compounds into the LP**, so **depositors keep the gains**: no new shares are minted, every holder's slice just grows.
- **HOW TO USE IT (skill: rh-vault-factory):**
  1. `predictAddress(vaultOwner, 416600, 424800, salt)` â€” free read.
  2. `createVault(vaultOwner, int24 tickLower, int24 tickUpper, bytes32 salt)` â†’ new vault (CREATE2, ~3M gas).
  3. Owner seeds a BURGERS/FTP V4 position NFT to the vault, then `adoptPosition(tokenId)` â€” vault goes live.
  4. Public: `deposit(usdgAmount, displayName)` (min 0.1 USDG, exact approval first), `withdraw(shareAmount)` for USDG out, `withdrawAsTokens(shareAmount)` for raw FTP+BURGERS.
- **WHERE THE MONEY FLOWS:** deposit USDG â†’ FTP minted 1:1 (all USDG backed) â†’ half swapped to BURGERS through the vault's own V4 pool (that 1% pool fee feeds the Burgers reactor's LP) â†’ both sides added to the community position. FTP leg-3 yield arriving at the vault â†’ `processYield()` compounds it into the same position for all holders.
- **SAFETY NOTE (from the skill, non-negotiable):** never renounce a concentrated-range vault; owner can withdraw the position ONLY while no public depositors hold shares.

### 2.5 Community vault creation â€” Base (MfTVaultFactory + fund variants)

- **CHAIN:** Base (8453)
- **ADDRESSES (all âœ… VERIFIED-ON-CHAIN today):**
  | Factory | Address | Seed asset / paired fund |
  |---|---|---|
  | **MfTVaultFactory** (+source) | `0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1` | USDC / Money (min $10) |
  | MfTVaultFactoryFOT | `0x53b418bb3d27D45c34C240A5969121A7A34424C0` | USDC / Money (fee-on-transfer-safe) |
  | FundVaultFactory CHAR-R | `0x503fe2226ed8c93bC7864a3E59cEb2c64C305c64` | USDC / CHAR-R (min $20) |
  | FundVaultFactory CCC-R | `0x4a2DFd07A13aBD64553d34F65074fc716D97C290` | USDC / CCC-R (min $20) |
  | FundVaultFactory PRGT | `0xA54C86b545F6451c761Da684740bb390495170Df` | USDC / PRGT (min $20) |
  | BTCTVaultFactory | `0xA7BeD0d9963837E8426F241f132e1F8daEA6bD8B` | cbBTC / BTC-T (min 32,000 sats) |
  | ETHTVaultFactory | `0xc2Dbb3A02CF43270e3A69c2e15354887E094575f` | wETH / ETH-T (min 0.0115 wETH) |
- **WHAT THE USER GETS:** One transaction turns any token into a **charity-paired community vault**. The seed LP is **burned to 0xdEaD forever** â€” a permanent floor nobody can pull. After that, anyone can deposit USDC into the vault; charity yield **auto-compounds the LP**, and **depositors keep the gains** (compound mints no new shares â€” every holder's slice deepens). **No burns of the community token** in this path.
- **HOW TO USE IT (skills: vault-create, base-charity-vault-create):** approve seed asset + token to the factory, then `createVault(token, seedAmount, tokenAmount, maxImpactBps)` (selector `0x0eabcca1`). Vault deposits then run through skill **vault-deposit**: read `maxInstantDeposit()` first; small amounts â†’ `deposit(usdcAmount)`; big amounts â†’ `depositQueued(usdcAmount)` + public `processDeposit(user, chunk)` metering. Exit: `withdraw(shareAmount)` â†’ USDC.
- **WHERE THE MONEY FLOWS:** seed â†’ Money minted from USDC (USDC lands in Aave = charity principal) â†’ Money/token V2 LP â†’ LP burned to `0xdEaD`. Ongoing: fund yield assigned to the LP â†’ vault `compound()` claims it and deepens the LP for all depositors. **32 live vaults** on Base today (token-lp-registry.json census, 2026-07-18).
- **ALSO:** **CharityFundFactory** `0x955383723E8A1AD82800406D6f492260918DF882` (âœ… +source) â€” `createFund(name, symbol, charityWallet, charityBps)` deploys a brand-new immutable CharityFund clone for ANY charity wallet (charityBps â‰¥ 1000; no approvals needed; funds are ownerless once created).

### 2.6 Burn reactors â€” the "automated token burns" option (RHReactorFactory)

- **CHAIN:** Robinhood (4663)
- **ADDRESS:** `0xdC36A42cf7F964053EB3Ab2aF169BdaBF4263C80` â€” âœ… VERIFIED-ON-CHAIN +source (name: RHReactorFactory; Sourcify match per deploy record)
- **WHAT THE USER GETS:** A community that wants **automated burns** stamps a **burn reactor** for its token. The reactor harvests its LP fees on a cycle and **burns the token to 0xdEaD** â€” direct burn of the token-side fees, plus ~45% of paired fees **buys the token and burns it**. This is the burn option; the community vault (2.4/2.5) is the no-burn option where depositors keep the gains. One reactor per token, forever.
- **HOW TO USE IT (skill: rh-reactor-factory):**
  1. `reactorOf(token)` â€” free read; non-zero = already exists, stop.
  2. `createReactor(coreToken)` â†’ new reactor (~3.5M gas), then `acceptAdmin()` on the reactor from the same wallet.
  3. Wire: `POSM.safeTransferFrom(admin, reactor, tokenId)` then `addPool(tokenId)` (dust-test first). `execute(minCoreOut[])` is permissionless after a 2-hour cooldown.
- **WHERE THE MONEY FLOWS:** per `execute()`: token-side fees â†’ **BURN** (0xdEaD); paired-side fees â†’ **10%** upstream fuel to the prime reactor `0xd511â€¦dd4D`, **~45%** buy-token-and-burn, **~45%** compound back into the LP. Factory holds no funds; reactor admin is add-only, no withdrawal path.
- **LIVE REACTORS (all âœ… VERIFIED-ON-CHAIN today):** RH prime **V4ReactorPrime** `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D` (+source; burns the MfT twin), **V4FryerTuckReactor** `0x90125c8C3103556c3cdc2cbC9B508A84F52497fA` (burns FRYER), **V4BurgersReactor** `0x3dB6BF508060b51FFC2622b81B888442e7B60458` (burns BURGERS). Base: **ReactorPrimeV3** `0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA` (MfT terminal; Base prime burns MfT fees to the impact registry `0xfd780B0a` â€” ~26.8M MfT held there, +4.0M at 0xdEaD, verified 2026-07-19) and four **sealed** band reactors (EBM/RISH/BONGO/DGT, admin = 0x0).

### 2.7 Shillwood launcher â€” one-tx token launch (Robinhood)

- **CHAIN:** Robinhood (4663)
- **ADDRESS:** `0xca800407BF99a0d654E2605160c8581Ef3dcCE70` â€” âœ… VERIFIED-ON-CHAIN +source (name: Shillwood; `launchCount()=1` read 2026-07-19)
- **WHAT THE USER GETS:** Launch a token in **one transaction**, no ETH needed. 1B supply, **liquidity locked forever**, three sell-walls (token/ETH, token/GST, token/FTP), and its own reactor clone wired to the MfT prime. The **Unrugable** model: fees build locked liquidity, not a dev wallet.
- **HOW TO USE IT (skill: shillwood-launch):** `launch(string name, string symbol, address customUpstream)` with `customUpstream = 0x0` (always) â†’ returns `(tokenAddr, reactorAddr)`. Only inputs are NAME and SYMBOL. Optional logo: POST the X-post image to `https://tasern.quest/api/shillwood/image` (one-time, off-chain).
- **WHERE THE MONEY FLOWS:** walls are seeded from the token's own supply and locked; trading fees flow to the launch's **ShillwoodReactor** clone (impl `0xFc3A7EeBâ€¦2348`, âœ… +source) which burns core fees, compounds paired, and fuels the prime reactor â€” so every launch feeds the MfT core and the GST/FTP causes.
- **BASE ORIGINAL:** **Unrugable factory** `0x90297A8a1F9A7E35bbC9DF8C35Aa7F3FFBe9BDb2` â€” âœ… VERIFIED-ON-CHAIN (11,491 bytes, owner = project agent; source not shown verified on Blockscout). The Base one-tx launcher this was ported from; launched tokens get a reactor + CHAR-reactor pair (see impact-network.md launch list).

### 2.8 Prize pools â€” achievement payouts, admin can never withdraw

- **RH PrizePool (USDG):** `0xF20c8d3B7EB81A2cf100e99690DA2E4D79F47D21` â€” âœ… VERIFIED-ON-CHAIN +source. **Balance today: 0 USDG (live read 2026-07-20 â€” deployed, UNFILLED).**
  - **WHAT THE USER GETS:** A pot that pays **USDG prizes to NFT owners** for achievements. **Nobody â€” not even the admin â€” can withdraw the pot.** The only way money leaves is `claim()`, paying the eligible NFT's current owner.
  - **HOW TO USE IT (skill: rh-prize-pool):** anyone: `fund(amount)` (exact USDG approval first) + all view reads (`poolBalance()`, `rewardAmount(id)`, `isEligible(id, collection, tokenId)`, `hasClaimed(...)`). NFT owner: `claim(achievementId, collection, tokenId)`. Admin only (`0xE2a4â€¦aC10`): `addAchievement`, `attest`, `attestMany`, `setAchievementActive`.
  - **WHERE THE MONEY FLOWS:** in via `fund()` from anyone; out ONLY via `claim()` to the NFT's owner. Reward types: FIXED amount or BPS_OF_POOL.
- **Base prize-pool ladder (game economy):** 15 pools (5 tiers Ã— GOLD/WETH/cbBTC), ðŸ“„ RECORDED (addresses in FEE-FLOW-MAP Â§6, cbBTC legs on-chain wired). cbBTC pools are fed by **MayorVault** `0x44c504Ceâ€¦131F` â†’ **TributeSplitter** `0x6B901D2aâ€¦5a413` (10/20/20/20/20 verified wiring). **WETH pools hold 0 (verified 2026-07-19 â€” unfilled).** GOLD pool funding mechanism is undocumented (open gap).

### 2.9 Commission booths â€” pay a band token, get a custom song

- **Base booth:** `0x1bA68C58d6d774227bf5cf48D8D3C27429616B8f` â€” âœ… VERIFIED-ON-CHAIN (source shows Sourcify-verified per skill; Blockscout name field empty). **14 bands armed** (2026-07-20), price **10,000 of the band's token (~$1)** each.
- **RH booth (Alan-a-Dale):** `0xAfA527CF6Fa1fcFF66837FD3710d498e06aa6b05` â€” âœ… VERIFIED-ON-CHAIN. Band 1 = $ALAN `0x5e35b494â€¦aba3` (âœ… +source), price **10,000,000 $ALAN (~$1)**.
- **WHAT THE USER GETS:** Pay ~$1 in a band's token and a **custom song** about anything gets written, generated, and delivered as a **native video on X**, tagging whoever it's for. Gifting works â€” put the friend's handle in the call. The song joins the link-library for free recalls forever.
- **HOW TO USE IT (skills: band-commission / alan-commission):** two txs â€” `approve(booth, exactPrice)` on the band token, then `commission(bandId, "idea (10+ chars)", "handle")` on the booth. One call = payment + filing (the event IS the order; a watcher picks it up in ~2 min). Thread delivery: append `#<tweetId>` to the handle. Free recalls of existing songs = skill **song-drop** (no contract, no fee â€” post the library link).
- **WHERE THE MONEY FLOWS:** the booth is a **pure pass-through** â€” `transferFrom(payer â†’ projectWallet, price)` in the same tx; the booth holds nothing, ever. Base projectWallet `0x684811C6â€¦f9D0`, RH projectWallet `0xE2a4â€¦aC10` (per deploy records).

### 2.10 Bridges

- **Tasern Bridge (Polygon â†” Base), nation tokens + PR25:**
  - Base vault `0x492Ae01aad197D77ebB817597d8Fa096122040F8` â€” âœ… VERIFIED-ON-CHAIN. Polygon vault `0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f` â€” âœ… VERIFIED-ON-CHAIN (2,616 bytes via RPC today; Polygon Blockscout API was down).
  - **WHAT THE USER GETS:** Move Tasern nation tokens between Polygon and Base. Pure **lock/mint â€” no fee, no yield, no value taken in transit**. The Polygon escape hatch is **renounced** (verified 2026-07-19) â€” the vault is trustless.
  - **HOW TO USE IT:** Polygonâ†’Base: `approve` + `bridgeToBase(token, amount, baseRecipient)`; relayer mints the twin (~1-3 min). Baseâ†’Polygon: `bridgeToPolygon(twin, amount, polygonRecipient)`; relayer releases the original. UI: tasern.quest/bridge.
- **MfT Bridge (Base â†” Robinhood):**
  - Base lock vault `0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb` â€” âœ… VERIFIED-ON-CHAIN. RH twin vault `0xa819b6D99135222f604047A3304ba53424D4779d` â€” âœ… VERIFIED-ON-CHAIN. MfT twin on RH `0x6ae576608725677Bf8D05EA7796849E6F8F57608` â€” âœ… (name: MemeForTrees).
  - **WHAT THE USER GETS:** Move **MfT** from Base to Robinhood and back. Same lock/mint model, no fee. Invariant held on last check: 4.0M MfT locked = 4.0M twins minted.
  - **HOW TO USE IT:** same calls as above with MfT `0x8FB87d13â€¦9bA3` (âœ… +source on Base).
  - **âš  TRUST NOTE (be honest with users):** this bridge is an **older contract version without the one-way renounce switch** â€” the owner key `0xE2a4â€¦` may retain `adminWithdraw` over locked MfT. A renounce-capable redeploy is on the books. Also operational: relayer gas was 0 on both chains at the 2026-07-16 check.

---

## 3. CALL LOG

| Contract | Chain | Function | Who calls | Effect |
|---|---|---|---|---|
| FTP `0x8737â€¦Ccd3` | RH | `deposit(uint256)` | anyone (after USDG approve) | mints FTP 1:1; USDG â†’ Morpho |
| FTP / GST | RH | `redeem(uint256)` | holder | burns receipt, returns USDG 1:1 |
| FTP / GST | RH | `harvest()` | anyone | pulls Morpho yield; splits fixed thirds: ops/trees wallet Â· prime reactor Â· whitelist |
| GST `0x95eDâ€¦4F3F` | RH | `deposit(uint256)` | anyone | mints GST 1:1; USDG â†’ Morpho |
| Money/PRGT/CHAR-R/CCC-R `â€¦` | Base | `deposit(uint256)` / `depositFor(address,uint256)` | anyone (after USDC approve) | mints receipt 1:1; USDC â†’ Aave |
| BTC-T / ETH-T | Base | same | anyone (cbBTC / wETH approve) | mints receipt 1:1 in asset units |
| All Base funds | Base | `harvest()` | anyone | 33.34% â†’ cause wallet Â· 33.33% â†’ ReactorPrimeV3 Â· 33.33% â†’ holders (Aave) |
| All Base funds | Base | `claim()` / `claimV2Pool(lp)` / `claimV3Position(id)` | holder / anyone-for-pool | pays accumulated holder yield |
| RHVaultFactory `0xd41aâ€¦88Ec` | RH | `predictAddress(address,int24,int24,bytes32)` | anyone (view) | vault address before create |
| RHVaultFactory | RH | `createVault(address vaultOwner,int24 tickLower,int24 tickUpper,bytes32 salt)` | anyone | deploys a fresh BurgersCommunityVault (CREATE2) |
| RH community vault | RH | `adoptPosition(uint256 tokenId)` | vaultOwner | verifies pool+range, credits seed shares, activates vault |
| RH community vault | RH | `deposit(uint256 usdgAmount, string displayName)` | anyone (USDG exact approve; min 0.1) | USDG â†’ FTP 1:1 â†’ half â†’ BURGERS â†’ both into V4 LP; shares to depositor |
| RH community vault | RH | `withdraw(uint256 shareAmount)` / `withdrawAsTokens(uint256)` | shareholder | pro-rata exit in USDG / raw FTP+BURGERS |
| RH community vault | RH | `processYield()` | anyone | compounds arrived FTP yield into the LP; no new shares â€” holders' slices grow |
| MfTVaultFactory `0x1f6fâ€¦aaf1` (+ fund variants) | Base | `createVault(address token,uint256 seedAmount,uint256 tokenAmount,uint256 maxImpactBps)` `0x0eabcca1` | anyone (approve seed asset + token) | clones vault, seeds Money(or fund)/token V2 LP, **burns seed LP to 0xdEaD**, registers LP with the fund |
| Base community vault | Base | `deposit(uint256 usdcAmount)` | anyone (â‰¤ `maxInstantDeposit()`) | USDC â†’ fund receipt â†’ half â†’ token â†’ LP; shares minted |
| Base community vault | Base | `depositQueued(uint256)` / `processDeposit(address user,uint256 chunk)` / `cancelDeposit(uint256)` | depositor / **anyone** / depositor | queue any size; public metering into LP; refund unprocessed |
| Base community vault | Base | `compound()` | anyone | claims fund yield for the LP, deepens position for all holders |
| Base community vault | Base | `withdraw(uint256 shareAmount)` | shareholder | removes LP pro-rata, swaps to fund token, redeems â†’ USDC |
| CharityFundFactory `0x9553â€¦F882` | Base | `createFund(string,string,address charityWallet,uint16 charityBps)` `0x5c275a39` | anyone (gas only) | deploys immutable CharityFund clone; registry + FundCreated event |
| RHReactorFactory `0xdC36â€¦3C80` | RH | `reactorOf(address)` / `reactorCount()` / `allReactors(uint256)` | anyone (view) | registry reads; one reactor per token forever |
| RHReactorFactory | RH | `createReactor(address coreToken)` | anyone | stamps a V4 burn reactor wired to the prime; two-step admin to caller |
| RH child reactor | RH | `acceptAdmin()` | createReactor caller | claims reactor admin (required after stamp) |
| RH child reactor | RH | `addPool(uint256 tokenId)` | admin (after NFT transfer from admin) | registers a V4 position (add-only) |
| RH child reactor | RH | `execute(uint256[] minCoreOut)` | anyone (2h cooldown) | collect fees â†’ burn core Â· 10% fuel prime Â· 45% buy-and-burn Â· 45% compound |
| V4ReactorPrime `0xd511â€¦dd4D` | RH | `fuel(address token, uint256 amount)` | child reactors / FTP / GST | burn-flagged tokens â†’ 0xdEaD; reserves held to compound |
| Shillwood `0xbc27â€¦EF46` | RH | `launch(string name, string symbol, address customUpstream=0x0)` | anyone | mints 1B token, locks 3 sell-walls forever, clones reactor, wires network cut â†’ returns (token, reactor) |
| PrizePool `0xF20câ€¦7D21` | RH | `fund(uint256)` | anyone (exact USDG approve) | adds to the pot; can never be admin-withdrawn |
| PrizePool | RH | `claim(uint256 achievementId, address collection, uint256 tokenId)` | eligible NFT owner | pays USDG to the NFT's current owner, once per NFT |
| PrizePool | RH | `addAchievement` / `attest` / `attestMany` / `setAchievementActive` | admin `0xE2a4â€¦` only | configures achievements + eligibility; no fund movement |
| PrizePool | RH | `poolBalance()` / `rewardAmount(uint256)` / `isEligible(...)` / `hasClaimed(...)` | anyone (view) | pot + eligibility reads |
| CommissionBooth Base `0x1bA6â€¦6B8f` | Base | `commission(uint8 bandId, string idea, string handle)` | anyone (exact 10,000-token approve) | pulls price straight to projectWallet + emits Commissioned (the order) |
| CommissionBooth RH `0xAfA5â€¦6b05` | RH | `commission(1, idea, handle)` | anyone (exact 10,000,000 $ALAN approve) | same â€” pass-through payment + order event |
| CommissionBooth (both) | both | `setBand(uint8,address,uint256,bool)` / `setPaused(bool)` / `setProjectWallet(address)` | owner only | roster / pause / destination admin |
| TasernBridgePolygon `0xBB62â€¦016f` | Polygon | `bridgeToBase(address token, uint256 amount, address baseRecipient)` | anyone (approve first) | locks token in vault, emits Locked(nonce,â€¦) |
| TasernBridgeBase `0x492Aâ€¦40F8` | Base | `mintFromPolygon(uint256 nonce, address polygonToken, address to, uint256 amount)` | relayer `0x8496â€¦6CbC` only | mints Base twin to recipient; nonce replay-blocked |
| TasernBridgeBase | Base | `bridgeToPolygon(address twin, uint256 amount, address polygonRecipient)` | anyone | burns twin, emits Burned |
| TasernBridgePolygon | Polygon | `release(uint256 nonce, address token, address to, uint256 amount)` | relayer only | releases original from vault |
| MRB-BASE `0xD793â€¦93Cb` / MRB-RH `0xa819â€¦779d` | Base/RH | same 4 bridge functions as above | users / relayer | MfT lock on Base â†” twin mint/burn on RH; no fee |

---

## 4. OPEN GAPS (honest, with why)

1. **GST whitelist is EMPTY â€” recipients currently 0.** `recipients(i)` reverts on GST (verified sweep 2026-07-19). Its community-LP third rolls forward inside the vault until recipients are registered. FTP's whitelist has 4; GST's has none.
2. **RH PrizePool is UNFILLED â€” 0 USDG, live read 2026-07-20.** Deployed and source-verified, but nobody has funded it and no achievement registrations were confirmed in this session (achievement count not read). Do not market it as "prizes waiting" until funded.
3. **FTP `totalHarvested()` was 0 at the 2026-07-16 read** â€” the yield engine is wired but no harvest had fired then; not re-read today. First harvest still needs confirming before claiming "yield has flowed".
4. **MfT Baseâ†”RH bridge lacks the renounce switch.** `escapeHatchRenounced()` selector absent on MRB-BASE â€” older contract version; owner `0xE2a4â€¦` may retain `adminWithdraw` over the 4M locked MfT. Known item: needs a renounce-capable redeploy. Also, relayer wallet `0x8496â€¦` had **0 gas on both chains** at the 2026-07-16 check â€” bridge transfers stall if unfunded (not re-checked today).
5. **Base WETH prize pools deployed but hold 0** (verified 2026-07-19). **GOLD prize-pool funding mechanism undocumented** (G8) and **MayorVault's upstream deposit contract unverified** (G10) â€” both game-economy design, not the fee path.
6. **Several Base contracts have no verified source on Blockscout** (bytecode confirmed, source page empty): FundVaultFactory Ã—3, BTCT/ETHT factories, MfTVaultFactoryFOT, ReactorPrimeV3, both CommissionBooths on the explorer name field, Unrugable factory, TasernBridgeBase, MRB-BASE, RH: FryerTuck + Burgers reactors, MRB-RH, MfT twin. They exist and match our recorded deploys, but users can't read the source on the explorer for those. (band-commission skill records Sourcify exact-match for the Base booth â€” Sourcify and Blockscout indexes differ.)
7. **Vault Front Door (single-USDC vault creation for BNKR) is SPEC only** (VAULT-FRONTDOOR-SPEC.md) â€” not built, not deployed. Today, Base `createVault` still needs the caller to hold BOTH USDC and the token.
8. **LPManager launcher fee-router (Base) is draft-1, uncompiled, NOT deployed** â€” and its "network cut â†’ MfT" leg is DESIGN only (FEE-FLOW-LAUNCHER Â§3.2). Do not tell users the Base fee-recipient plug-in is live.
9. **RH Tasern bridge leg (nation tokens on RH) is a staged package, not deployed** â€” skills/rh-tasern-bridge still says `FILL_AFTER_DEPLOY`. Nation tokens bridge Polygonâ†”Base only today.
10. **RHVaultFactory `vaultCount()` and RHReactorFactory `reactorCount()` were not read this session** â€” how many community vaults/reactors have been created through the factories since 2026-07-18 is unconfirmed (the factories themselves are verified live).
11. **Polygon Blockscout API was down** (500/timeout) â€” TasernBridgePolygon was verified via `eth_getCode` on a public RPC instead (2,616 bytes of code present); explorer name/verification state not confirmed today.
12. **Base booth projectWallet `0x684811C6â€¦f9D0` is from the deploy record only** â€” not re-read on-chain today (the RH booth's `0xE2a4â€¦` likewise). Both are owner-changeable via `setProjectWallet`.

---

*Read-only compile. Sources: bnkr-sync (PORT-MAP.md, FEE-FLOW-MAP.md, FEE-FLOW-LAUNCHER.md, CROSS-CHAIN-FLOW.md, GAPS-CLOSED sweep, skills/, rh-vault-factory/, rh-reactor-factory/, prize-pool-rh/, token-lp-registry.json, VAULT-FRONTDOOR-SPEC.md) Â· mftusd-build (rh-v4-addresses.json, rh-tool-port-deploy.json, shillwood-deploy.json, alan-booth-deploy.json, base-booth-deploy.json, MfT-Addresses.md, contracts/CommissionBooth.sol) Â· Blockscout/RPC reads 2026-07-20 (script: bnkr-sync/verify/catalog-verify.ps1).*
