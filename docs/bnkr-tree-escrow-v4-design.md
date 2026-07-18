# BNKR Tree Escrow V4 — Design Spec

> Drip-feed escrow for large USDC deposits into any CommunityLPVaultV3 clone.
> Users commit capital upfront; the escrow splits it into slippage-safe chunks
> and drips one chunk every 30s. **User pays in TIME, not CAPITAL.**
>
> Status: v4 contract written (`contracts/BnkrTreeEscrowV4.sol`), not deployed.
> This spec is for review before deployment.
>
> **v4 supersedes v3.** Changes: vault-agnostic architecture, double-refund fix,
> min/max deposit guards, per-vault drip tracking.

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

**Additional problem (v4)**: There are 50+ `CommunityLPVaultV3` clones (one per
band, plus BNKR tree vault). v3 was hardcoded to a single vault. v4 makes the
escrow vault-agnostic — one contract serves all of them.

## 2. Solution

**BnkrTreeEscrowV4** — a non-custodial, vault-agnostic escrow that:

1. Accepts a large USDC deposit from a user, targeting a whitelisted vault
2. Splits it into chunks sized at 90% of `maxInstantDeposit()` (scaled to 3% slippage)
3. Drips one chunk into the vault every 30s (keeper-triggered)
4. Accrues vault shares per-drip
5. Lets the depositor claim shares (withdrawn as USDC) or cancel mid-progress

The user signs one tx (`createDrip(vault, amount)`), walks away, and comes back
to claim their vault position. The keeper (Bankr agent) calls `drip()` on a 30s loop.

## 3. Contract Evolution

### v1 (`BnkrTreeEscrow.sol`, 11.1KB)
- Single queue, escrow-total share accounting (`sharesAtStart`)
- `maxUint256` approval to vault
- Unbounded `rescue()`
- No reentrancy guard
- **Issues**: share accounting broke with concurrent drips, max approval violated hard rules, rescue could drain depositors

### v2 (`BnkrTreeEscrowV2.sol`, 15.3KB)
- Per-drip share accounting (`sharesEarned` / `sharesClaimed`)
- Exact per-chunk USDC approval (no maxUint256)
- `rescue()` bounded by `totalCommittedUSDC` + one-way `renounceRescue()`
- `nonReentrant` on all state-changing fns
- `cancelDrip` requires `d.active` + CEI ordering
- **Issues**: compile error (`_computeChunkSize()` called with no args), fund-lock on HELD drips (no recovery path)

### v3 (`BnkrTreeEscrowV3.sol`, 17.1KB)
- Fixes both v2 blockers:
  1. **Compile fix**: `_computeChunkSize(uint256 maxInstant)` now called with `VAULT.maxInstantDeposit()`
  2. **Fund-lock fix**: `claimShares` now refunds un-dripped USDC remainder alongside shares (HELD drips recoverable)
- All v2 safety features retained
- **Issues found in review**:
  1. Double-refund bug: `cancelDrip` returns `remainingUSDC` and sets `active=false` but does NOT set `d.drippedUSDC = d.totalUSDC`. Then `claimShares` sees `!active`, `sharesToReturn=0`, but `remainingUSDC = totalUSDC - drippedUSDC` is still the original amount → refunds remaining USDC a second time.
  2. Hardcoded to single vault — cannot serve the 50+ CommunityLPVaultV3 clones.
  3. No min/max deposit guards.

### v4 (`BnkrTreeEscrowV4.sol`) — CURRENT
- **Vault-agnostic**: `createDrip(address vault, uint256 amount)` + admin-managed whitelist (`whitelistedVaults(address) → bool`). One escrow serves all CommunityLPVaultV3 clones.
- **Double-refund fix**: `cancelDrip` now sets `d.drippedUSDC = d.totalUSDC` after returning remaining USDC, preventing `claimShares` from refunding again.
- **Min/max deposit guards**: `MIN_DEPOSIT = 1 USDC`, `MAX_DEPOSIT = 10,000 USDC`.
- **Per-vault drip tracking**: each drip records its target vault; `drip()` reads `maxInstantDeposit()` and `impactBps()` from the drip's vault.
- All v3 safety features retained: exact approval, bounded rescue, `renounceRescue`, `nonReentrant`, CEI, 2-strike slippage.

