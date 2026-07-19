---
name: vault-create-x
description: "[STAGING — NOT LIVE until VaultFrontDoor is deployed] Create a community LP vault on Base with ONE USDC transaction by tagging @bankrbot on X. Solves the two-token problem: the front-door takes USDC only, buys the token side itself, then creates + seeds + locks the vault via MfTVaultFactory. Use when a user asks to create/launch a community vault for a token on Base with a single USDC amount."
---

# Vault Create (X, one-click) — single-USDC vault creation on Base

⛔ **STAGING — NOT LIVE YET.** This skill needs the `VaultFrontDoor` contract deployed on Base first. The front-door address below is filled in AFTER deploy. Do NOT install or use until the address is present and this banner is removed.

**Front-door:** `<FILLED AFTER DEPLOY>` — Base (chainId 8453)

## Why this exists
The existing `base-charity-vault-create` skill needs the caller to hold **and approve two assets** (USDC + the token) in one go — which the BNKR bot can't do from a single X prompt. This front-door takes **one** asset (USDC), buys the token side itself, and creates the vault. **One approval, one call.**

## The call
On Base, after approving USDC to the front-door:
- **Front-door (copy VERBATIM, never retype):** `<FILLED AFTER DEPLOY>`
- **Function:** `createVault(address token, uint256 usdcTotal, uint256 minTokenOut, uint256 maxImpactBps)`
- **Args:**
  - `token` — the community token to create a vault for
  - `usdcTotal` — total USDC in raw 6-dec units (e.g. `20000000` = $20). **Minimum $20** recommended — half of `usdcTotal` seeds the Money side and the factory's `MIN_USDC` there is 10 USDC.
  - `minTokenOut` — slippage floor for the token buy; pass `0` to auto-quote at the front-door's slippage (3%).
  - `maxImpactBps` — the new vault's deposit max-impact config, `1..1500` (e.g. `500` = 5%). Default 500 if the user doesn't specify.
- **Approve first (the ONLY approval):** `approve(frontDoor, usdcTotal)` on USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`.
- **Value:** `0`.

The front-door splits `usdcTotal`: half seeds the Money side (via the factory), half buys the token side; the factory then creates + seeds + **burns-locks** the vault and returns its address.

## Steps
1. **Parse** the TOKEN address + the USDC amount from the request. (`maxImpact` defaults to 500 / 5% if unspecified.)
2. `approve(frontDoor, usdcTotal)` on USDC — the only approval.
3. Call `createVault(token, usdcTotal, 0, maxImpactBps)` on the front-door. Wait for confirm.
4. **Read** the vault address from the `VaultCreated` event / return value — **never fabricate**.
5. **Reply** with the confirmation.

## Reply format
```
🌱 Created a community vault on Base!

Vault: <vaultAddr>
Token: <token>

Liquidity seeded + locked forever · deposits fund trees
part of the BNKR extended family
```

## Rules (foolproof)
- **NEVER fabricate the vault address** — report only the address from the actual tx receipt.
- **The front-door address is FIXED** (filled post-deploy) — copy verbatim, never reconstruct.
- **ONE approval only** (USDC → front-door). Never approve the token — the front-door buys it for you.
- **Only create on an explicit request.** A vault seed + LP-lock is real and permanent.
- The vault LP is **burned/locked forever**; the seed price ratio is set at market by the front-door. No undo.

## Backing contract
`VaultFrontDoor.sol` (mftusd-build, compile-verified). Detects the token's pairing (Money-paired → `USDC→Money(mint)→token`; WETH-paired → `USDC→WETH→token`), exact approvals, reentrancy-guarded, renounce-capable, holds no funds between calls. Wraps `MfTVaultFactory` `0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1` (verified live, 4603 bytes, USDC+FUND wired).
