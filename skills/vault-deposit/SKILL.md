# Vault Deposit — handle ANY size, including over-slippage

**Use this whenever depositing USDC into a CommunityLPVault clone.** A plain `deposit()` of a large amount REVERTS ("price impact too high"). The vault has a NATIVE queue for big deposits — use it. No separate contract needed.

## ⭐ STOP-GAP — do THIS (simple, never reverts). The vaults are SMALL — a deposit bigger than the cap reverts.
When a user asks to deposit `$X` into a vault, do exactly this:
1. **Input must be USDC.** If they sent ETH or any other token, swap it to USDC first (the vault only accepts USDC) — or, if you can't swap, tell them to send USDC and stop.
2. **Read `maxInstantDeposit()`** → call it `M` (6-dec USDC; e.g. `1213826` = $1.21).
3. **Deposit only what fits, floored to a whole dollar:** `amount = min($X, floor(M to whole USDC))` (M=$1.21 → deposit **$1**; M=$5.80 → $5). Then `USDC.approve(vault, amount)` → `vault.deposit(amount)`. Because `amount ≤ M`, this **ALWAYS fits — never reverts.**
4. **If you capped it, tell them why:** *"This tree vault is small, so it only had room for $Y right now — I deposited $Y (the rest is still yours). The cap grows as more people add to it."*
**NEVER call `deposit()` with more than `floor(maxInstantDeposit())`** — that over-cap call is the "simulation reverted" every deposit hit. Taking only what fits is the whole fix. (The `depositQueued()` path below meters the FULL amount in over time — use it only when you specifically want to force a big deposit in; the stop-gap above is the default.)

## The vault's deposit functions (all on the vault itself)
| function | what it does |
|---|---|
| `maxInstantDeposit()` view | biggest USDC you can `deposit()` in ONE shot right now (grows as the pool deepens) |
| `deposit(usdcAmount)` | INSTANT. Only works if `usdcAmount ≤ maxInstantDeposit()`, else **reverts** |
| `depositQueued(usdcAmount)` | QUEUE any size — parks the USDC in the vault (no LP yet). Never reverts on size |
| `processDeposit(user, chunk)` | **PUBLIC — anyone can call.** Turns a safe-sized `chunk` of `user`'s queued USDC into LP; shares go to `user`. Call repeatedly until their queue is empty |
| `cancelDeposit(usdcAmount)` | depositor pulls back un-processed USDC |
| `pendingDeposit(user)` view | how much of `user`'s queue is left to process |
| `shares(user)` view | the user's LP shares |

## The rule (memorize this)
1. Read `maxInstantDeposit()`.
2. **amount ≤ it** → `USDC.approve(vault, amount)` then `vault.deposit(amount)`. Instant, done.
3. **amount > it** → `USDC.approve(vault, amount)` then `vault.depositQueued(amount)`. Then meter it in: loop `vault.processDeposit(user, chunk)` where `chunk ≈ maxInstantDeposit() × 0.9`, **re-reading `maxInstantDeposit()` each round**, pacing **~30s between rounds** (lets arbs re-balance the pool so the price doesn't run), until `pendingDeposit(user) == 0`.

## The tool (does all of the above automatically)
```
npm install ethers          # once
DEPOSITOR_PRIVATE_KEY=0x…  node skills/vault-deposit/vault-deposit.cjs <vaultAddr> <usdcAmount_6dec>
```
- amount fits → instant `deposit()`.
- amount too big → `depositQueued()` + metered `processDeposit()` loop (30s pacing, auto chunk-sizing, halves the chunk + retries if a chunk still hits the impact cap).

## Key facts
- **`processDeposit` is PUBLIC** — a separate bot can process ANYONE's queued deposit (the "public button"). Nobody's funds are at risk: `processDeposit` only advances a deposit the user already queued; it can't move USDC anywhere but into the user's own LP position.
- **DON'T** call `deposit()` with a big amount (reverts) — always check `maxInstantDeposit()` first.
- **DON'T** process a chunk bigger than `maxInstantDeposit()` (reverts on impact).
- Works on ALL 17 vaults (same impl `0x3bb5f84c`), e.g. the BNKR-for-Trees vault `0x3531780Bc106bA69897b4CB3D0a0A6E44F436AC5`.
