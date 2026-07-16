# Coordinator On-Chain Verification 01 — 2026-07-16

Grounded RPC checks (`https://rpc.mainnet.chain.robinhood.com`) of BNKR's first two RH deploys.

## RESULT: neither created a contract ❌

Both transactions set `to = 0x0000000000000000000000000000000000000000` (the zero address).
That is NOT a contract-creation tx — creation requires `to` to be EMPTY / null. So the txs ran as
transfers to the zero address: they succeed but deploy nothing.

| Contract | tx | status | to | contractAddress | code |
|----------|-----|--------|-----|-----------------|------|
| PrizePool | 0xdc32714f…f283 | 0x1 | 0x0000…0000 | **null** | **0 bytes** |
| TasernBridgeBase | 0x5d7f0306…774c | 0x1 | 0x0000…0000 | **null** | **0 bytes** |

Bytecode WAS present in the tx input (6463 / 6146 bytes) — the only error is the `to` field.

## FIX
Resend each with `to` **empty / null / omitted** (not `0x0`). `data` = the same creation bytecode
(+ encoded args), `value` = 0. Then verify: receipt `contractAddress` non-null AND `eth_getCode > 0`.

Not moved to `done/`. `TASKS-FOR-BNKR.md` updated with the creation-tx rule at the top of the deploy queue.
