# BNKR Tree Escrow — Design Spec

> Drip-feed escrow for large USDC deposits into the BNKR Tree Funding Vault.
> Users commit capital upfront; the escrow splits it into slippage-safe chunks
> and drips one chunk every 30s. **User pays in TIME, not CAPITAL.**
>
> Status: v3 contract written (`contracts/BnkrTreeEscrowV3.sol`), not deployed.
> This spec is for review before deployment.
>
> **⚠️ CORRECTIONS PENDING — see the escrow-design review in `COORDINATION.md` (2026-07-18):**
> 1. **§8 + §10 USDC address is WRONG.** Real Base USDC = `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`. Do NOT deploy with the address currently in this doc.
> 2. **v3 has a double-refund bug** (`cancelDrip` → `claimShares`) — needs the v4 one-line fix (`cancelDrip` sets `d.drippedUSDC = d.totalUSDC`).
> 3. **REDIRECT (founder):** make the escrow **vault-agnostic** — one contract serving all 50+ `CommunityLPVault` clones (`createDrip(vault, amount)` + a bytecode whitelist against impl `0x3bb5f84c`). Update this doc when v4 lands.

---

## 1. Problem

The BNKR Tree Funding Vault (`0x3531...6AC5`, a `CommunityLPVaultV3` clone)
accepts USDC and routes it through the MfT flywheel:

```
USDC → MfT Aave vault (mint mftUSD) → BNKR/mftUSD LP deepen → trees funded
```

The vault has a `maxInstantDeposit()` guard — deposit too much at once and
slippage exceeds 5%, reverting the trade. This caps single deposits at roughly
$1–3 depending on pool depth.

Users who want to fund $50, $500, or $5,000 can't do it in one tx. They'd need
to manually call `deposit()` dozens of times, waiting 30s between each. That's
not a product — it's a chore.

## 2. Solution

**BnkrTreeEscrow** — a non-custodial escrow that:

1. Accepts a large USDC deposit from a user
2. Splits it into chunks sized at 90% of `maxInstantDeposit()` (scaled to 3% slippage)
3. Drips one chunk into the vault every 30s (keeper-triggered)
4. Accrues vault shares per-drip
5. Lets the depositor claim shares (withdrawn as USDC) or cancel mid-progress

The user signs one tx (`createDrip`), walks away, and comes back to claim their
vault position. The keeper (Bankr agent) calls `drip()` on a 30s loop.

## 3. Contract Evolution

### v1 (`BnkrTreeEscrow.sol`, 11.1KB)
- Single queue, escrow-total share accounting (`sharesAtStart`)
- `maxUint256` approval to vault
- Unbounded `rescue()`
- No reentrancy guard
- **Issues found in review**: share accounting broke with concurrent drips, max approval violated hard rules, rescue could drain depositors

### v2 (`BnkrTreeEscrowV2.sol`, 15.3KB)
- Per-drip share accounting (`sharesEarned` / `sharesClaimed`)
- Exact per-chunk USDC approval (no maxUint256)
- `rescue()` bounded by `totalCommittedUSDC` + one-way `renounceRescue()`
- `nonReentrant` on all state-changing fns
- `cancelDrip` requires `d.active` + CEI ordering
- **Issues found in review**: compile error (`_computeChunkSize()` called with no args), fund-lock on HELD drips (no recovery path)

### v3 (`BnkrTreeEscrowV3.sol`, 17.1KB) — CURRENT
- Fixes both v2 blockers:
  1. **Compile fix**: `_computeChunkSize(uint256 maxInstant)` now called with `VAULT.maxInstantDeposit()`
  2. **Fund-lock fix**: `claimShares` now refunds un-dripped USDC remainder alongside shares (HELD drips recoverable)
- All v2 safety features retained

## 4. v3 Architecture

### Roles
| Role | Address | Powers |
|---|---|---|
| KEEPER | Bankr agent wallet | Calls `drip()`, calls `rescue()` (bounded) |
| DEPOSITOR | Any user | `createDrip()`, `cancelDrip()`, `claimShares()` |

### Constants
| Constant | Value | Rationale |
|---|---|---|
| `DRIP_INTERVAL` | 30s | Matches vault cooldown |
| `MAX_SLIPPAGE_BPS` | 300 (3%) | Tighter than vault's 5% guard |
| `MAX_CHUNK_BPS` | 9000 (90%) | Safety margin under `maxInstantDeposit` |

