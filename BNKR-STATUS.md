# BNKR Song Booth Status

Last updated: Jul-17-2026 by Bankr agent (session 3 — BONGO + DGT deployed)

## CommissionBooth (RETIRED)
- Address: 0xC094664560024e77A710B80D08d15B15EDE0a4a7
- Status: RETIRED — replaced by SongRevenueSplitter
- 14 bands registered, price = 100k band tokens per song

## SongRevenueSplitter Deployments

Factory: 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D
Deploy fn: deploy(bytes) — selector 0x00774360, fee = 0
Constructor: (address _band, address _money, address _lp, address _v2Router, address _ops, address _admin)

Shared args:
- _money: 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072
- _v2Router: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
- _ops: 0x0780b1456d5e60cf26c8cd6541b85e805c8c05F2
- _admin: 0xE2a4a8b9d77080c57799a94ba8edeb2dd6e0aC10

### Deployed Splitters

| Band | Splitter Address | Band Token | LP Pair | Tx Hash | Block | Status |
|------|-----------------|------------|---------|---------|-------|--------|
| EBM | 0x3366340eCB42AC8c209fA5B6f21e03E439521501 | 0xF113fe2a0e1181a21fa97b1f52ff232140b7692d | 0x7B053d6dcb7afb45c5d57c85c0442312d9cd04Dd | 0xe7185ce8b7ece15d2c6f6af37c4c1d8b34539696facca36438f36ea5d0d1a259 | 48752063 | LIVE |
| RISH | 0x54d2a9D01d0f796b23d1085fc1efBabb251125F5 | 0x31c600871603bab5d855463e03c6d0a9eb661d26 | 0x87E363b27a77c593965e8fae9466d5f98fc3E408 | 0x86d00cd77109c80db45936059695547a1ddbfe3d6fc784580b53957926cb7d0b | 48752190 | LIVE |
| BONGO | 0x1Ce4D413637D6e876139AcB2E75BDf4A2F0a8351 | 0x85Dd5183D203CcE70b88234D31f075774AcCC453 | 0xEdA306F5ebC51144890E6b6Efc3511dc5593056D | 0x0ee05f495857998483936d2b5f0719a9ec424d445778253669c27069d582af3e | 48753528 | LIVE |
| DGT | 0x3753674fFc1d4417372FF603b6F3Aab619B8aFD2 | 0x52414B7cD2FA723E1c8f9295EB29F16d15aA7BB9 | 0x3E2F276Af52ED472b8f727083f1cBD047fE45692 | 0x7b5b48a850ba60e5bb2b82db3f73bbce143471ad862bfaf912ee3559670e8acc | 48753530 | LIVE |

### Missing Vault Addresses (10 bands)

These bands need CommunityLPVaultV3 addresses before their splitters can be deployed. Need to ask Claude/jimbo for the vault addresses.

| Band | Band Token | Status |
|------|------------|--------|
| DD | 0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3 | Missing vault address |
| MYCO | 0x36A01B05cf86a170490E3Ba4981eFd12B559a5a3 | Missing vault address |
| MR | 0x8d669b539C7801c1271BC484Bdd8a6084b7788e7 | Missing vault address |
| JS | 0x16Ba11AeDA2Da0eb2C64Ff7d0e74884033Ef2C65 | Missing vault address |
| NN | 0x2beBaBdF57597F3ce75BDC75FAD3C40C4A9Fc8cc | Missing vault address |
| RICKY | 0x95286F2cce3C2de48EB75bB4E2Ec004429F18E53 | Missing vault address |
| HT | 0x7B105F45ddaA689AfDa5606628761a9Fb2dCd826 | Missing vault address |
| WM | 0x6f45F5cE7027745b1Ab11D5493F187960D00FCfc | Missing vault address |
| BIGGINS | 0x7C596a0d594D670ffB256bBfbB5379fC8Cf7d62B | Missing vault address |
| JASMINE | 0x3a952eFa41501c0463Cf8Af9f821f8F549f47Edf | Missing vault address |

## Skill Installation

- mft-song-request skill: NOT INSTALLED
- SKILL.md exists at skills/mft-song-request/SKILL.md (confirmed in repo)
- Coordinator says: skip skill install — founder's bot handles delivery, BNKR handles transactions only
- Drop this thread

## Delivery Queue

- delivery-queue/ contains only .gitkeep
- No songs queued for X delivery yet
- Founder's bot handles delivery, not BNKR

## Role (per coordinator)

- BNKR handles TRANSACTIONS: debit customer Bankr wallet (0.02 USDC for pull / route 10k band tokens for commission) + mint
- Founder's bot recognizes request + posts song
- BNKR does NOT need mft-song-request/delivery skill

## Next Steps

1. Get missing vault addresses for 10 bands from Claude/jimbo (TASKS-FOR-CLAUDE.md pushed)
2. Once vaults received → batch-deploy all 10 remaining splitters
3. Confirm debit flow: user tags BNKR → debit 0.02 USDC from Bankr wallet to ops → write delivery-queue entry
4. PUBLIC-TOOL-REQUEST.md pushed for generic RevenueSplitter as Bankr ecosystem tool
