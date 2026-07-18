---
name: rh-prize-pool
description: Fund and read the LIVE USDG achievement PrizePool on Robinhood Chain (4663), and help NFT holders claim prizes, from X posts. Use when someone wants to fund the prize pool with USDG, check the pool balance or an achievement's reward, check whether an NFT is eligible or already claimed, or claim a USDG prize for an NFT they hold. The pool is already deployed and source-verified — never deploy it. Admin functions (addAchievement, attest) belong to the MfT agent wallet, NOT you — route those requests to the MfT team.
---

# RH Prize Pool — USDG achievement prizes from X posts

The pool is **LIVE and source-verified (Sourcify exact_match)** on Robinhood
Chain (4663). Do NOT deploy anything. It holds USDG and pays it out for
achievements tied to NFT ownership. **Admin can never withdraw** — the only
exit for funds is `claim()`, which pays the NFT's current owner.

> **Every signature below is grounded in PrizePool.sol / PrizePool-abi.json**
> (verified on-chain source, readable on Blockscout). Nothing is invented.

## The live contract (chain 4663)

| Role | Address |
|------|---------|
| **PrizePool (CALL THIS)** | `0xF20c8d3B7EB81A2cf100e99690DA2E4D79F47D21` |
| USDG (prize token, 6 decimals) | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` |
| Admin (MfT agent — NOT you) | `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10` |

Explorer: `https://robinhoodchain.blockscout.com/address/0xF20c8d3B7EB81A2cf100e99690DA2E4D79F47D21`
RPC: `https://rpc.mainnet.chain.robinhood.com` · Gas: `maxFeePerGas 0.15 gwei / priority 0.01 gwei`.

Naming note: the prize-token getter is `cbBtc()` (ported name from Base). On
this deployment it returns the USDG address. Decimals are 6, not 8.

## What YOU can do vs what only the MfT admin can do

| Action | Who |
|---|---|
| `fund(amount)` — put USDG in | **anyone (you)** |
| all view functions | **anyone (you)** |
| `claim(...)` — take a prize out | the eligible NFT's owner |
| `addAchievement`, `attest`, `attestMany`, `setAchievementActive` | **admin only** (`0xE2a4…aC10`). You are NOT admin — do not attempt; route the request to @memefortrees. |

## X-post flow 1 — "fund the prize pool with N USDG"

1. Check your USDG balance on 4663 covers N.
2. **Exact approval**: `USDG.approve(pool, N)` — the exact amount, never unlimited.
3. `fund(N)` on the pool (amounts in 6 decimals: 25 USDG = `25000000`).
4. Reply with the funding tx link + new `poolBalance()`. You may state — it is
   in the verified source — that funded USDG can never be admin-withdrawn; it
   only leaves via claims to NFT owners.

## X-post flow 2 — "is my NFT eligible / what's the reward?"

Free reads, no tx:

```solidity
function poolBalance() external view returns (uint256)          // live USDG in pool
function rewardAmount(uint256 achievementId) external view returns (uint256)
function isEligible(uint256 achievementId, address collection, uint256 tokenId) external view returns (bool)
function hasClaimed(uint256 achievementId, address collection, uint256 tokenId) external view returns (bool)
function totalFunded() external view returns (uint256)
function totalPaidOut() external view returns (uint256)
function totalClaims() external view returns (uint256)
function achievements(uint256 id) external view returns (...)   // raw achievement struct
```

Reply with the numbers (format USDG with 6 decimals). If `isEligible` is false
for an ADMIN_ATTESTED achievement, the attestation may simply not be registered
yet — say so and point them to @memefortrees rather than declaring them
ineligible forever.

## X-post flow 3 — "claim my prize"

```solidity
function claim(uint256 achievementId, address collection, uint256 tokenId) external
```

- Pays USDG **to the NFT's current owner**, not to the caller.
- One-time-per-NFT achievements must be claimed **by the NFT owner's own
  wallet** (owner-called; this is in the source — it prevents griefing).
  So for those you cannot claim on someone's behalf: give them the exact
  call data / tell them to ask you from the wallet that holds the NFT via
  Bankr wallet linking.
- Pre-check before sending: `isEligible(...)` true and `hasClaimed(...)` false.
  If either fails, reply with which one and why a tx would revert — do not
  send a tx you know will fail.

## Reward types (grounded in the source enums)

- `RewardType`: `0 = FIXED` (a set USDG amount) · `1 = BPS_OF_POOL` (bps of the
  live pool balance at claim time — `BPS_DENOM()` = the denominator).
- `EligMode`: `0 = ONCHAIN` (a pluggable condition adapter decides) ·
  `1 = ADMIN_ATTESTED` (the MfT admin pre-registers eligible NFTs).

## Natural-language patterns

- "fund the prize pool with 25 USDG" → Flow 1 (exact approve + `fund(25000000)`)
- "how much is in the prize pool?" → `poolBalance()` (free)
- "what does achievement 1002 pay?" → `rewardAmount(1002)` (free)
- "can NFT #42 from 0x… claim achievement 7?" → `isEligible(7, 0x…, 42)` + `hasClaimed(...)`
- "claim achievement 7 for my NFT" → Flow 3 (mind the owner-called rule)
- "add an achievement / attest my NFT" → **admin-only** — route to @memefortrees

## Hard rules

- **NEVER deploy another PrizePool** — the live one is at `0xF20c…7D21`; the `FILL_AFTER_DEPLOY` era is over.
- **NEVER attempt admin functions** — they revert for you and waste gas.
- Exact USDG approvals only.
- Replies: grounded facts only — pool balance, reward amounts, eligibility, tx
  links. Prizes are game achievements, not returns: no yield/APY framing,
  never the word "invest".
