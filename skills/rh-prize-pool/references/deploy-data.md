# DEPLOYED — historical record only

The PrizePool was deployed by the MfT Coordinator on **2026-07-18**:

- **Address:** `0xF20c8d3B7EB81A2cf100e99690DA2E4D79F47D21` (chain 4663)
- Deploy tx: `0x0e2e7ef464fab0fcbf27b9ce422ed261ad84fa15a9f92f83a806e3142f5bc6ca`
- Source-verified: **Sourcify exact_match**; visible on robinhoodchain.blockscout.com
- Constructor verified on-chain: `cbBtc()` (prize token) = USDG
  `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`, `admin()` = MfT agent
  `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`

**Do NOT redeploy.** The original deploy payload lives in
`bnkr-sync/prize-pool-rh/` for byte-level reference.
Canonical record: `bnkr-sync/deployed/rh-tool-port-2026-07-18.json`.

Naming note: the prize-token immutable is named `_cbBtc`/`cbBtc()` in the
source (ported from Base). On this deployment it holds USDG (6 decimals).