### Drip Lifecycle
```
createDrip(usdcAmount)
  → transfers USDC from user to escrow
  → creates Drip struct (active=true)
  → emits DripCreated

drip(dripId) [keeper only, every 30s]
  → computes chunk = _computeChunkSize(maxInstant)
  → chunk = min(chunk, remaining)
  → exact-approve vault for chunk
  → VAULT.deposit(chunk)
  → sharesMinted accrue to d.sharesEarned
  → if drippedUSDC >= totalUSDC → active=false, emit DripCompleted
  → on slippage revert: retryCount++, 2 strikes → HELD (active=false)

cancelDrip(dripId) [depositor only]
  → returns remaining USDC + withdraws earned shares as USDC
  → CEI: sets active=false before external calls

claimShares(dripId) [depositor only, when !active]
  → withdraws earned shares from vault as USDC
  → ALSO refunds un-dripped USDC remainder (HELD recovery)
  → resets accounting
```

### Chunk Sizing
```
chunk = maxInstantDeposit × (MAX_SLIPPAGE_BPS / vaultImpactBps) × MAX_CHUNK_BPS / 10000
      = maxInstantDeposit × (300 / 500) × 0.9
      = maxInstantDeposit × 0.54
```
Scales dynamically as pool depth changes. Last chunk = remaining (if under maxSafe).

### Safety Features
- **Exact approval**: per-chunk `USDC.approve(vault, chunk)` — no lingering allowance
- **Bounded rescue**: `rescue()` can only withdraw up to `totalCommittedUSDC` (sum of remaining across active drips), never depositors' earned shares
- **renounceRescue()**: one-way lock, once called `rescue()` reverts forever
- **nonReentrant**: all state-changing functions
- **CEI pattern**: state updates before external calls in `cancelDrip` and `claimShares`
- **2-strike slippage**: 2 consecutive fails → HELD state, depositor can claim partial shares + refund

## 5. Integration with MfT Flywheel

The escrow sits upstream of the BNKR Tree Funding Vault:

```
User → BnkrTreeEscrow → (drip) → BNKR Tree Funding Vault → MfT Aave vault → mftUSD → BNKR/mftUSD V2 LP
```

### BNKR/mftUSD V2 Pool (from addendum)
- Pool: `0x1941201a37f5548dbe01e900f01b539f508f6cbf` (Uniswap V2)
- token0: $BNKR (`0x22af33fe49fd1fa80c7149773dde5890d3c76f3b`)
- token1: mftUSD (`0xe3dd3881477c20C17Df080cEec0C1bD0C065A072`)
- Reserves: ~44,862 BNKR / 15 mftUSD

The vault deepens this pool directly. Every drip → more LP → more trees funded.

### mftUSD Stays Internal
Per the MfT routing policy, mftUSD never touches user wallets. The escrow only
moves USDC in and vault shares out. Users see USDC in, USDC out.

## 6. Keeper Automation

The keeper (Bankr agent wallet) calls `drip()` on a loop. Design options:

### Option A: Bankr Automation (Recommended)
- Register a scheduled automation that calls `drip()` every 30s
- Agent scans for active drips, calls `drip(dripId)` for each
- Pros: no off-chain infra, uses existing Bankr automation stack
- Cons: 30s cadence may hit automation rate limits at scale

### Option B: Off-chain Keeper Script
- Lightweight script (Node/Python) with a funded wallet
- Polls for active drips, calls `drip()` every 30s
- Pros: precise timing, no rate limits
- Cons: separate infra to maintain

### Option C: Anyone-Can-Trigger (Future v2)
- Open `drip()` to anyone, add gas bounty (small USDC from drip)
- Pros: decentralized, self-sustaining
- Cons: adds complexity, bounty accounting

**Recommendation**: Start with Option A (Bankr automation) for v1. Move to
Option C in v2 once the escrow is battle-tested.

## 7. Open Design Decisions

### 7.1 Concurrent Drips
v3 has a global cooldown (`lastGlobalDrip`) — one drip every 30s across ALL drips.
With 10 active drips, each drip runs every 300s (5 min). For a $50 deposit at
$1/chunk, that's 50 chunks × 5 min = ~4 hours.

**Options**:
- Keep global cooldown (simple, fair, slow at scale)
- Per-drip cooldown only (faster, but multiple drips hit vault in same block)
- Weighted round-robin (proportional to deposit size)

**Recommendation**: Keep global cooldown for v1. Revisit when concurrent drip
count exceeds ~5.

