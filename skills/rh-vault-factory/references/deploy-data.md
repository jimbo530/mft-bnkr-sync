# RHVaultFactory — Deploy Data

Chain: Robinhood (chainId 4663)
RPC: https://rpc.mainnet.chain.robinhood.com

## Source files (in package rh-vault-factory/)

| File | Description |
|------|-------------|
| `RHVaultFactory.sol` | Factory source |
| `BurgersCommunityVault.sol` | Vault impl source (bytecode embedded in factory) |
| `RHVaultFactory.artifact.json` | Compiled ABI + factory bytecode |
| `creation-bytecode.txt` | Contains factory-only hex AND full deploy tx.data sections |

## Deploy transaction

Use the "FULL deploy tx.data" section in `creation-bytecode.txt`.

That is factory creation bytecode + ABI-encoded constructor arg (the impl bytecode blob).

## Constructor arg

Single argument: `_implBytecode` (bytes) — the BurgersCommunityVault creation bytecode.
This is pre-encoded in the full deploy tx.data in creation-bytecode.txt.

## Gas

- Factory deploy: ~2,200,000 gas (factory + 21KB vault bytecode in constructor storage)
- `createVault(owner, ticks, salt)`: ~3,000,000 gas (deploys 21KB vault bytecode)
- Gas fees: `maxFeePerGas=0.15 gwei`, `maxPriorityFeePerGas=0.01 gwei`

## Existing manual vault deploys (not through factory)

| Label | Address |
|-------|---------|
| V1 (71091 NFT) | `0x35f67D74402dd46aAd94809808698FCDB93BEE50` |
| V2 (burgersV2, active) | `0x261F76D20983f299962b1481d7968d2F27b79BB1` |
