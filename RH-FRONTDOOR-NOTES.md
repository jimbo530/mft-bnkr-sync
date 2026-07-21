# RH Front Door — design notes (v2, NOT BUILT)

**Status:** notes only, 2026-07-21. Base v1 (`VaultFrontDoor.sol`, mftusd-build) is done + fork-tested; this file is the RH follow-on. Framing below is the founder ruling as relayed by the Coordinator 2026-07-21 — **founder to confirm directly before any build.**

## The product (same as Base, not the BURGERS/FTP design)
RH vault creation is the **same product as the Base MfTVaultFactory vaults**: user brings the chain dollar (**USDG** on RH), a community impact vault gets created for any token, the seed LP is locked/burned forever, deposits go through a public queue, depositors keep the gains. It is **NOT** the concentrated BURGERS/FTP community-vault design — the existing `RHVaultFactory` (`0xd41a8E5c`, never-renounce concentrated vaults) is a **different product and stays as-is**.

## Differences forced by the venue (and only those)
- **RH chain 4663 has Uniswap V4 ONLY** (PoolManager `0x8366a39C`, POSM `0x58daec31`, UR `0x53BF6B06`). No V2 pairs, no standalone V3 pools. Vault LPs are **V4 positions**.
- **House law — locked V4 positions must be FULL-RANGE [MIN_TICK, MAX_TICK].** A concentrated locked position can drift out of range and die one-sided, unfixable once locked (FTP/BURGERS near-miss 2026-07-16). The seed lock AND any vault-held position that can never be withdrawn must be full-range. Verify ticks before any lock.
- **Quote token = GST** (Grow Some Trees, live `0x95eD…4F3F`) — the RH Money analog. Flow mirrors Base: USDG in → mint GST via its deposit backend → pair token/GST **full-range V4** → lock the seed. Yield/cause legs mirror the Base thirds via the GST vault mechanics (GST is a charity DEPOSIT token — Morpho-backed, not a meme, not a stablecoin).
- **Front-door buy leg:** BNKR moves USDG only; the front door buys the token side itself on V4 (Universal Router / PoolManager swap). Venue support has to be stated per-token like Base v1 — RH V4 pools have no standalone contracts and no Transfer events; read PoolManager balances for grounding.

## What needs BUILDING (the real work)
1. **A V4-native community vault implementation.** The Base `CommunityLPVaultV3Init` is V2-pair based (LP-token shares, router add/remove). V4 has no LP ERC20 — positions live on POSM. Likely shape: port the Base vault logic (deposit USDG → half to GST mint, half token-buy → add to a vault-owned FULL-RANGE POSM position; shares = liquidity delta; withdraw = decrease liquidity), keeping the deposit-queue + max-impact metering semantics.
2. **An RH factory for that vault** (createVault: pull USDG, mint GST, seed full-range V4 position, burn/lock the seed — on V4 "burn forever" needs a defined mechanism: POSM position owned by a dead-end contract or transferred to a locker with no exit; pick one and verify).
3. **The RH front door** wrapping it (same one-USDC-analog shape: `createVaultWithUSDG(token, usdgTotal, maxImpactBps, handle)`).
4. Renounce-capable everywhere per house law; RH estimateGas folds the L1 fee (13M "gas" ≈ pennies — don't panic at estimates).

## Open questions for the founder
1. Confirm the ruling above directly (it arrived Coordinator-relayed).
2. Seed lock mechanism on V4 — POSM position sent where? (dead-owner contract vs no-exit locker; both need a tick check gate that refuses non-full-range.)
3. Which RH tokens are in scope day one ($ALAN, $FRYER, $BURGERS, FTP?) and which venues the buy leg must support at launch (GST-paired V4 pools only, vs USDG/WETH-paired generics).
4. Vault fee/yield legs: mirror the Base thirds exactly, or adjust for GST's Morpho yield already flowing to cause?