### 7.2 Min/Max Deposit
No min/max in v3. A $0.01 deposit wastes gas on a drip. A $100K deposit takes
days to complete.

**Recommendation**: Add `MIN_DEPOSIT = $1` (1 USDC) and `MAX_DEPOSIT = $10,000`
(10,000 USDC) as configurable constants. Max protects against griefing via
queue saturation.

### 7.3 Deposit Fee / Gas Bounty
v3 has no fee. The keeper pays gas for every `drip()` call with no compensation.

**Options**:
- No fee (v1, keeper subsidizes)
- Small gas bounty per drip (e.g., $0.01 USDC from deposit)
- Deposit-time fee (e.g., 0.5% of total, goes to keeper)

**Recommendation**: Add a 0.5% deposit-time fee in v2, routed to keeper wallet.
v1: no fee, Bankr subsidizes keeper gas.

### 7.4 HELD Drip Recovery
v3 fixes the fund-lock: `claimShares` returns shares + un-dripped USDC. But the
depositor must manually call `claimShares` — there's no auto-refund.

**Options**:
- Manual claim (v3, current)
- Auto-refund after 24h in HELD state
- Keeper triggers refund

**Recommendation**: Manual claim for v1. Add auto-refund timer in v2.

### 7.5 Proxy / Upgradeability
v3 is not upgradeable. If a bug is found post-deploy, funds are stuck.

**Options**:
- No proxy (v3, immutable)
- UUPS proxy (upgradeable, admin-gated)
- Beacon proxy (factory pattern for multiple escrows)

**Recommendation**: Deploy v3 immutable for v1. If it works for 30 days with
real deposits, deploy a v2 with UUPS proxy. Immutability is a feature for
custodial contracts — users trust it more.

## 8. Deployment Plan

### Phase 1: Deploy v3 (Current)
1. Verify all addresses against current chain state:
   - BNKR Tree Funding Vault: `0x3531...6AC5`
   - USDC on Base: `0x833589fCD6eDb6E08f4c7C32D4f71c54b7770845`
   - Keeper: Bankr agent wallet
2. Deploy `BnkrTreeEscrowV3` with verified params
3. Test with $1 USDC deposit → verify drip → verify claim
4. Register Bankr automation for `drip()` loop
5. `renounceRescue()` after first successful withdrawal

### Phase 2: Productize
1. Add min/max deposit guards
2. Build depositor UI (create drip, view progress, claim)
3. Build keeper dashboard (active drips, queue depth, gas spend)
4. Index `DripCreated` / `DripExecuted` / `DripCompleted` events for UI

### Phase 3: v2 Contract
1. Gas bounty / deposit fee
2. Auto-refund for HELD drips
3. UUPS proxy (if immutability trust established)
4. Anyone-can-trigger `drip()` with bounty
5. Multi-vault support (escrow routes to multiple tree funding vaults)

## 9. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Vault `deposit()` reverts on every chunk | Medium | 2-strike → HELD, depositor claims refund |
| Keeper goes offline | Medium | Drips pause, no funds lost, any funded wallet can be rotated |
| `maxInstantDeposit()` returns 0 | Low | `drip()` reverts cleanly, no silent 0-drip |
| USDC depegs | Low | Escrow holds USDC, not LP tokens — depositor gets USDC back |
| Reentrancy via vault callback | Low | `nonReentrant` on all fns, CEI pattern |
| Rescue abuse | Low | Bounded by `totalCommittedUSDC`, `renounceRescue()` one-way lock |
| Share accounting drift | Low | Per-drip `sharesEarned` — no escrow-total dependency |

## 10. Address Reference (Base Mainnet)

| Contract | Address | Status |
|---|---|---|
| BNKR Tree Funding Vault | `0x3531...6AC5` | Deployed, $1 test deposit done |
| MfT Aave Vault (mftUSD) | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` | Deployed, live |
| BNKR/mftUSD V2 Pool | `0x1941201a37f5548dbe01e900f01b539f508f6cbf` | Deployed, live |
| $BNKR | `0x22af33fe49fd1fa80c7149773dde5890d3c76f3b` | Deployed |
| USDC (Base) | `0x833589fCD6eDb6E08f4c7C32D4f71c54b7770845` | Deployed |
| CommissionBooth | `0xC094664560024e77A710B80D08d15B15EDE0a4a7` | Deployed, live |
| BnkrTreeEscrowV3 | — | Not deployed |

---

*Authored by Bankr. Review requested before deployment.*
