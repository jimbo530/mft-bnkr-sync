# Base Charity Funds — Address Reference

All verified on-chain 2026-07-14 via `eth_getCode` + `name()/symbol()/decimals()` + one sanity read.
Chain: Base (chainId 8453). Explorer: https://basescan.org/address/<addr>

## CharityFund infrastructure

| Contract | Address | Notes |
|---|---|---|
| CharityFundFactory | `0x955383723E8A1AD82800406D6f492260918DF882` | Deploys EIP-1167 clones; verified `implementation()=0xBEA5c3D2dc02C4A8385896ca70CCC6345574c96f` |
| CharityFund implementation | `0xBEA5c3D2dc02C4A8385896ca70CCC6345574c96f` | Logic contract all clones proxy to; 15,135 bytes |
| Aave V3 Pool (Base) | `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5` | Where principal earns yield |
| Reactor Prime (yield destination) | `0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA` | Service-leg yield flows here as mftUSD V2 |

## Fund addresses

### Money for Trees (key: `money`)
- **Fund**: `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072`
- **Deposit asset**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6 dec)
- **Receipt**: Money (6 dec)
- **Verified**: name="Money for Trees", decimals=6, reactor=Reactor Prime

### PRGT — Poly Raiders Growth Token (key: `prgt`)
- **Fund**: `0xEe6fB5f324B05efF95fD59F4574050a891e6913D`
- **Deposit asset**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6 dec)
- **Receipt**: PRGT (6 dec)
- **PRGT vault factory**: `0xA54C86b545F6451c761Da684740bb390495170Df` (from fund-vault-factories-deployment.json)

### CHAR-R — Carbon Retirement Fund (key: `char-r`)
- **Fund**: `0xde12963128CBe9aF173a37FFF866cA4D4A194ff4`
- **Deposit asset**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6 dec)
- **Receipt**: CHAR-R (6 dec)
- **Verified**: name="CHAR Retirement Fund", sym=CHAR-R
- **FundVaultFactory (CHAR-R)**: `0x503fe2226ed8c93bC7864a3E59cEb2c64C305c64`

### CCC-R — CCC Retirement Fund (key: `ccc-r`)
- **Fund**: `0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B`
- **Deposit asset**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6 dec)
- **Receipt**: CCC-R (6 dec)
- **Verified**: name="CCC Retirement Fund", sym=CCC-R
- **FundVaultFactory (CCC-R)**: `0x4a2DFd07A13aBD64553d34F65074fc716D97C290`

### BTC-T — BTC for Trees (key: `btc-t`)
- **Fund**: `0x839BAa00734f319C11F2869bC155C6B5Fe35a283`
- **Deposit asset**: cbBTC `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf` (8 dec)
- **Receipt**: BTC-T (8 dec, despite CharityFund.sol returning decimals()=6; encode at 8 dec)
- **Verified**: sym=BTC-T, charityWallet=project wallet
- **FundVaultFactory (BTC-T)**: `0xA7BeD0d9963837E8426F241f132e1F8daEA6bD8B` (fund-vault-factories-deployment.json)

### ETH-T — ETH for Trees (key: `eth-t`)
- **Fund**: `0x80d1edd0236A06283fd1212FDB12cfA79516933d`
- **Deposit asset**: wETH `0x4200000000000000000000000000000000000006` (18 dec)
- **Receipt**: ETH-T (18 dec, encode at 18 dec)
- **Verified**: name="ETH for Trees", sym=ETH-T
- **ETHTVaultFactory**: `0xc2Dbb3A02CF43270e3A69c2e15354887E094575f` (calm-vault-etht-factory-deployment.json)
  - Note: an older ETHTVaultFactory `0x53d8AdA1EEA871689323f7bd4B6f2f6208079704` exists in fund-vault-factories-deployment.json
    (same underlying, different implementation version — the calm-vault version supersedes it)

## Decimal encoding notes

When encoding calldata amounts, always use the **deposit asset** decimal count,
not CharityFund's `decimals()` return value (which is hardcoded to 6 in the sol):

| Key    | Asset   | Encode at |
|--------|---------|-----------|
| money  | USDC    | 6         |
| prgt   | USDC    | 6         |
| char-r | USDC    | 6         |
| ccc-r  | USDC    | 6         |
| btc-t  | cbBTC   | 8         |
| eth-t  | wETH    | 18        |

`deposit(uint256 amount)` pulls `amount` raw token units from the caller, so
encoding at the asset's decimal count is correct.
