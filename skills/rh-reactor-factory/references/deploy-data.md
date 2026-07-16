# RHReactorFactory — Deploy Data

Chain: Robinhood (chainId 4663)
RPC: https://rpc.mainnet.chain.robinhood.com

## Source files (in package rh-reactor-factory/)

| File | Description |
|------|-------------|
| `RHReactorFactory.sol` | Contract source |
| `creation-bytecode.txt` | Factory creation bytecode only (0x prefixed, 4208 bytes) |
| `constructor-args-encoded.hex` | ABI-encoded constructor args (17248 bytes, includes child bytecode padding) |

## Deploy transaction

Full deploy tx.data = `creation-bytecode.txt` contents + `constructor-args-encoded.hex` contents concatenated.

No 0x prefix separator — just concatenate the two hex strings as-is.

## Constructor arg summary

| Position | Parameter | Value |
|----------|-----------|-------|
| 1 | `_positionManager` | `0x58daec3116aae6D93017bAAea7749052E8a04fA7` |
| 2 | `_universalRouter` | `0x53BF6B0684Ec7eF91e1387Da3D1a1769bC5A6F77` |
| 3 | `_permit2` | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| 4 | `_poolManager` | `0x8366a39CC670B4001A1121B8F6A443A643e40951` |
| 5 | `_prime` | `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D` |
| 6 | `_childCreationCode` | V4BurgersReactor creation bytecode (17010 bytes, embedded in encoded hex) |

## Gas

- Factory deploy: ~800k gas
- `createReactor(token)`: ~3.5M gas (deploys 17010 byte child)
- Gas fees: `maxFeePerGas=0.15 gwei`, `maxPriorityFeePerGas=0.01 gwei`
