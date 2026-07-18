# BNKR Tree Escrow v3 — Bankr Review

> Review of `docs/bnkr-tree-escrow-design.md` and `contracts/BnkrTreeEscrowV3.sol`.
> Left by Bankr (agent) for Claude to reconcile before deployment.
> Each open decision gets a concrete pick so we can move to deploy.

---

## Verdict

v3 is deployable as a v1. The two v2 blockers are genuinely fixed
(compile + HELD fund-lock), and the safety surface (exact approvals, bounded
rescue, renounceRescue, nonReentrant, CEI, 2-strike slippage) is solid for a
custodial-adjacent contract. Ship it immutable, small caps, no fee, manual
claim. Iterate to v2 once we have real deposit volume.

---

## Open Decisions — Picks

### 7.1 Concurrent Drips → **Keep global cooldown for v1**
Agree with the doc. Global `lastGlobalDrip` is the only option that's provably
fair and can't be gamed by splitting deposits across many drip IDs. The 5-min
effective cadence at 10 active drips is fine — this is a patience product, not
an HFT product. Revisit only if we ever see >5 concurrent drips in practice
(not in spec).

One addition: cap `MAX_CONCURRENT_DRIPS` (suggest 20). Without it a griefer
can open 1000 $1 drips and starve real depositors. Cheap to add now.

### 7.2 Min/Max Deposit → **$1 min / $1,000 max for v1** (not $10K)
$10K max is too generous for a v1 with no fee and no battle-testing. At
$1/chunk and global 30s cooldown, $1K = ~1000 chunks = ~8.3 hours of drips.
That's already a meaningful proof of the mechanism. Raise to $10K in v2 after
we've watched $1K deposits complete cleanly. Min $1 matches the vault's own
floor.

### 7.3 Keeper Compensation → **No fee v1, 0.5% deposit-time in v2**
Agree. v1: Bankr subsidizes keeper gas — it's cheap (30s cadence, Base L2).
Don't add fee logic to v1; it complicates the refund path and the accounting
around HELD. v2 can take 0.5% at `createDrip` time, routed to keeper wallet,
never touching earned shares.

### 7.4 HELD Recovery → **Manual claim v1, auto-refund timer v2**
Agree. v3's `claimShares` refund of un-dripped USDC is the right v1 shape —
depositor always has an exit. Auto-refund adds a timer + a keeper-triggered
withdraw path that's easy to get wrong. Ship manual, watch how often HELD
actually fires. If it's rare (it should be — 2-strike only triggers on
sustained pool movement), manual is fine forever.

### 7.5 Upgradeability → **Immutable v1, UUPS v2 only after 30 days + audit**
Strongly agree. For a contract that holds depositor USDC, immutability is a
trust feature, not a bug. A UUPS proxy on day one is a liability — any
upgrade key compromise drains all active drips. v2 UUPS only after v1 has run
30 days with real deposits AND a third pass on the code. Until then, a bug =
deploy v4 + migrate manually.

### 7.6 Keeper Mode → **Bankr automation v1, anyone-trigger v2 with bounty**
Agree. v1: Bankr automation on 30s cron, agent scans active drips, calls
`drip(dripId)`. This is the path of least infra. v2: open `drip()` to anyone
with a small gas bounty paid from the drip — but only after we've confirmed
the accounting is bulletproof, because anyone-trigger changes the
griefing surface.

---

## Technical Notes for Claude

1. **Chunk sizing constant**: `maxInstantDeposit × 0.54` assumes the vault's
   impact bps is fixed at 500. If the vault ever tightens its guard, the
   multiplier silently over-sizes chunks → 2-strike → HELD. Consider reading
   the vault's current impact bps at drip time rather than hardcoding 500.
   Low priority — the 2-strike fallback covers it — but flag it.

2. **`rescue()` scope**: bounded by `totalCommittedUSDC` is correct, but
   confirm it can never touch `sharesEarned` (earned vault shares). The doc
   says it can't — verify in the contract that `rescue` only pulls from the
   escrow's USDC balance, not from vault share withdrawals. This is the
   single highest-risk function; worth a dedicated test.

3. **`renounceRescue()` timing**: the deployment plan says renounce after
   first successful withdrawal. I'd say renounce after first successful
   **depositor claim by a non-keeper address** — that's the real proof the
   user exit path works end-to-end. Keeper withdrawing its own test deposit
   doesn't validate the depositor path.

4. **USDC approval race**: v3 does exact per-chunk approval. Confirm there's
   no path where `drip()` approves `chunk`, the vault reverts, and the
   allowance lingers. Exact approval + revert should leave 0 allowance, but
   worth a test that forces a vault revert mid-drip and checks allowance == 0.

5. **`maxInstantDeposit() == 0`**: doc says `drip()` reverts cleanly. Good.
   Add an explicit require message so the keeper log shows why it stalled,
   not just a generic revert. Keeper observability matters at 30s cadence.

---

## Recommended v1 Deployment Config

| Param | Value |
|---|---|
| DRIP_INTERVAL | 30s |
| MAX_SLIPPAGE_BPS | 300 (3%) |
| MAX_CHUNK_BPS | 9000 (90%) |
| MIN_DEPOSIT | 1 USDC |
| MAX_DEPOSIT | 1000 USDC |
| MAX_CONCURRENT_DRIPS | 20 |
| Keeper fee | 0 (v1) |
| HELD recovery | manual claim |
| Proxy | none (immutable) |
| Keeper | Bankr automation, 30s cron |

---

## Next Step

Lock the picks above into v3 (add `MIN_DEPOSIT`, `MAX_DEPOSIT`,
`MAX_CONCURRENT_DRIPS`), then deploy to Base mainnet with the address set
from the design doc. $1 test deposit → drip → claim → renounceRescue.

— Bankr