## 4. v4 Architecture

### Roles
| Role | Address | Powers |
|---|---|---|
| KEEPER | Bankr agent wallet | Calls `drip()`, calls `rescue()` (bounded) |
| ADMIN | Deployer / governance | `setVaultWhitelist()`, `renounceRescue()` |
| DEPOSITOR | Any user | `createDrip()`, `cancelDrip()`, `claimShares()` |

### Constants
| Constant | Value | Rationale |
|---|---|---|
| `DRIP_INTERVAL` | 30s | Matches vault cooldown |
| `MAX_SLIPPAGE_BPS` | 300 (3%) | Tighter than vault's 5% guard |
| `MAX_CHUNK_BPS` | 9000 (90%) | Safety margin under `maxInstantDeposit` |
| `MIN_DEPOSIT` | 1 USDC (1e6) | Gas-efficient minimum |
| `MAX_DEPOSIT` | 10,000 USDC (10,000e6) | Anti-griefing / queue saturation |
| `MAX_CONCURRENT_DRIPS` | 20 | Queue depth cap |
| `SLIPPAGE_STRIKES` | 2 | Tolerance before HELD state |

### Vault Whitelist
Admin calls `setVaultWhitelist(vault, true)` for each CommunityLPVaultV3 clone.
`createDrip` reverts with `VaultNotWhitelisted` if the vault isn't whitelisted.

**Whitelist verification**: Before whitelisting, verify the vault's runtime
bytecode hash matches the canonical `CommunityLPVaultV3` implementation
(`0x3bb5f84c...`). This prevents malicious contracts from being whitelisted.

### Drip Lifecycle
```
createDrip(vault, usdcAmount)
  → validates vault whitelist + min/max deposit
  → transfers USDC from user to escrow
  → creates Drip struct (active=true, vault recorded)
  → emits DripCreated

drip(dripId) [keeper only, every 30s]
  → reads maxInstantDeposit() + impactBps() from drip's vault
  → computes chunk = _computeChunkSize(maxInstant, impactBps)
  → chunk = min(chunk, remaining)
  → exact-approve vault for chunk
  → vault.deposit(chunk)
  → sharesMinted accrue to d.sharesEarned
  → if drippedUSDC >= totalUSDC → active=false, emit DripCompleted
  → on slippage revert: retryCount++, 2 strikes → HELD (active=false)

cancelDrip(dripId) [depositor only]
  → returns remaining USDC + withdraws earned shares as USDC
  → CEI: sets active=false, drippedUSDC=totalUSDC BEFORE external calls
  → ← v4 FIX: drippedUSDC=totalUSDC prevents double-refund in claimShares

claimShares(dripId) [depositor only, when !active]
  → withdraws earned shares from vault as USDC
  → ALSO refunds un-dripped USDC remainder (HELD recovery)
  → resets accounting (sharesClaimed=sharesEarned, drippedUSDC=totalUSDC)
```

### Chunk Sizing
```
chunk = maxInstantDeposit × (MAX_SLIPPAGE_BPS / vaultImpactBps) × MAX_CHUNK_BPS / 10000
      = maxInstantDeposit × (300 / 500) × 0.9
      = maxInstantDeposit × 0.54
```
Scales dynamically per-vault as pool depth changes. Last chunk = remaining
(if under maxSafe).

### Safety Features
- **Exact approval**: per-chunk `USDC.approve(vault, chunk)` — no lingering allowance
- **Bounded rescue**: `rescue()` can only withdraw up to `totalCommittedUSDC` (sum of remaining across active drips), never depositors' earned shares
- **renounceRescue()**: one-way lock, once called `rescue()` reverts forever
- **nonReentrant**: all state-changing functions (transient storage)
- **CEI pattern**: state updates before external calls in `cancelDrip` and `claimShares`
- **2-strike slippage**: 2 consecutive fails → HELD state, depositor can claim partial shares + refund
- **Vault whitelist**: only admin-whitelisted CommunityLPVaultV3 clones accepted
- **Min/max deposit**: prevents dust griefing and queue saturation

## 5. Double-Refund Bug Analysis (v3 → v4 Fix)

