# PrizePool — Deploy Data

Chain: Robinhood (chainId 4663)
RPC: https://rpc.mainnet.chain.robinhood.com

## Source files (in package prize-pool-rh/)

| File | Description |
|------|-------------|
| `PrizePool.sol` | Contract source |
| `PrizePool-abi.json` | Full compiled ABI |
| `creation-bytecode.txt` | Creation bytecode (0x prefixed) |
| `constructor-args.txt` | ABI-encoded constructor args + breakdown |

## Deploy transaction

Full deploy tx.data = `creation-bytecode.txt` contents + constructor args hex from `constructor-args.txt` (concatenated, no separator).

## Constructor args

| Position | Parameter | Value |
|----------|-----------|-------|
| 1 | `_cbBtc` (prize token) | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` (USDG on RH) |
| 2 | `_admin` | `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10` (agent wallet) |

Note: the parameter is named `_cbBtc` in the source (ported from Base). On RH
this immutable holds the USDG address. The logic is identical.

## Gas

Estimate: standard ERC-20 contract deploy, no large bytecode payload.
Gas fees: `maxFeePerGas=0.15 gwei`, `maxPriorityFeePerGas=0.01 gwei`

## Deployed PrizePool address

FILL_AFTER_DEPLOY
