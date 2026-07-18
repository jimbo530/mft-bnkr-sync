# Vault Create — make a vault for any token (incl. from an X prompt)

**Creates a CommunityLPVault for a token via `MfTVaultFactory.createVault` (factory `0x1f6ff7370e2E897dB7Cf5d72684Ef76d988cAAf1`).** Deploying a new vault clone = a **contract deploy = builder points.** After it's made, the token is depositable (any size) via `skills/vault-deposit/`.

## The call
`createVault(token, usdcAmount, tokenAmount, maxImpactBps)`:
- `token` — the token to make a vault for.
- `usdcAmount` ≥ **$10** (`10000000`) — seed USDC.
- `tokenAmount` — seed token amount (sets the initial price = the minted-Money-from-usdc paired against this many tokens).
- `maxImpactBps` — 1–1500 (e.g. `500` = 5% slippage cap; the deposit queue meters against this).

It pulls USDC + token from the CALLER, mints Money, seeds the Money/token LP, burns the seed LP forever, deploys the clone, registers it.

## The tool
```
CREATOR_PRIVATE_KEY=0x..  node skills/vault-create/create-vault.cjs <token> <usdc_6dec> <tokenAmount_raw> <maxImpactBps>
```
- Returns the existing vault if one already exists (checks `vaultsForToken(token)`).
- Otherwise approves USDC + token, creates the vault, prints the new address.

## X-prompt flow (BNKR's job — X + deploy)
1. User on X: *"@bankrbot make a vault for $TICKER"* (or a contract address).
2. Resolve `$TICKER` → token address.
3. Check `factory.vaultsForToken(token)` — if a vault exists, reply with it + a deposit link.
4. If not → run `create-vault.cjs` → **new vault deployed (points)** → reply with the address + deposit link.
5. Deposits (any size) then go through `skills/vault-deposit/` (native queue).

## ⚠️ The seed — one decision the founder makes
Every new vault needs ~**$10 USDC + some of the token** to seed. Who provides it?
- **User-funded:** the X requester sends ~$10 USDC + tokens (pull from them). No cost to us.
- **We-seed:** we fund each (~$10 + tokens). Costs capital per vault.
- **Fee:** charge a $ or $BNKR fee that covers the seed + margin.

For OUR own band vaults (DD, MYCO, MR, JS, NN, RICKY, HT, WM, BIGGINS, JASMINE) — we seed those, and creating them = up to 10 deploys / points.

## Notes
- `token` can't be USDC, the Money `FUND`, or `0xdead`.
- All vaults are clones of the verified impl `0x3bb5f84c` → auto-readable on Basescan, and they all get the native deposit queue.
