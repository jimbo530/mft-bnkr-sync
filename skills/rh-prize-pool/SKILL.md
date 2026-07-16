---
name: rh-prize-pool
description: Deploy a PrizePool on Robinhood Chain (4663), fund it with USDG, register achievements, and claim prizes for NFT holders. Use when the user wants to deploy an achievement prize pool, fund a prize pool with USDG, add an achievement, attest NFT eligibility, or claim a USDG prize for an NFT they hold. The pool is add-only — admin cannot withdraw; USDG only ever leaves via claim() to verified NFT owners.
---

# RH Prize Pool — USDG Achievement Prizes on Robinhood Chain

Deploy **PrizePool** on Robinhood Chain (4663) to hold USDG and pay it out
for configurable, extensible achievements tied to NFT ownership. Admin can
add achievements and attest eligibility but **can never withdraw USDG** — the
only exit is `claim()` which pays the NFT's current live owner.

> **Function names below are grounded in PrizePool.sol and PrizePool-abi.json.**
> Every signature was read from both sources — nothing is invented.

## Contract addresses (chain 4663)

| Role | Address |
|------|---------|
| USDG (prize token) | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` |
| PrizePool | `FILL_AFTER_DEPLOY` |

## Step 1 — Deploy PrizePool

Constructor takes two arguments:

```solidity
constructor(address _cbBtc, address _admin)
```

Despite the parameter name `_cbBtc` in the source (ported from the Base version
that uses cbBTC), pass **USDG** as `_cbBtc` for the Robinhood Chain deploy.
The variable is `IERC20 public immutable cbBtc` in the source but holds USDG on RH.

Recommended args for the RH deploy (grounded from FOR-BNKR.txt):
- `_cbBtc` (prize token): `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` (USDG)
- `_admin`: `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10` (agent wallet, or your address)

Pre-built deploy payload is in `references/deploy-data.md`. No additional encoding
needed — paste bytecode + constructor args concatenated.

## Step 2 — Fund the pool

Anyone can fund (permissionless). Two-step: approve USDG to the pool, then call `fund`.

```solidity
// On USDG (0x5fc5360D…): approve pool to spend
approve(address spender, uint256 amount)

// On PrizePool:
function fund(uint256 amount) external
```

- Pulls `amount` USDG from `msg.sender` via `transferFrom`.
- Emits `Funded(from, amount)`.
- Increments `totalFunded` (telemetry only).
- There is **no admin withdrawal path**. USDG that enters can only leave via `claim()`.

## Step 3 — Add an achievement (admin only)

```solidity
function addAchievement(
    uint256 id,
    RewardType rewardType,     // 0=FIXED, 1=BPS_OF_POOL
    uint256 amountOrBps,       // USDG amount (FIXED) or bps 1-10000 (BPS_OF_POOL)
    EligMode eligMode,         // 0=ONCHAIN, 1=ADMIN_ATTESTED
    bool oneTimePerNFT,        // true = each (collection,tokenId) claims once only
    uint8 tierTag,             // display/grouping tag (e.g. 1=Mayor ... 5=Emperor)
    address condition,         // ONCHAIN: IOnchainCondition adapter address; ADMIN_ATTESTED: address(0)
    uint256 threshold          // ONCHAIN: threshold value; ADMIN_ATTESTED: ignored
) external onlyAdmin
```

- `id` is admin-chosen (allows the game to assign meaning, e.g. 1001=Guard-the-Port Mayor).
- Add-only: each `id` can be configured only once.
- Admin **cannot** change an existing achievement's economics after adding — only pause it.
- Emits `AchievementAdded(id, rewardType, amountOrBps, eligMode, oneTimePerNFT, tierTag, condition, threshold)`.

**RewardType values:**
- `0` (FIXED): pays exactly `amountOrBps` USDG per eligible claim.
- `1` (BPS_OF_POOL): pays `pool_balance * amountOrBps / 10000` USDG (dynamic share).

**EligMode values:**
- `0` (ONCHAIN): calls `IOnchainCondition(condition).meets(collection, tokenId, threshold)`.
- `1` (ADMIN_ATTESTED): admin pre-registers eligibility via `attest()`.

## Step 4 — Attest NFT eligibility (admin only, ADMIN_ATTESTED mode)

```solidity
// Single NFT
function attest(
    uint256 id,
    address collection,
    uint256 tokenId,
    bool eligible
) external onlyAdmin