### The Bug (v3)
```
cancelDrip(dripId):
  remainingUSDC = totalUSDC - drippedUSDC    // e.g., 50 - 10 = 40
  d.active = false
  // ← MISSING: d.drippedUSDC = d.totalUSDC
  USDC.transfer(depositor, remainingUSDC)    // sends 40 USDC
  withdraw earned shares...

claimShares(dripId):                         // called later
  !d.active ✓
  sharesToReturn = sharesEarned - sharesClaimed  // 0 (already claimed in cancel)
  remainingUSDC = totalUSDC - drippedUSDC    // 50 - 10 = 40 (still original!)
  // refunds 40 USDC AGAIN → double-refund
```

### The Fix (v4)
```
cancelDrip(dripId):
  remainingUSDC = totalUSDC - drippedUSDC
  d.active = false
  d.drippedUSDC = d.totalUSDC                // ← v4 FIX
  USDC.transfer(depositor, remainingUSDC)
  withdraw earned shares...

claimShares(dripId):
  remainingUSDC = totalUSDC - drippedUSDC    // 50 - 50 = 0 ✓
  // no double-refund
```

## 6. Integration with MfT Flywheel

The escrow sits upstream of any CommunityLPVaultV3 clone:

```
User → BnkrTreeEscrowV4 → (drip) → CommunityLPVaultV3 → MfT Aave vault → mftUSD → band/BNKR LP
```

### BNKR Tree Funding Vault (primary target)
- Vault: `0x3531...6AC5` (CommunityLPVaultV3 clone)
- Routes to: MfT Aave vault → BNKR/mftUSD V2 LP

### BNKR/mftUSD V2 Pool
- Pool: `0x1941201a37f5548dbe01e900f01b539f508f6cbf` (Uniswap V2)
- token0: $BNKR (`0x22af33fe49fd1fa80c7149773dde5890d3c76f3b`)
- token1: mftUSD (`0xe3dd3881477c20C17Df080cEec0C1bD0C065A072`)
- Reserves: ~44,862 BNKR / 15 mftUSD

### mftUSD Stays Internal
Per the MfT routing policy, mftUSD never touches user wallets. The escrow only
moves USDC in and vault shares out. Users see USDC in, USDC out.

## 7. Keeper Automation

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

### Option C: Anyone-Can-Trigger (Future v5)
- Open `drip()` to anyone, add gas bounty (small USDC from drip)
- Pros: decentralized, self-sustaining
- Cons: adds complexity, bounty accounting

**Recommendation**: Start with Option A (Bankr automation) for v1. Move to
Option C in v5 once the escrow is battle-tested.

## 8. Open Design Decisions

### 8.1 Concurrent Drips
v4 retains the global cooldown (`lastGlobalDrip`) — one drip every 30s across ALL drips.
With 10 active drips, each drip runs every 300s (5 min). For a $50 deposit at
$1/chunk, that's 50 chunks × 5 min = ~4 hours.

**Options**:
- Keep global cooldown (simple, fair, slow at scale)
- Per-drip cooldown only (faster, but multiple drips hit vault in same block)
- Weighted round-robin (proportional to deposit size)

**Recommendation**: Keep global cooldown for v1. Revisit when concurrent drip
count exceeds ~5.

### 8.2 Deposit Fee / Gas Bounty
v4 has no fee. The keeper pays gas for every `drip()` call with no compensation.

**Options**:
- No fee (v1, keeper subsidizes)
- Small gas bounty per drip (e.g., $0.01 USDC from deposit)
- Deposit-time fee (e.g., 0.5% of total, goes to keeper)

**Recommendation**: Add a 0.5% deposit-time fee in v5, routed to keeper wallet.
v1: no fee, Bankr subsidizes keeper gas.

### 8.3 HELD Drip Recovery
v4 retains manual claim: `claimShares` returns shares + un-dripped USDC. But the
depositor must manually call `claimShares` — there's no auto-refund.

**Options**:
- Manual claim (v4, current)
- Auto-refund after 24h in HELD state
- Keeper triggers refund

**Recommendation**: Manual claim for v1. Add auto-refund timer in v5.

### 8.4 Proxy / Upgradeability
v4 is not upgradeable. If a bug is found post-deploy, funds are stuck.

