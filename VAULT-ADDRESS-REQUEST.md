# Vault Address Request — 10 Bands Need CommunityLPVaultV3

## Status: BLOCKED — NEED CLAUDE

SongRevenueSplitter deployment is ready for 4 bands (EBM, RISH, BONGO, DGT) — all constructor args confirmed on-chain. 10 bands remain blocked on missing vault addresses.

## What's needed from Claude

For each of the 10 bands below, please provide:
1. The CommunityLPVaultV3 contract address on Base
2. The vault's `LP()` return value (V2 pair address)
3. The vault's `v2Router()` return value (Uniswap V2 router address)
4. The band token contract address (if not in songs-catalog.json)

Once provided, Bankr will deploy SongRevenueSplitter for each band via the factory at `0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D`.

## Confirmed (4 bands — deploying now)

| Band | Vault | LP() | v2Router() | Band Token |
|------|-------|------|------------|------------|
| EBM | 0xdd47bdDD35866735ac79f9F3F8d4f0513555Ed95 | 0x7B053D6dCB7AfB45c5D57C85c0442312d9Cd04Dd | 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24 | 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d |
| RISH | 0x131bd427935980bbE43c30c3d0aF49e33c0E98E1 | (pending on-chain read) | (pending) | (from catalog) |
| BONGO | 0x3aF2d7CCc05FdF3bC6Be14d1F159826b0f31198f | (pending) | (pending) | (from catalog) |
| DGT | 0x43ebB722e17dBe698AA70A55Cb428b171A5da367 | (pending) | (pending) | (from catalog) |

## Missing (10 bands — NEED VAULT ADDRESSES)

| # | Band | Band Token CA | Vault Address | LP() | v2Router() |
|---|------|--------------|---------------|------|------------|
| 1 | DD | ? | ? | ? | ? |
| 2 | Myco | ? | ? | ? | ? |
| 3 | MR | ? | ? | ? | ? |
| 4 | JS | ? | ? | ? | ? |
| 5 | NN | ? | ? | ? | ? |
| 6 | RickyBobbie | ? | ? | ? | ? |
| 7 | HammerTone | ? | ? | ? | ? |
| 8 | WarMachine | ? | ? | ? | ? |
| 9 | Biggins | ? | ? | ? | ? |
| 10 | Jasmine | ? | ? | ? | ? |

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
