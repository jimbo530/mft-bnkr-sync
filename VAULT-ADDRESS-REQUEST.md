# Vault Address Request — 10 Bands Need CommunityLPVaultV3

## Status: ANSWERED 2026-07-17 — see `deployed/band-vaults.json`

**Answer in one line:** the 4 confirmed bands are now FULLY resolved (pending LP()/router cells filled below, all on-chain verified) — but **none of the 10 requested bands has a vault**. Verified absence, not a failed lookup: both vault factory registries were enumerated on-chain (17 vaults total, TOKEN() read on each — no match), and `v2Factory.getPair(Money, bandToken)` is the zero address for all 10, so the V2 pair a vault would wrap doesn't exist either. Full evidence + unblock path in `deployed/band-vaults.json`.

SongRevenueSplitter deployment is ready for 4 bands (EBM, RISH, BONGO, DGT) — all constructor args confirmed on-chain. 10 bands remain blocked on missing vault addresses.

## What's needed from Claude

For each of the 10 bands below, please provide:
1. The CommunityLPVaultV3 contract address on Base
2. The vault's `LP()` return value (V2 pair address)
3. The vault's `v2Router()` return value (Uniswap V2 router address)
4. The band token contract address (if not in songs-catalog.json)

Once provided, Bankr will deploy SongRevenueSplitter for each band via the factory at `0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D`.

## Confirmed (4 bands — deploying now)

All four rows below verified on-chain 2026-07-17 (vault TOKEN()/LP()/v2Router() read directly, code present at every address):

| Band | Vault | LP() | v2Router() | Band Token |
|------|-------|------|------------|------------|
| EBM | 0xdd47bdDD35866735ac79f9F3F8d4f0513555Ed95 | 0x7B053D6dCB7AfB45c5D57C85c0442312d9Cd04Dd | 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24 | 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d |
| RISH | 0x131bd427935980bbE43c30c3d0aF49e33c0E98E1 | 0x87E363B27A77C593965e8FAE9466d5f98fc3E408 | 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24 | 0x31c600871603bab5d855463E03c6d0a9eB661D26 |
| BONGO | 0x3aF2d7CCc05FdF3bC6Be14d1F159826b0f31198f | 0xEdA306F5ebC51144890E6b6Efc3511dc5593056D | 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24 | 0x85Dd5183D203CcE70b88234D31f075774AcCC453 |
| DGT | 0x43ebB722e17dBe698AA70A55Cb428b171A5da367 | 0x3E2F276Af52ED472b8f727083f1cBD047fE45692 | 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24 | 0x52414B7cD2FA723E1c8f9295EB29F16d15aA7BB9 |

## Missing (10 bands — VAULTS DO NOT EXIST ON-CHAIN)

Band token CAs are verified on-chain (code + symbol/name). Vault/LP columns are **VERIFIED MISSING**: neither vault factory registry contains a vault for these tokens, and no Money/band V2 pair exists (`getPair` = 0x0). Do not deploy splitters against these until vaults are created.

| # | Band | Band Token CA (verified) | Vault Address | LP() | v2Router() |
|---|------|--------------------------|---------------|------|------------|
| 1 | DD | 0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3 | MISSING | no V2 pair | n/a |
| 2 | Myco | 0x36A01B05cf86a170490E3Ba4981eFd12B559a5a3 | MISSING | no V2 pair | n/a |
| 3 | MR | 0x8d669b539C7801c1271BC484Bdd8a6084b7788e7 | MISSING | no V2 pair | n/a |
| 4 | JS | 0x16Ba11AeDA2Da0eb2C64Ff7d0e74884033Ef2C65 | MISSING | no V2 pair | n/a |
| 5 | NN | 0x2beBaBdF57597F3ce75BDC75FAD3C40C4A9Fc8cc | MISSING | no V2 pair | n/a |
| 6 | RickyBobbie | 0x95286F2cce3C2de48EB75bB4E2Ec004429F18E53 | MISSING | no V2 pair | n/a |
| 7 | HammerTone | 0x7B105F45ddaA689AfDa5606628761a9Fb2dCd826 | MISSING | no V2 pair | n/a |
| 8 | WarMachine | 0x6f45F5cE7027745b1Ab11D5493F187960D00FCfc | MISSING | no V2 pair | n/a |
| 9 | Biggins | 0x7C596a0d594D670ffB256bBfbB5379fC8Cf7d62B | MISSING | no V2 pair | n/a |
| 10 | Jasmine | 0x3a952eFa41501c0463Cf8Af9f821f8F549f47Edf | MISSING | no V2 pair | n/a |

**Caution:** DD (band) is not DDD (nation token 0x87CD3a19a30b7f714dd0D6020dAb8e9EBE4fe8C4). DDD *does* have a factory vault — it is NOT the DD band vault.

**Unblock path:** one `createVault(token, usdcAmount, tokenAmount, maxImpactBps)` per band on MfTVaultFactory `0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1` (pulls >= $10 USDC + band tokens, mints Money, creates + seeds the V2 pair, burns seed LP, clones the vault). After that each vault's LP()/v2Router() read exactly like the confirmed 4. Who runs/funds those 10 calls = founder decision.

## Constructor args for SongRevenueSplitter

```solidity
constructor(address _band, address _money, address _lp, address _v2Router, address _ops, address _admin)
```

Shared args (same for all bands):
- `_money` = 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 (MfT/Money vault)
- `_ops` = 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 (PROJECT wallet)
- `_admin` = 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 (agent wallet)

Per-band args:
- `_band` = band token contract address
- `_lp` = vault's LP() return value (V2 pair)
- `_v2Router` = vault's v2Router() return value

## Deploy path

Factory: `0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D`
Function: `deploy(bytes)` — selector `0x00774360`, fee = 0
The `bytes` argument = creation bytecode + ABI-encoded constructor args (6 addresses, each 32-byte word).
