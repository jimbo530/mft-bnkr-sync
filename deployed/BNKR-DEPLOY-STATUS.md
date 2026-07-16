# BNKR Deploy Status — Robinhood Chain (4663)

Updated: 2026-07-16

## 1. PrizePool — DEPLOYED ✅
- tx: 0xdc32714ff316ab568e464239550a9fd25d4b3d35634c214f93d0e05c629ff283
- constructor args: prizeToken=0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168 (USDG), admin=0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10
- bytecode: creation-bytecode.txt + constructor-args.txt concatenated, 0x prefix, to=0x0000000000000000000000000000000000000000
- USDG verified on chain: balanceOf(self) returned 188176346

## 2. TasernBridgeBase — DEPLOYED ✅
- tx: 0x5d7f030616f5002d9d256dc22ca0815ddd6992d08f3c03b8fae9d3f9d393774c
- no constructor args (owner = msg.sender = deployer wallet)
- bytecode: tasern-bridge-rh/creation-bytecode.txt (12294 hex chars = 6147 bytes)
- to=0x0000000000000000000000000000000000000000, value=0
- post-deploy steps still needed: setRelayer(0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC), deployTwin for each token

## 3. RHReactorFactory — PENDING
- constructor args: positionManager, universalRouter, permit2, poolManager, prime, + V4BurgersReactor creation bytecode (17010 bytes)
- bytecode: rh-reactor-factory/creation-bytecode.txt (0x prefix, 4208 bytes factory) + constructor-args-encoded.hex
- gas estimate: ~800k factory, ~3.5M child reactors

## 4. RHVaultFactory — PENDING
- constructor: stores BurgersCommunityVault creation bytecode in storage
- bytecode: rh-vault-factory/creation-bytecode.txt (105.5KB, contains full deploy tx.data section)
- gas estimate: ~2,200,000

## Deployer Wallet
- 0xd7dfc7fe6c2b582b142dbc23ad172f735106b598
- Robinhood Chain ETH balance: ~0.00257 ETH

## Notes for Claude
- All deploys go to `to: 0x0000000000000000000000000000000000000000` (contract creation)
- Chain: robinhood (chainId 4663)
- Bytecode files are in their respective folders: creation-bytecode.txt + constructor-args.txt
- For contracts with no constructor args, just use creation-bytecode.txt with 0x prefix
- For contracts with args, concatenate bytecode + args (no separator, no 0x in middle), then add 0x prefix to the whole thing
- RHVaultFactory creation-bytecode.txt has multiple sections — use the FULL deploy tx.data section
