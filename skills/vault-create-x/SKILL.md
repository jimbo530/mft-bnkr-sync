---
name: vault-create-x
description: "Create a community LP vault on Base with ONE USDC transaction by tagging @bankrbot on X. Solves the two-token problem: the front-door takes USDC only, buys the token side itself, then creates + seeds + locks the vault via MfTVaultFactory. Use when a user asks to create/launch a community vault for a token on Base with a single USDC amount."
---

# Vault Create (X, one-click) — single-USDC vault creation on Base

✅ **LIVE 2026-07-21.** VaultFrontDoor deployed + fork-tested (48/0): **`0xD8231550E5FC3c063F48d1E5Dea010EbbEA48c9E`** (Base). That is the front-door address everywhere below.

**Front-door:** `<FILLED AFTER DEPLOY>` — Base (chainId 8453)

## Why this exists
The existing `base-charity-vault-create` skill needs the caller to hold **and approve two assets** (USDC + the token) in one go — which the BNKR bot can't do from a single X prompt. This front-door takes **one** asset (USDC), buys the token side itself, and creates the vault. **One approval, one call.**

## The call
On Base, after approving USDC to the front-door:
- **Front-door (copy VERBATIM, never retype):** `<FILLED AFTER DEPLOY>`
- **Function:** `createVaultWithUSDC(address token, uint256 usdcTotal, uint256 maxImpactBps, string handle)`
- **Args:**
  - `token` — the community token to create a vault for
  - `usdcTotal` — total USDC in raw 6-dec units. **Minimum `20000000` ($20)** — half seeds the Money side (the factory's floor there is $10), half buys the token.
  - `maxImpactBps` — the new vault's deposit max-impact config, `1..1500` (e.g. `500` = 5%). Default 500 if the user doesn't specify.
  - `handle` — the requester's X handle as a plain string (e.g. `"@theirhandle"`). It is emitted in the event so the watcher can reply — pass it exactly.
- **Approve first (the ONLY approval):** `approve(0xD8231550E5FC3c063F48d1E5Dea010EbbEA48c9E, usdcTotal)` on USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`.
- **Value:** `0`.

The front-door splits `usdcTotal`: half goes to the factory (which mints Money from it), half market-buys the token; the factory then creates + seeds + **burns-locks** the vault. Any USDC/Money/token dust refunds to the caller in the same tx.

**If the token already has a vault**, the call succeeds WITHOUT pulling any USDC and simply returns/emits the existing vault — safe to call without checking first.

## Supported tokens (v1 — the contract picks the venue itself)
Money V3 1% walls (all MfT band tokens) · Money V2 pairs · token/WETH Uniswap V3 (1%/0.3%/0.05%) · token/WETH Uniswap V2. A token with none of these pools **reverts with `no supported venue`** — nothing is bought, nothing is lost. Report that honestly, don't retry.

## Steps
1. **Parse** the TOKEN address + the USDC amount from the request (`maxImpact` defaults to 500; min $20 total).
2. `approve(0xD8231550E5FC3c063F48d1E5Dea010EbbEA48c9E, usdcTotal)` on USDC — the only approval.
3. Call `createVaultWithUSDC(token, usdcTotal, maxImpactBps, "@requesterhandle")`. Wait for confirm.
4. **Read** the vault address from the `FrontDoorVault(requester, token, vault, handle, created)` event — **never fabricate**. `created=false` means the token already had this vault.
5. **Reply** with the confirmation.

## Reply format
```
🌱 Created a community vault on Base!

Vault: <vaultAddr>
Token: <token>

Liquidity seeded + locked forever · deposits fund trees
part of the BNKR extended family
```
(If `created=false`: "This token already has a community vault:" + the address + a deposit link.)

## Rules (foolproof)
- **NEVER fabricate the vault address** — report only the address from the actual event/receipt.
- **The front-door address is FIXED** (filled post-deploy) — copy verbatim, never reconstruct.
- **ONE approval only** (USDC → front-door). Never approve the token — the front-door buys it for you.
- **Only create on an explicit request.** A vault seed + LP-lock is real and permanent.
- The vault seed LP is **burned/locked forever**; the seed ratio is set at live market spot with a price-impact guard. No undo.

## Backing contract
`VaultFrontDoor.sol` (mftusd-build — compiled clean solc 0.8.36, **48/48 fork tests** in `test-vault-frontdoor-fork.cjs` against the live factory/walls/pools). Venue-routing (Money V3 wall → Money V2 → WETH V3 → WETH V2, else revert), spot-bounded buys (10% max incl. pool fee), exact approvals, reentrancy-guarded, renounce-capable rescue, holds no funds between calls. Wraps `MfTVaultFactory` `0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1` (verified live).
