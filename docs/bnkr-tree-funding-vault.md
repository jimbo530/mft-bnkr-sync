# BNKR Tree Funding Vault — Design Spec

> Authored by **Bankr** for Claude to review and implement.
> Status: DRAFT — architecture proposal, not yet deployed.
> Target chain: Base
> Related repo: `mft-bnkr-sync` (MfT routing + sync infra)

---

## 1. Vision

A "super-powered" vault that takes **$BNKR** as the entry asset and automatically
routes it through the existing **Money for Trees (MfT)** flywheel to fund tree
planting and deepen band-token liquidity — while putting BNKR at the top of a
public **Tree Funding Leaderboard**.

Flow:

```
BNKR (in)
  → swap BNKR → USDC
  → deposit USDC into MfT Aave vault → mint mftUSD
  → swap mftUSD → band token (e.g. DD) via Uniswap V3
  → deepen band-token LP position
  → emit TreeFunding event (USDC-equiv amount, source asset, caller)
  → leaderboard updates
```

The vault is **asset-agnostic by design**: BNKR is the first entry, but any
token can route through it and compete on the leaderboard. That is where the
network effect lives — other projects route their tokens in to climb the
leaderboard, and every route deepens MfT LP.

---

## 2. Why this fits the existing stack

The MfT stack already has every primitive this vault needs:

- **MfT vault** (`0xe3dd3881477c20C17Df080cEec0C1bD0C065A072`) — mints mftUSD
  from USDC. This is the core routing primitive; the vault calls it.
- **Band token purchase path** — already proven via the
  `mft-band-token-purchase` skill: USDC → MfT vault deposit → swap MfT to band
  token via Uniswap V3 SwapRouter02. The vault replicates this on-chain.
- **CommissionBooth** (`0xC094664560024e77A710B80D08d15B15EDE0a4a7`) — live,
  agent-owned, 14 bands registered. Revenue splits (LP deepen + ops) are wired.
- **Routing policy** — mftUSD stays internal (Clarity Act alignment). The vault
  never exposes mftUSD to the user; it is an internal accounting asset only.

So the vault is a **modular plug-in** on top of existing routing, not a
replacement. BNKR goes in, the flywheel runs, LP deepens, leaderboard updates.

---

## 3. Key addresses (Base)

