# DEPLOYED — historical record only

The RHVaultFactory was deployed by the MfT Coordinator on **2026-07-18**:

- **Address:** `0xd41a8E5c44c4a83F6406eB7B530429E5411588Ec` (chain 4663)
- Deploy tx: `0xe2aea38399117f94b3e12d8a940ba1f2ebddf57b248306e47c1a54e0ba91c05e`
- Source-verified: **Sourcify exact_match**; visible on robinhoodchain.blockscout.com
- All 8 baked constants (POOL_MANAGER/POSM/ROUTER/PERMIT2/USDG/FTP_VAULT/BURGERS/WETH)
  verified on-chain against the canonical registry

**Do NOT redeploy.** The original deploy payload lives in
`bnkr-sync/rh-vault-factory/` for byte-level reference.
Canonical record: `bnkr-sync/deployed/rh-tool-port-2026-07-18.json`.

## Live-call gas (still current)

- `createVault(owner, ticks, salt)`: ~3,000,000 gas (deploys 21KB vault bytecode)
- Gas fees: `maxFeePerGas=0.15 gwei`, `maxPriorityFeePerGas=0.01 gwei`

## Existing manual vault deploys (not through factory)

| Label | Address |
|-------|---------|
| V1 (superseded) | `0x35f67D74402dd46aAd94809808698FCDB93BEE50` |
| V2 (burgersV2, active) | `0x261F76D20983f299962b1481d7968d2F27b79BB1` |
