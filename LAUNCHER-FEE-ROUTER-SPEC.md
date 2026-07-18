# Launcher Fee-Router — Money LP Manager (SPEC)

**Status:** SPEC — Claude building 2026-07-18. Deploy is a money op → gated on founder's explicit go.

## Goal
Every token launched via BNKR's native launcher routes its trading fees into a Money-paired LP that grows forever — a permanent, ever-deepening charity-liquidity floor. **We do NOT touch BNKR's launch LP; we only set the token's FEE RECIPIENT to our per-token LP Manager.** Plug-in, not a competing launcher (adoption > a better-but-unused launcher).

## The flywheel
Launch → set fee recipient = LP Manager → trading fees (Xtoken) accrue → manager converts fees to Money + builds an Xtoken/Money LP → the LP locks (permanent floor). Memes pump-and-die, but each pump's fees leave a growing Money seed. The seed is the value — never a meme-moonshot promise (no price claims).

## Dual-chain — SAME FLOW, swap only venue + charity token (CLAUDE builds both, NOT BNKR — he's slow + gets it wrong)

| | Base | Robinhood (chain 4663) |
|---|---|---|
| Charity token (the "Money") | mftUSD `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` | **GST** (Grow Some Trees) `0x95eD…4F3F` **[verify full addr]** |
| AMM | Uniswap **V2** (router `0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24`) | Uniswap **V4** (PoolManager `0x8366a39C`, POSM `0x58daec31`, UR `0x53BF6B06`) **[verify]** |
| Stable hop | USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | USDG `0x5fc5360D` **[verify]** |
| Flow | Xtoken→WETH→USDC→mint mftUSD→LP→lock | Xtoken→…→USDG→mint GST→LP→lock |

The flywheel is identical; only the venue layer (V2↔V4) and the charity token (mftUSD↔GST) change. **Build Base first, port to RH** (swap venue + token only), per "port don't reinvent." RH V4 has no standalone pool contracts + no Transfer events — read PoolManager balances. **All RH addresses are memory-sourced → VERIFY on-chain before wiring a single line.** Base examples below; the RH port mirrors them.

## Contract: `LPManager` (one per launched token)

### Addresses (Base — grounded this session, VERIFY each at build)
- `MONEY` (mftUSD) = `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` (CharityFund clone; USDC deposit receipt; 1 MONEY = 0.01 USDC)
- `USDC` = `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- `WETH` = `0x4200000000000000000000000000000000000006`
- `BNKR` = `0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b`
- V2 router = `0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24`
- Existing BNKR/mftUSD V2 pool (reference) = `0x1941201a37f5548dbe01e900f01b539f508f6cbf`

### State
- `TOKEN` (Xtoken, the launched token), `MONEY`, `USDC`, `WETH`, `router`, `CHARITY_FUND`
- `moneyTokenPair` — the Xtoken/Money V2 pair (created lazily on first compound)
- `admin`, `renounced` (bool, one-way)

### `compound()` — permissionless (the buy machine)
Anyone can call (caller pays gas; optional small caller reward in Xtoken to incentivize poking):
1. Read accrued fees = `TOKEN.balanceOf(this)`.
2. Swap **half** the Xtoken → Money:
   - **Bootstrap** (Xtoken/Money pair missing or thin): `Xtoken → WETH → USDC`, then **mint Money via CharityFund deposit** (the USDC funds charity, Money minted at peg).
   - **Steady state** (pair deep enough): `Xtoken → Money` directly through `moneyTokenPair` (cheaper).
3. `addLiquidity(Xtoken, Money)` → LP tokens to the manager.
4. **LP LOCK:** during BUILD the manager HOLDS the LP (recoverable via `adminWithdraw`). At SHIP, `renounceAdminWithdraw()` (one-way, checked by withdraw) locks it forever = the permanent floor. **Never burn-to-DEAD during prototype — no premature lock.**

### Safety (non-negotiable, per our rules)
- **STAGED** — deploy manager → accrue → compound as separate txs (Base ~16.5M gas cap; never a monolith). If a single compound would exceed the cap (huge fee batch), meter it in chunks.
- **Renounce-capable** — `adminWithdraw` + one-way `renounceAdminWithdraw()` → provably locked/trustless at ship.
- **Exact approvals** (never MaxUint256). **No hardcoded prices** — quote live, revert on stale. **Slippage guard** on every swap. **No silent catches** — every failure reverts or logs.
- **Seed locks, but this is FEES not user deposits** → no withdrawable-user concern here. (User-deposit products stay withdrawable — mint shares → withdraw — per the live CommunityLPVaultV3 model. That rule is NOT relaxed.)

### Open items to confirm at build (grounded, not assumed)
1. **USDC → Money exact path** — mint via CharityFund deposit (funds charity) vs a USDC/Money AMM pool. Read the live Money contract before wiring.
2. **Fee-accrual token(s)** — does BNKR's launch pool pay the fee recipient in Xtoken, WETH, or both? Confirm against a real BNKR launch, handle both.
3. **V2 vs V4** for the Xtoken/Money pair — existing Money LPs are V2 → default V2 unless a launch forces V4.

## Build order
1. Verify Money mint mechanism + fee-accrual token on-chain (read contracts).
2. Write `LPManager.sol` (staged, renounce-capable, guarded).
3. Compile-check + fork test: compound bootstrap → steady-state, seed-lock, renounce.
4. Deploy script (node + agent wallet). **Deploy = gated on founder go** (BNKR may deploy for builder points once correct).
