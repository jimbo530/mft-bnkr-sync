# BNKR Song Booth Status

Last updated: Jul-17-2026 by Bankr agent

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

### Pending Deployments (args confirmed on-chain)

| Band | Band Token | LP Pair | Status |
|------|------------|---------|--------|
| BONGO | 0x85Dd5183D203CcE70b88234D31f075774AcCC453 | 0xEdA306F5ebC51144890E6b6Efc3511dc5593056D | NOT DEPLOYED — simulation reverted, investigating bytecode encoding |
| DGT | 0x52414B7cD2FA723E1c8f9295EB29F16d15aA7BB9 | 0x3E2F276Af52ED472b8f727083f1cBD047fE45692 | NOT DEPLOYED — pending BONGO fix |

LP pairs verified on-chain:
- BONGO LP: token0 = BONGO, token1 = mftUSD ✓
- DGT LP: token0 = DGT, token1 = mftUSD ✓

### Missing Vault Addresses (10 bands)

These bands need CommunityLPVaultV3 addresses before their splitters can be deployed. Need to ask Claude/jimbo for the vault addresses.

| Band | Status |
|------|--------|
| DD | Missing vault address |
| MYCO | Missing vault address |
| MR | Missing vault address |
| JS | Missing vault address |
| NN | Missing vault address |
| RICKY | Missing vault address |
| HT | Missing vault address |
| WM | Missing vault address |
| BIGGINS | Missing vault address |
| JASMINE | Missing vault address |

## Skill Installation

- mft-song-request skill: NOT INSTALLED
- Path attempted: skills/mft-song-request/SKILL.md
- Error: SKILL.md not found at that path in repo (branch: main)
- Need to verify correct path or add SKILL.md to repo

## Delivery Queue

- delivery-queue/ contains only .gitkeep
- No songs queued for X delivery yet

## Next Steps

1. Fix BONGO/DGT splitter deployment (investigate simulation revert)
2. Get missing vault addresses for 10 bands from Claude/jimbo
3. Install mft-song-request skill (fix SKILL.md path)
4. Begin routing song commissions through new splitters
