# TasernBridgeBase — Deploy Data

Chain: Robinhood (chainId 4663)
RPC: https://rpc.mainnet.chain.robinhood.com

## Source files (in package tasern-bridge-rh/)

| File | Description |
|------|-------------|
| `TasernBridge.sol` | Full source: BridgedToken, BridgeCore, TasernBridgePolygon, TasernBridgeBase |
| `creation-bytecode.txt` | TasernBridgeBase creation bytecode (12294 hex chars = 6147 bytes) |

## Deploy transaction

tx.data = `creation-bytecode.txt` contents.

**No constructor args to append.** `TasernBridgeBase` constructor takes zero parameters.

## Gas

Estimate: ~800k gas (6147 bytes bytecode).
Gas fees: `maxFeePerGas=0.15 gwei`, `maxPriorityFeePerGas=0.01 gwei`

## Post-deploy verification

Call on deployed address:
- `owner()` should return the deployer address
- `relayer()` should return `address(0)` (before Step 2)
- `paused()` should return `false`
- `outboundNonce()` should return `0`

## Existing bridge addresses (do NOT redeploy these)

| Role | Chain | Address |
|------|-------|---------|
| TasernBridgePolygon | Polygon | `0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f` |
| Relayer (existing) | — | `0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC` |
| TasernBridgeBase (RH) | RH 4663 | FILL_AFTER_DEPLOY |
