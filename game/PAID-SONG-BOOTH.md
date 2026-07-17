# PAID SONG BOOTH — spec for BNKR

Buy a band's song by X post. Payment routes through the MfT flywheel (funds trees on the way IN);
revenue splits to LP + real-world ops on the way OUT. Delivery = native-video reply (proven live
2026-07-16, tweet 2077889430078038083).

## Price — two tiers
- **Commission (a NEW song): 10,000 band tokens** → full routing (below) → SongRevenueSplitter 50/50 (LP + ops).
- **Pull (an EXISTING library song): 0.02 USDC** → straight to the **ops wallet** `0x0780…` (covers our per-delivery
  cost; no split). Kept tiny so people pull often — and since *we* post the reply, we also capture the X creator revenue.

The routing + splitter below apply to the **commission** tier. The **pull** tier is just: collect 0.02 USDC → ops,
then deliver the existing song.

## Payment IN — BNKR multi-hop (any token accepted)
User tags BNKR: *"buy an <band> song"* and pays with anything.
```
[any token] -> WETH -> USDC
  -> DEPOSIT USDC into the Money vault  ==> MINTS Money 1:1     <-- NOT a swap. This is the tree-funding hop.
     Money vault (CharityFund): 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072
     deposit(uint256) mints Money 1:1; the USDC parks in Aave.
  -> swap Money -> <band> token via the band/Money LP
  -> 10,000 <band> tokens acquired
```
The parked USDC's Aave yield splits **1/3 trees · 1/3 reactor · 1/3 holders** (the flywheel).
**So every song bought funds trees on the front end.** Mint Money — never buy it — or the charity hop is skipped.

## Revenue split OUT — the 10,000 <band> tokens
Route them through **SongRevenueSplitter** (contract below). Split **50 / 50**:
```
10,000 <band> tokens
  -> 50%  LP BUILD:  sell half of this 50% -> Money, then addLiquidity(<band>, Money) -> DEEPEN the band's LP
  -> 50%  OPS:       swap -> Money, transfer to OPS WALLET 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2
                     (PROJECT / ops wallet — pays real-world bills as needed)
```
Grows the band's liquidity + covers real operations. **No burn.**

## Delivery
BNKR replies to the request with the band's song as **native video** (song-booth.js mechanism —
`v1.uploadMedia(file,{mimeType:'video/mp4',longVideo:true})` -> `v2.tweet(reply)`).
Caption: `Title — Full Band`, then one cashtag (`$<BAND>` + CA), never tag @bankrbot.
Use the **corrected** catalog (band attribution fixed 2026-07-16; 40 mislabels repaired).

## Contract to deploy: SongRevenueSplitter (renounce-capable) — Coordinator is building the package
- Receives a band's tokens; `split()` performs the 50/50 (LP-build + Money->ops).
- Parameterized per band: band token + band/Money LP + Money + ops wallet.
- Ships one-way `renounceAdminWithdraw()` (holds value → must be renounce-capable at ship).
- BNKR-deployable (bytecode + args + FOR-BNKR.txt).

## Grounded addresses (verified this session)
| Role | Address | Source |
|------|---------|--------|
| Money (deposit → mint 1:1) | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` | FEE-FLOW-MAP §1.1 |
| Ops wallet (bills) | `0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2` | FEE-FLOW-MAP / wallet-map (PROJECT) |
| USDC (Base) | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | FEE-FLOW-MAP §1.1 |
| WETH (Base) | `0x4200000000000000000000000000000000000006` | Base canonical WETH |
| Band token + band/Money LP | per band — `songs-catalog.json` (tag+CA) + CommunityLPVaultV3 (band/Money V2) | catalog / FEE-FLOW-MAP §4.1 |

Canonical fund pathing: `C:\Users\bigji\flywheel-map\FLYWHEEL.md`. Money is 6 decimals — never assume 18.
