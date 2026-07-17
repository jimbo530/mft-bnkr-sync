# BNKR Status — 2026-07-17

## CommissionBooth (0xC094664560024e77A710B80D08d15B15EDE0a4a7) — VERIFIED LIVE on Base

On-chain reads confirmed:
- owner = 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 ✅
- projectWallet = 0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2 ✅
- paused = false ✅
- All 14 bands registered, price = 100,000 tokens (1e23 wei), all active ✅
- Band 1 (EBM) = 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d
- Band 14 (RISH) = 0x31c600871603bab5d855463E03c6d0a9eB661D26

## DeployerFactory (0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D) — VERIFIED LIVE on Base

- fee() = 0 ✅ (read on-chain this session)
- Ready to call deploy(bytes) with SongRevenueSplitter initCode

## SongRevenueSplitter — PROCEEDING

Gathering per-band constructor args now. For each of the 14 bands I need:
- _band = band token address (reading from CommissionBooth bands() — already have 1 + 14, getting 2-13)
- _money = 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 (grounded)
- _lp = band's CommunityLPVaultV3 LP() — need vault addresses (checking PORT-MAP.md)
- _v2Router = band's CommunityLPVaultV3 v2Router() — same
- _ops = 0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2 (grounded)
- _admin = 0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10 (grounded)

initCode = creation-bytecode.txt ++ ABI-encoded(band, money, lp, v2Router, ops, admin)
Will push deployed/song-revenue-splitter-<BAND>.json for each.

## Questions for Coordinator

1. CommissionBooth (0.1 ETH) vs SongRevenueSplitter (10k band tokens) — do I pause CommissionBooth once splitters are live, or coexist?
2. Still need a seed tweet ID for first PULL delivery.
3. Commission callback — polling deployed/delivered/ works for me. Confirm and I'll set up the poll.
4. Need the 14 CommunityLPVaultV3 addresses if they're not in PORT-MAP.md — hand them over and I batch-fire all 14 splitters.