| Role | Address |
|---|---|
| $BNKR | `0x22af33fe49fd1fa80c7149773dde5890d3c76f3b` |
| MfT Aave vault (mints mftUSD) | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` |
| CommissionBooth | `0xC094664560024e77A710B80D08d15B15EDE0a4a7` |
| Uniswap V3 SwapRouter02 | `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` |
| Uniswap V2 router (fallback) | `0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24` |
| Ops / fee recipient | `0x0780b1456d5e60cf26c8cd6541b85e805c8c05F2` |
| Admin | `0xE2a4a8b9d77080c57799a94ba8edeb2dd6e0aC10` |

> Claude: confirm each address against the latest deployment state before
> implementing. These are sourced from the MfT network infrastructure map.

---

## 4. Contract architecture

### 4.1 `BnkrTreeFundingVault` (core)

Non-custodial vault. Users deposit BNKR (or any approved asset); the vault
auto-routes it through MfT and accumulates an LP position on their behalf.

```
contract BnkrTreeFundingVault {
  // --- entry ---
  function fundWithBnkr(uint256 bnkrAmount, bytes32 bandKey) external;
  function fundWithAsset(address asset, uint256 amount, bytes32 bandKey) external;

  // --- routing (internal) ---
  // 1. swap asset -> USDC
  // 2. USDC -> MfT vault.deposit() -> mftUSD
  // 3. mftUSD -> band token via V3 SwapRouter02
  // 4. band token + paired asset -> LP deepen (NonfungiblePositionManager)

  // --- LP position ---
  function lpPosition(bytes32 bandKey) external view returns (uint256 tokenId, uint128 liquidity, uint256 tokensOwed);
  function withdrawLp(bytes32 bandKey, uint128 liquidity) external; // only position owner

  // --- config ---
  function setSlippageBps(uint256 bps) external onlyAdmin;        // default 300 (3%)
  function setTriggerMode(TriggerMode mode) external onlyAdmin;
  function setBandRouter(bytes32 bandKey, address bandToken, uint24 poolFee) external onlyAdmin;
}
```

### 4.2 `TreeFundingLeaderboard`

On-chain counter + event stream that sums tree-funding contributions per
source asset. BNKR is the first entry; the design is asset-agnostic so other
tokens can compete.

```
contract TreeFundingLeaderboard {
  struct Contribution { address sourceAsset; uint256 usdcEquivalent; uint256 ts; }
  event TreeFunding(address indexed sourceAsset, uint256 usdcEquivalent, bytes32 bandKey, address indexed funder);

  mapping(address => uint256) public totalFundedByAsset;     // cumulative USDC-equiv
  mapping(address => uint256) public fundedCountByAsset;      // # of fund events
  address[] public rankedAssets;                             // for off-chain sort

  function record(address sourceAsset, uint256 usdcEquivalent, bytes32 bandKey, address funder) external onlyVault;
  function topN(uint256 n) external view returns (address[] memory, uint256[] memory); // off-chain helper
}
```

**Metric decision (open question for Claude):** leaderboard ranks by
**cumulative USDC-equivalent routed to tree funding**. This is the most
verifiable and asset-agnostic metric. Alternatives — total LP depth added,
mftUSD minted — are noted in §8.

### 4.3 Trigger modes

| Mode | Behavior | Tradeoff |
|---|---|---|
| `SCHEDULE` | DCA-style: route a fixed BNKR amount on cron | predictable, gas-bounded |
| `THRESHOLD` | route when BNKR balance in vault > X | gas-efficient, lumpy |
| `DEPTH_TARGET` | route when band LP depth < target | keeps pools healthy |
| `MANUAL` | anyone calls `fundWithBnkr` | simplest, no keeper needed |

Recommendation: ship `MANUAL` first (anyone can trigger, gas paid by caller),
add `SCHEDULE` via a keeper in v2. Keeps the contract simple and avoids keeper
infra on day one.

---

## 5. Routing detail (the hard parts)

### 5.1 Multi-hop slippage

BNKR → USDC → mftUSD → band token is 3 hops. Cumulative slippage can bite.

- Enforce a **global slippage bound** (`slippageBps`, default 300 = 3%) on the
  final band-token out vs a TWAP oracle.
- Each hop gets a proportional `amountOutMinimum` derived from the global bound.
- If any hop would breach the bound, revert the whole route (atomic). No partial
  fills — the vault either deepens LP or refunds.

### 5.2 LP deepening

- Use Uniswap V3 **NonfungiblePositionManager** (`0xC36442b3a272A498D3286408F8AaA5c3d43eA1a8`).
- Deposit band token + USDC (or mftUSD, depending on pool) into the existing
  band pool at the current tick range, or a managed range set by admin.
- LP position NFT is held by the vault, attributed to the funder
  (`mapping(bytes32 bandKey => mapping(address => uint256 tokenId))`).
- `withdrawLp` is owner-only; decreases liquidity and returns assets.

### 5.3 mftUSD stays internal

Per the MfT routing policy, mftUSD never leaves the vault or reaches the user.
The vault holds the mftUSD transiently between `vault.deposit()` and the V3
swap, then it is gone. No user-facing mftUSD exposure.

### 5.4 Revenue split

Mirror CommissionBooth's existing split: 50% LP deepen / 50% ops. The vault's
`fundWithBnkr` routes the ops share to `0x0780b1456d5e60cf26c8cd6541b85e805c8c05F2`
and the LP share into the position. Keep this configurable but default to the
existing split so the vault is consistent with the rest of MfT.

---

## 6. Leaderboard design

- **On-chain**: `TreeFundingLeaderboard` stores cumulative USDC-equiv per asset
  and emits `TreeFunding` events. Cheap to write, verifiable by anyone.
- **Off-chain**: a subgraph or simple indexer sorts `rankedAssets` by
  `totalFundedByAsset` and renders the public leaderboard UI. BNKR starts at #1
  by seeding (or just by being first to route).
- **Gamification**: any project can route its token through the vault to climb
  the leaderboard. Each route deepens MfT LP and funds trees. This is the
  network-effect loop — the leaderboard is the magnet.

---

## 7. Security / non-custodial guarantees

- Vault is **non-custodial**: LP positions are attributed to funders and
  withdrawable by them. The vault never holds user assets beyond the transient
  routing window.
- `onlyVault` on `Leaderboard.record` — only the vault can write contributions,
  so the leaderboard can't be spammed.
- Reentrancy guards on every routing path (checks-effects-interactions + ReentrancyGuard).
- Admin role is multisig-able; admin can set slippage, bands, trigger mode, but
  **cannot** move user LP positions.
- No upgradeable proxy on day one — deploy immutable, audit, then decide on a
  proxy for v2. Reduces surface area.

---

## 8. Open questions for Claude

1. **Leaderboard metric**: confirm cumulative USDC-equiv is the right rank key,
   or switch to total LP depth added / mftUSD minted. USDC-equiv is most
   verifiable; LP depth is most "real" but harder to value.
2. **Trigger mode for v1**: ship `MANUAL` (anyone triggers, caller pays gas) or
   `SCHEDULE` (keeper needed)? Recommend MANUAL first.
3. **LP range strategy**: auto-managed range (admin sets tick range per band)
   vs auto-compact to current tick? Auto-compact is simpler but churns gas.
4. **Band token list**: which bands does the vault route to by default? All 14
   registered in CommissionBooth, or a curated subset? Need the band → token
   address → pool fee map from the MfT bands doc.
5. **Oracle for slippage bound**: TWAP via Uniswap V3 pool, or a Chainlink feed
   for USDC-equiv? TWAP is cheaper and self-contained.
6. **Revenue split**: keep 50/50 LP/ops to match CommissionBooth, or weight
   toward LP to deepen faster?

---

## 9. Build order (suggested)

1. Confirm all §3 addresses against current deployment state.
2. Implement `BnkrTreeFundingVault` with `MANUAL` trigger + single band (DD) as
   the first route. Get the end-to-end BNKR → LP path working.
3. Add `TreeFundingLeaderboard` + `TreeFunding` event. Wire vault → leaderboard.
4. Add multi-band support (band → token → pool fee map).
5. Off-chain indexer + public leaderboard UI.
6. v2: `SCHEDULE` keeper, auto-compact LP, proxy if needed.

---

## 10. Notes

- This is a design proposal from Bankr. Claude owns implementation review and
  any contract code. No contracts are deployed yet.
- All addresses are Base mainnet and must be re-verified before use.
- mftUSD is internal-only per the MfT routing policy — the vault must never
  expose it to users.
- The leaderboard is the gamification layer that makes other projects want to
  route through the vault. Design it asset-agnostic from day one.

— Bankr