**Options**:
- No proxy (v4, immutable)
- UUPS proxy (upgradeable, admin-gated)
- Beacon proxy (factory pattern for multiple escrows)

**Recommendation**: Deploy v4 immutable for v1. If it works for 30 days with
real deposits, deploy a v5 with UUPS proxy. Immutability is a feature for
custodial contracts — users trust it more.

### 8.5 Vault Whitelist Management
Admin must whitelist each CommunityLPVaultV3 clone before users can drip into it.

**Options**:
- Manual whitelist (v4, current) — admin calls `setVaultWhitelist` per vault
- Bytecode hash verification — auto-whitelist if runtime bytecode matches canonical impl
- Factory integration — escrow listens to vault factory events

**Recommendation**: Manual whitelist for v1. Add bytecode hash auto-verification
in v5 to reduce admin overhead.

## 9. Deployment Plan

### Phase 1: Deploy v4 (Current)
1. Verify all addresses against current chain state:
   - BNKR Tree Funding Vault: `0x3531...6AC5`
   - USDC (Base): `0x833589fCD6eDb6E08f4c7C32D4f71c54b7770845`
   - Keeper: Bankr agent wallet
   - Admin: deployer or governance multisig
2. Deploy `BnkrTreeEscrowV4` with verified params
3. Admin calls `setVaultWhitelist(BNKR_TREE_VAULT, true)`
4. Test with $1 USDC deposit → verify drip → verify claim
5. Register Bankr automation for `drip()` loop
6. `renounceRescue()` after first successful withdrawal

### Phase 2: Productize
1. Whitelist additional CommunityLPVaultV3 clones (band vaults)
2. Build depositor UI (create drip, select vault, view progress, claim)
3. Build keeper dashboard (active drips, queue depth, gas spend)
4. Index `DripCreated` / `DripExecuted` / `DripCompleted` events for UI

### Phase 3: v5 Contract
1. Gas bounty / deposit fee
2. Auto-refund for HELD drips
3. UUPS proxy (if immutability trust established)
4. Anyone-can-trigger `drip()` with bounty
5. Bytecode hash auto-whitelist for vaults

## 10. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Vault `deposit()` reverts on every chunk | Medium | 2-strike → HELD, depositor claims refund |
| Keeper goes offline | Medium | Drips pause, no funds lost, any funded wallet can be rotated |
| `maxInstantDeposit()` returns 0 | Low | `drip()` reverts cleanly, no silent 0-drip |
| USDC depegs | Low | Escrow holds USDC, not LP tokens — depositor gets USDC back |
| Reentrancy via vault callback | Low | `nonReentrant` on all fns, CEI pattern |
| Rescue abuse | Low | Bounded by `totalCommittedUSDC`, `renounceRescue()` one-way lock |
| Share accounting drift | Low | Per-drip `sharesEarned` — no escrow-total dependency |
| Malicious vault whitelisted | Medium | Admin must verify bytecode hash before whitelisting |
| Double-refund (v3 bug) | Fixed | v4 sets `drippedUSDC = totalUSDC` in `cancelDrip` |
| Queue saturation griefing | Low | `MAX_CONCURRENT_DRIPS = 20` + `MAX_DEPOSIT = 10,000 USDC` |

## 11. Address Reference (Base Mainnet)

| Contract | Address | Status |
|---|---|---|
| BNKR Tree Funding Vault | `0x3531...6AC5` | Deployed, $1 test deposit done |
| MfT Aave Vault (mftUSD) | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` | Deployed, live |
| BNKR/mftUSD V2 Pool | `0x1941201a37f5548dbe01e900f01b539f508f6cbf` | Deployed, live |
| $BNKR | `0x22af33fe49fd1fa80c7149773dde5890d3c76f3b` | Deployed |
| USDC (Base) | `0x833589fCD6eDb6E08f4c7C32D4f71c54b7770845` | Deployed |
| CommissionBooth | `0xC094664560024e77A710B80D08d15B15EDE0a4a7` | Deployed, live |
| BnkrTreeEscrowV4 | — | Not deployed |

---

*Authored by Bankr. v4 supersedes v3. Review requested before deployment.*
