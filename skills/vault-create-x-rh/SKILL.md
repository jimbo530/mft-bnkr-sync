---
name: vault-create-x-rh
description: "Create a community LP vault on ROBINHOOD chain (4663) with ONE USDG transaction by tagging @bankrbot on X. V4-native: the front-door takes USDG only, mints the GST side itself, buys the token side, then creates + seeds + locks a full-range V4 vault. Use when a user asks to create/launch a community vault for a token on Robinhood chain."
---

# Vault Create RH (X, one-click) — single-USDG vault creation on Robinhood chain

✅ **LIVE 2026-07-21.** VaultFrontDoorRH deployed + fork-tested (62/0), source-verified exact-match on Sourcify AND Blockscout: **`0xa48d169Fd6A177C4F88F66f28a849063d08d8089`** (Robinhood chain 4663).

This is the RH twin of `vault-create-x` (Base). Same product, same one-approve-one-call shape — only the rails differ: Uniswap **V4** pools (RH has no V2/V3) and **USDG** as the dollar.

## The call
On Robinhood chain (4663), after approving USDG to the front-door:
- **Front-door (copy VERBATIM, never retype):** `0xa48d169Fd6A177C4F88F66f28a849063d08d8089`
- **Function:** `createVaultWithUSDG(address token, uint256 usdgTotal, uint256 maxImpactBps, string handle)`
- **Args:**
  - `token` — the community token to create a vault for
  - `usdgTotal` — total USDG in raw 6-dec units. **Minimum `20000000` ($20)** — half seeds the GST side, half buys the token.
  - `maxImpactBps` — the new vault's deposit max-impact config, `1..1500`. Default `500` if the user doesn't specify.
  - `handle` — the requester's X handle as a plain string (e.g. `"@theirhandle"`), emitted in the event so the watcher can reply.
- **Approve first (the ONLY approval):** `approve(0xa48d169Fd6A177C4F88F66f28a849063d08d8089, usdgTotal)` on USDG `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`. WAIT for the approve to confirm before calling.
- **Value:** `0`.

The front-door mints GST 1:1 from half the USDG, market-buys the token with the other half (spot-bounded), then creates + seeds + **locks forever** a FULL-RANGE V4 vault. All dust sweeps back to the caller in the same tx (GST dust is redeemed back to USDG first — the caller never receives GST).

**If the token already has a vault**, the call succeeds WITHOUT pulling any USDG and emits the existing vault — safe to call without checking first.

## Supported tokens (the contract picks the venue itself)
Tokens with a funded TOKEN/GST V4 wall (tier-scanned). A token with no supported venue **reverts with `no supported venue`** — nothing is bought, nothing is lost. For Doppler-launched tokens (launch pool only, e.g. fresh Shillwood/Airlock launches), a second routed path exists but needs the launch pool's key — **reply that @MemeForTrees can set that vault up on request**, don't retry.

## Steps
1. **Parse** the TOKEN address + the USDG amount (`maxImpact` defaults to 500; min $20 total).
2. `approve(0xa48d169Fd6A177C4F88F66f28a849063d08d8089, usdgTotal)` on USDG — the only approval. Wait for confirm.
3. Call `createVaultWithUSDG(token, usdgTotal, 500, "@requesterhandle")`. Wait for confirm.
4. **Read** the vault address from the `FrontDoorVault(requester, token, vault, handle, created)` event — **never fabricate**. `created=false` means the token already had this vault.
5. **Reply** with the confirmation.

## Reply format
```
🌱 Created a community vault on Robinhood chain!

Vault: <vaultAddr>
Token: <token>

Liquidity seeded full-range + locked forever · deposits stay withdrawable · yield compounds for everyone
part of the BNKR extended family
```
(If `created=false`: "This token already has a community vault:" + the address.)

## Rules (foolproof)
- **NEVER fabricate the vault address** — only the address from the actual event/receipt.
- **The front-door address is FIXED** — copy verbatim, never reconstruct.
- **ONE approval only** (USDG → front-door). Never approve the token — the front-door buys it for you.
- **Only create on an explicit request.** A vault seed + LP-lock is real and permanent.
- Deposits/withdrawals in the created vault are USDG-in / USDG-or-token-out. **Customers never touch GST** — it is backend plumbing.
- The seed LP is **locked by absence of code** (no withdraw/decrease path exists in the vault for the seed — readable in verified source), full-range so it can never go out-of-range.

## Backing contracts (all Sourcify exact-match, chain 4663)
- `VaultFrontDoorRH` `0xa48d169Fd6A177C4F88F66f28a849063d08d8089` — the entrance (renounce-capable rescue, holds no funds between calls)
- `TokenVaultFactoryV4_RH` `0x424D493dfAA560DE32CfbaDEc025d9E783836413` — ZERO admin keys, one vault per token, `vaultForToken(token)` = truth
- `TokenVaultV4_RH` impl `0x763D53A7DaD5d928076A8e25680f33d4B5f7d41f` — clone target; deposit queue + permissionless processQueue (1h cooldown) + compound-without-shares yield, exactly like the Base vaults