// Batch (gas-efficient for contest winners)
function attestMany(
    uint256 id,
    address collection,
    uint256[] calldata tokenIds,
    bool eligible
) external onlyAdmin
```

- Emits `Attested(id, collection, tokenId, eligible)` per NFT.
- Grants or revokes eligibility before any `claim()` is made.
- Attestation is consumed on claim (requires fresh attest for repeat claims).

## Step 5 — Claim a prize

```solidity
function claim(
    uint256 achievementId,
    address collection,
    uint256 tokenId
) external
```

- Anyone may call (permissionless). The USDG reward **always goes to `ownerOf(tokenId)`**
  resolved live — not to the caller.
- For `oneTimePerNFT=true` achievements, only the current NFT owner may call
  (prevents griefing that would lock the owner out of a one-time prize).
- Reverts if: not eligible, already claimed, achievement paused, or pool underfunded.
- Emits `Claimed(achievementId, collection, tokenId, recipient, amount)`.

## Pause / unpause an achievement (admin only)

```solidity
function setAchievementActive(uint256 id, bool active) external onlyAdmin
```

Stops or resumes new claims. Cannot move USDG — only gates the claim path.
Emits `AchievementActiveSet(id, active)`.

## Read-only queries

```solidity
function cbBtc() external view returns (address)          // the USDG address on RH
function admin() external view returns (address)
function poolBalance() external view returns (uint256)    // live USDG balance
function totalFunded() external view returns (uint256)    // cumulative funded
function totalPaidOut() external view returns (uint256)   // cumulative paid
function totalClaims() external view returns (uint256)    // cumulative claims
function BPS_DENOM() external view returns (uint256)      // 10000

function achievements(uint256 id) external view returns (
    bool exists, bool active, uint8 rewardType, uint256 amountOrBps,
    uint8 eligMode, bool oneTimePerNFT, uint8 tierTag,
    address condition, uint256 threshold
)
function rewardAmount(uint256 achievementId) external view returns (uint256)
function hasClaimed(uint256 achievementId, address collection, uint256 tokenId) external view returns (bool)
function isEligible(uint256 achievementId, address collection, uint256 tokenId) external view returns (bool)
function claimed(uint256 id, bytes32 key) external view returns (bool)
function attested(uint256 id, bytes32 key) external view returns (bool)
```

## Natural-language patterns

- "deploy a prize pool on Robinhood" → Step 1
- "fund the prize pool with 100 USDG" → approve USDG then `fund(100e6)`
- "add a Mayor achievement worth 50 USDG" → `addAchievement(id, 0, 50e6, 1, true, 1, address(0), 0)`
- "attest that NFT #42 in [collection] is eligible for achievement 1001" → `attest(1001, collection, 42, true)`
- "claim the Guard achievement for NFT #42" → `claim(achievementId, collection, 42)`
- "how much USDG is in the prize pool?" → `poolBalance()`
- "has NFT #42 already claimed achievement 1001?" → `hasClaimed(1001, collection, 42)`
- "pause achievement 1002" → `setAchievementActive(1002, false)`

## Files

| File | Purpose |
|------|---------|
| `references/PrizePool.sol` | Contract source (all signatures verified here) |
| `references/PrizePool-abi.json` | Full ABI (from package, used for encoding calls) |
| `references/deploy-data.md` | Pre-built deploy payload + constructor arg detail |

## Notes

- The `cbBtc` immutable in the source holds USDG on this RH deploy (the
  variable name is inherited from the Base version; the logic is identical).
- `admin` is **immutable**. It can never be changed. The admin for the RH deploy
  is set at construction time (see Step 1).
- On-chain condition adapters (`ShiftCountCondition`, `TreeWaterCondition`) are
  also in the source but are separate contracts — deploy them independently if
  needed and pass their address as `condition` in `addAchievement`.
- Fund the pool before adding high-value FIXED achievements so claims never
  hit the underfunded revert.
