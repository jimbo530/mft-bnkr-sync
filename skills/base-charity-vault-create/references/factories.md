# Base Charity Vault Factories — Address Reference

All verified on-chain 2026-07-14. Chain: Base (chainId 8453).
Source files: fund-vault-factories-deployment.json, btct-vault-factory-deployment.json,
calm-vault-etht-factory-deployment.json, prgt-vault-factory-deployment.json,
MfT-Addresses.md, MfTVaultFactory.json (bytecode embedded USDC/Money addresses),
BTCTVaultFactory.json (bytecode embedded cbBTC/BTC-T addresses),
ETHTVaultFactory.json (bytecode embedded wETH/ETH-T addresses).

## LP Vault Factories

All factories use the same createVault signature:
  createVault(address token, uint256 seedAmount, uint256 tokenAmount, uint256 maxImpactBps)
  selector: 0x0eabcca1

### MfTVaultFactory (key: mft-vault)
- **Factory**: `0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1`
- **Verified**: name=MfTVaultFactory in on-chain sweep (_verify-sweep-result.json), 4,603 bytes
- **Underlying**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (hardcoded in bytecode, confirmed from MfTVaultFactory.sol embedded address)
- **Paired fund**: Money for Trees `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` (hardcoded in bytecode)
- **Implementation**: `0x3bB5f84c797e5932656AB66830bD901637DaE318` (CommunityLPVaultV3, 10,306 bytes)
- **MIN_USDC**: 10,000,000 (= $10; confirmed from MfTVaultFactory.sol source MIN_USDC=10_000_000)
- **Source**: deploy-vault-factory.cjs + MfT-Addresses.md

### FundVaultFactory — CHAR-R (key: char-r-vault)
- **Factory**: `0x503fe2226ed8c93bC7864a3E59cEb2c64C305c64`
- **Source**: fund-vault-factories-deployment.json (CHAR-R entry)
- **Underlying**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6 dec)
- **Paired fund**: CHAR-R `0xde12963128CBe9aF173a37FFF866cA4D4A194ff4`
- **Implementation**: `0xB9d3723B5CAB7DaB4A1b2f6EC63D77cbaEE6C315` (FOT-safe v2 impl)
- **MIN_SEED**: 20,000,000 (= $20 USDC)

### FundVaultFactory — CCC-R (key: ccc-r-vault)
- **Factory**: `0x4a2DFd07A13aBD64553d34F65074fc716D97C290`
- **Source**: fund-vault-factories-deployment.json (CCC-R entry)
- **Underlying**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6 dec)
- **Paired fund**: CCC-R `0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B`
- **Implementation**: `0xB9d3723B5CAB7DaB4A1b2f6EC63D77cbaEE6C315`
- **MIN_SEED**: 20,000,000

### FundVaultFactory — PRGT (key: prgt-vault)
- **Factory**: `0xA54C86b545F6451c761Da684740bb390495170Df`
- **Source**: fund-vault-factories-deployment.json (PRGT entry)
- **Underlying**: USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6 dec)
- **Paired fund**: PRGT `0xEe6fB5f324B05efF95fD59F4574050a891e6913D`
- **Implementation**: `0xB9d3723B5CAB7DaB4A1b2f6EC63D77cbaEE6C315`
- **MIN_SEED**: 20,000,000

### FundVaultFactory — BTC-T (key: btc-t-vault)
- **Factory**: `0xA7BeD0d9963837E8426F241f132e1F8daEA6bD8B`
- **Source**: fund-vault-factories-deployment.json (BTC-T entry) — this is the v2 FOT-safe factory deployed 2026-07-08; supersedes the earlier `0x54CBD993DD393D34fA9747134C65bFA2Ba0D9B3F` (btct-vault-factory-deployment.json, 0 vaults, abandoned)
- **Underlying**: cbBTC `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf` (8 dec); address embedded in BTCTVaultFactory.json bytecode
- **Paired fund**: BTC-T `0x839BAa00734f319C11F2869bC155C6B5Fe35a283`; address embedded in BTCTVaultFactory.json bytecode
- **Implementation**: `0xB9d3723B5CAB7DaB4A1b2f6EC63D77cbaEE6C315`
- **MIN_CBBTC**: 32,000 sats (verified from BTCTVaultFactory.json bytecode constant 0x7d00 = 32000)

### ETHTVaultFactory (key: eth-t-vault)
- **Factory**: `0xc2Dbb3A02CF43270e3A69c2e15354887E094575f`
- **Source**: calm-vault-etht-factory-deployment.json — this is the v2 FOT-safe factory deployed 2026-07-08; supersedes the earlier `0x53d8AdA1EEA871689323f7bd4B6f2f6208079704` (fund-vault-factories-deployment.json ETH-T entry, 0 vaults, effectively superseded)
- **Underlying**: wETH `0x4200000000000000000000000000000000000006` (18 dec); address embedded in ETHTVaultFactory.json bytecode
- **Paired fund**: ETH-T `0x80d1edd0236A06283fd1212FDB12cfA79516933d`; address embedded in ETHTVaultFactory.json bytecode
- **Implementation**: `0x3bB5f84c797e5932656AB66830bD901637DaE318` (v1 impl; ETHTVaultFactory predates the v2 FOT impl)
- **MIN_WETH**: 11,500,000,000,000,000 wei (= 0.0115 wETH; value 0x28db3066eac000 in bytecode)

## CharityFund Factory

### CharityFundFactory (key: create-fund)
- **Factory**: `0x955383723E8A1AD82800406D6f492260918DF882`
- **Source**: MfT-Addresses.md (verified on-chain 2026-07-14, implementation() read confirmed)
- **Implementation**: `0xBEA5c3D2dc02C4A8385896ca70CCC6345574c96f` (CharityFund logic, 15,135 bytes)
- **Deploys**: EIP-1167 minimal proxy clones of CharityFund
- **createFund selector**: `0x5c275a39`
- **Constraints**: charityBps >= 1000, charityBps + serviceBps <= 9000
- **No approvals needed** (pure clone deploy, no asset transfer at create time)
- **Infrastructure inherited** (cannot be overridden per-fund):
  - USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
  - Aave V3: `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5`
  - aUSDC: `0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB` (Base aUSDC)
  - mftUSD V2 (service leg): `0x85C78B8104D874d17e698b8c5678e3B8072347B1`
  - Reactor: `0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA`

## Abandoned / superseded factory addresses (do not use)

| Address | Reason |
|---|---|
| `0x54CBD993DD393D34fA9747134C65bFA2Ba0D9B3F` | Older BTCTVaultFactory (btct-vault-factory-deployment.json) — 0 vaults, superseded by fund-vault-factories-deployment.json v2 factory |
| `0x53d8AdA1EEA871689323f7bd4B6f2f6208079704` | Older ETHTVaultFactory entry in fund-vault-factories-deployment.json — superseded by calm-vault-etht-factory-deployment.json |
