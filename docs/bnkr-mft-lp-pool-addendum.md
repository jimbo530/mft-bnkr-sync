# BNKR/mftUSD LP Pool — On-Chain Addendum

> Addendum to `docs/bnkr-tree-funding-vault.md`
> Verified on-chain by Bankr, July 2026.
> Pool address: `0x1941201a37f5548dbe01e900f01b539f508f6cbf`

---

## 1. What this pool is

A **live Uniswap V2 pair** pairing $BNKR directly against mftUSD (the MfT Aave
vault token). This is not a hypothetical — it's already deployed, already
holding liquidity, and already routing trades that fund trees.

| Field | Value |
|---|---|
| Pair address | `0x1941201a37f5548dbe01e900f01b539f508f6cbf` |
| Type | Uniswap V2 (UNI-V2) |
| Factory | `0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6` |
| token0 | `0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b` ($BNKR, 18 decimals) |
| token1 | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` (mftUSD / MfT vault, 6 decimals) |
| Reserve0 (BNKR) | 44,862,051,714,899,277,292,891 (~44,862 BNKR) |
| Reserve1 (mftUSD) | 15,000,000 (15 mftUSD) |
| LP total supply | 820,323,579,889,965 |
| kLast | 672,930,775,723,489,159,393,365,000,000 |

---

## 2. Why this changes the vault design

The original spec assumed the vault would route BNKR → USDC → MfT vault →
mftUSD → band token → LP. But a **BNKR/mftUSD LP already exists**. This means:

### 2.1 The pool IS the corridor

BNKR is already paired against mftUSD. Every swap through this pool:
- Buys mftUSD with BNKR (or vice versa)
- mftUSD is the MfT vault token — so buying mftUSD = depositing into the Aave
  vault = funding the yield that funds trees
- Trading fees accumulate to LP holders = tree funding revenue

### 2.2 The vault should deepen THIS pool, not create a new one

Instead of the multi-hop route in the original spec, the vault can:
1. Take BNKR in
2. Add it directly as liquidity to the BNKR/mftUSD V2 pool (paired with mftUSD
   minted from the Aave vault)
3. LP fees from the pool = ongoing tree funding
4. Leaderboard tracks total BNKR liquidity added to this pool

This is simpler, cheaper (one hop, not three), and the LP already has price
discovery and volume.

### 2.3 Revised routing

```
Original:  BNKR → USDC → MfT vault → mftUSD → band token → LP deepen
Revised:   BNKR + mftUSD (minted from vault) → add liquidity to BNKR/mftUSD V2 pool
           → LP fees fund trees → leaderboard records BNKR LP contribution
```

The vault still needs USDC to mint mftUSD (the Aave vault takes USDC in, mints
mftUSD out). So the full revised flow is:

```
BNKR (in)
  → swap portion of BNKR → USDC (via Uniswap)
  → deposit USDC into MfT Aave vault → mint mftUSD
  → pair remaining BNKR + minted mftUSD → add liquidity to BNKR/mftUSD V2 pool
  → LP position held by vault, attributed to funder
  → emit TreeFunding event (USDC-equiv, BNKR, funder)
  → leaderboard updates
```

This is a **self-balancing LP add**: the vault splits incoming BNKR into two
legs — one leg gets swapped to USDC → mftUSD, the other stays as BNKR — then
pairs them into the existing pool. No new pool needed.

### 2.4 Band token routing still works

The original band-token LP deepening path (mftUSD → band token → V3 LP) can
still run as a **secondary route** — the vault can split incoming BNKR between
deepening the BNKR/mftUSD pool AND deepening band-token pools. But the primary
and simplest path is the BNKR/mftUSD pool that already exists.

---

## 3. Updated architecture implications

### 3.1 `BnkrTreeFundingVault` changes

- `fundWithBnkr()` now adds liquidity to the existing V2 pair instead of
  routing through a multi-hop swap chain
- Need to handle the **BNKR/mftUSD ratio**: split incoming BNKR optimally
  so that after swapping part to USDC → mftUSD, the remaining BNKR and the
  minted mftUSD are in the correct ratio for the current pool price
- Use Uniswap V2 Router's `addLiquidity()` (not V3 NonfungiblePositionManager)
  for this pool
- LP tokens (UNI-V2) are held by the vault, attributed to the funder

### 3.2 `TreeFundingLeaderboard` changes

- Metric can now be **total BNKR liquidity added to the BNKR/mftUSD pool**
  (in BNKR terms) OR **USDC-equivalent** (convert BNKR at pool price)
- BNKR is already #1 by default — it's the only asset in the pool
- Other tokens can still route through the vault (swap to BNKR first, then
  add LP), keeping the asset-agnostic leaderboard design

### 3.3 Revenue from LP fees

- The V2 pool charges a 0.3% fee on every swap
- These fees accumulate to LP holders (the vault)
- The vault can claim accrued fees and route them to the tree funding
  beneficiary (`0x0780b1456d5e60cf26c8cd6541b85e805c8c05F2`) or reinvest
  them into more LP
- This is **passive tree funding** — the LP earns fees 24/7 from volume

---

## 4. Open questions for Claude (updated)

7. **V2 vs V3 for BNKR/mftUSD**: the existing pool is V2. Should the vault
   deepen the V2 pool, or also create a V3 concentrated liquidity position
   for better capital efficiency? V2 is simpler and already has liquidity;
   V3 could be added later for active management.
8. **BNKR split ratio**: when adding LP, what % of incoming BNKR gets swapped
   to USDC → mftUSD vs kept as BNKR? Should be calculated from the current
   pool reserves to minimize slippage, not hardcoded.
9. **Fee reinvestment**: should LP fees be auto-compounded back into the pool,
   or routed to the ops/charity beneficiary? Auto-compound grows the LP;
   routing to charity funds trees directly.
10. **Existing LP holders**: who currently holds the 820K LP tokens? If the
    vault adds more LP, it dilutes existing holders' fee share. Need to
    understand the current LP holder distribution before the vault adds
    significant liquidity.

---

## 5. Summary

The BNKR/mftUSD V2 pool at `0x1941...6cbf` is the missing piece. It's already
a live tree-funding corridor — BNKR paired against the MfT vault token, with
trading fees funding the system. The vault's job is to **deepen this pool
automatically** and **track BNKR's contribution on a leaderboard**.

This simplifies the original design significantly:
- No multi-hop routing needed for the primary path
- LP already exists with price discovery
- V2 addLiquidity is simpler than V3 position management
- Fees are passive and ongoing

The band-token LP deepening path from the original spec can run as a secondary
route if desired, but the BNKR/mftUSD pool should be the primary target.

— Bankr
