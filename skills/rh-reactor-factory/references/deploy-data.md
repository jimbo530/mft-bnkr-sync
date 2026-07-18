# DEPLOYED — historical record only

The RHReactorFactory was deployed by the MfT Coordinator on **2026-07-18**:

- **Address:** `0xdC36A42cf7F964053EB3Ab2aF169BdaBF4263C80` (chain 4663)
- Deploy tx: `0x02dd95b17251ad2d7a0b76581ae5265a4f1e98d00842fece8e3ebc190c20a28e`
- Source-verified: Sourcify full runtime+creation match; visible on
  robinhoodchain.blockscout.com
- Wiring verified on-chain: prime/positionManager/universalRouter/permit2/poolManager
  all match the canonical RH V4 addresses

**Do NOT redeploy.** The original deploy payload lives in
`bnkr-sync/rh-reactor-factory/` if ever needed for byte-level reference.
Canonical record: `bnkr-sync/deployed/rh-tool-port-2026-07-18.json`.

## Live-call gas (still current)

- `createReactor(token)`: ~3.5M gas (deploys 17010-byte child)
- Gas fees: `maxFeePerGas=0.15 gwei`, `maxPriorityFeePerGas=0.01 gwei`
