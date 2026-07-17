# GAMIFIED-NFT INVENTORY — text-RPG character loop (staging)

Grounded 2026-07-16 by reading the sources listed per row (stats-engine files, Tales-of-Tasern
src + contracts, mftusd-build sources, bankr-impact-network.csv). Spec: `game/TEXT-RPG-FLOW.md`
+ `game/DM-PROMPT.md`. Roles per COORDINATION.md: GPT = story/art · Claude = stats/packages ·
BNKR = payment/tracking/deploys/prizes.

## The loop we are wiring

```
player on X: "I want to adventure"
   ├─ HAS an NFT  → identify it ("play with #X") → stats-engine reads its LPs  (Entry A — LIVE)
   └─ NEW player  → race pick → GPT art + story start → createCharacter()      (Entry B — THIS PACKAGE)
→ character = a CONTRACT ADDRESS; its LP holdings = its D20 stats
→ turns are paid ($1 = 50 turns, payment mints Money → trees)                   (dep #4 — venue TBD)
→ quest resolves → pay-prize → cash to wallet OR LP INTO the character NFT      (dep #5 — reward = progression)
```

## How stats actually work (grounded, this session)

- `update-chain-data/route.ts` multicalls **`pair.balanceOf(characterContract)` on every
  KNOWN_LP_PAIR** (12 Base + 90 Polygon), derives underlying token amounts from LP share ×
  reserves, prices them, writes to **Supabase `nft_backing`**. The game (`useNftStats.ts`)
  reads Supabase first and runs `computeD20Stats` client-side.
- **ONLY LP-pair tokens held AT the character's contract address count.** Raw ERC20s sent to
  the address do NOT move stats. To grow a stat: add liquidity on a registered pair and send
  the LP tokens to the character address.
- **Ownership check** = ERC1155 `balanceOf(wallet, 1)` (`useNftStats.ts:249-253`). Token id is
  always 1. One contract per character.
- `computeD20Stats.ts`: USD → points in brackets (first 10 pts $1/pt, next 10 $10/pt, ×10 per
  bracket). Token→stat mapping (EGP→DEX/INT/WIS, BURGERS→CON×3 @1.5x, stables→all 6 @0.5x,
  MfT→all 6 @0.5x/6, etc.) + `boons.ts` (CHAR/NCT/BCT carbon, tree, storm, WETH/WBTC/WPOL boons).
- **Shared editions** divide backing by supply via `NFT_SUPPLY_DIVISOR` (route.ts:132-137 —
  e.g. Guards of Kardov's Gate /300, Space Donkeys /1163, MycoVault /80, Goblins /50).
- Registry is **Supabase-first with hardcoded fallback** (route.ts:156-168): new characters =
  registry inserts (nft-lp-database → sync → Supabase). **No game redeploy needed.**

## Inventory — every gamified-NFT piece

| Piece | Where | Status | Role in the loop |
|---|---|---|---|
| **Stats engine** (contracts.ts / computeD20Stats.ts / boons.ts) | `game/stats-engine/` (synced from `Tales-of-Tasern/src/lib/`) | **LIVE** (Supabase pipeline serving the game) | THE core: LPs → D20 stats. Reuse as-is for the text RPG. |
| **Character NFT registry** — 209 characters (27 Base + 182 Polygon) | `GAME_NFTS` in contracts.ts; source of truth `nft-lp-database/nfts.json`; Supabase `getSharedNfts()` | **LIVE on-chain** (each = its own contract, token id 1; incl. Kardov's Gate + all legacy POL NFTs) | Entry A: legacy players "call in" any of these — engine already reads them. Zero new infra. |
| **Chain-data reader** | `Tales-of-Tasern/src/app/api/update-chain-data/route.ts` → Supabase `nft_backing` | **LIVE** | Refreshes every character's LP backing on both chains. |
| **Character mint path** (TasernCharacterFactory + TasernCharacter) | `staging/gamified-nfts/character-nft/` | **NEW — this package** (compiled + 34/34 local EVM tests) | Entry B: BNKR-callable mint for new players. |
| **PowerVault suite** (PowerVault / CrossChainVault / VaultFactory / GenericVaultRouter) | `Tales-of-Tasern/contracts/VaultSystem.sol`; UI `src/components/PowerUp.tsx` | Source in repo; **8 PowerUp instances wired in the live game UI** (7 Base + 1 POL addresses in PowerUp.tsx; on-chain state not re-verified this session) | One-click WETH → LP → stat boost. The LP-zap pattern dep #5 reuses (target = character address). 1-of-1 rule: shared-edition vault stakes are banned (PowerVault design). |
| **Seas crew collections** (FeeShareDistributorV2 — 100-seat ERC721 fee-share, baseURI→crew-meta) | `mftusd-build/FeeShareDistributorV2.sol`; live: 4 in GAME_NFTS + Verdant Warden (bankr-impact-network.csv rows 237-240) | **LIVE on Base** | Playable via Entry A (shared-edition divisor applies). Also the movable-baseURI metadata pattern this package ports. |
| **PrizePool system** | canonical `mftusd-build/PrizePool.sol`; 15 tier pools live on Base (per reference_prize_pool_system); RH deploy = queue Task 1 (`prize-pool-rh/`) | **LIVE (Base)** / queued (RH) | Dep #5 cash leg: claim() pays the winner's wallet. Add-only, no-rug. |
| **GearStore1155** (open-mint USDC gear, burn-on-loss, proceeds→impact) | `MfT-Launch/contracts/GearStore1155.sol` | Built; deploy not verified this session | Later: GEAR line of the DM state block. |
| **ItemTokenFactory** (item ERC20s, 100B fixed, add-only registry) | `mftusd-build/ItemTokenFactory.sol` | Built; live for Seas items per project notes (not re-verified this session) | Later: loot/VAULT items as tokens. |
| **BaselingNFT** (ERC721 + per-tokenId forever-locked LP vault + POOP) | `Tales-of-Tasern/contracts/BaselingNFT.sol`; House NFT 0x70Ff566A… per CSV row 232 | Built; pet game | Sibling pattern ("the baseling IS its vault") — same sell-the-NFT-sell-the-vault semantics as characters. |
| **MemeTrees / MemeTreesV4** (mint-funded Water-backed art) | `mftusd-build/MemeTrees.sol` (+V4); MT4 live 0x07EA5415… per CSV row 233 | **LIVE** | Different backing rail (Water vault, not LP-at-address). Not part of this loop. |
| **DM spec** | `game/DM-PROMPT.md` + `game/TEXT-RPG-FLOW.md` | Committed | GPT runs story/art; state block (STATUS/CHARACTER/GEAR/VAULT) is what BNKR tracks. |
| **Turn credits** ($1 = 50 turns, mint-Money route) | — | **NOT BUILT — venue TBD (flag)** | Dep #4. |

## Dependency order — end to end

0. **(LIVE)** Stats engine + 209-character registry + Supabase pipeline. Nothing to build.
1. **Character factory** ← THIS PACKAGE (`character-nft/`). Founder confirms CHAIN → promote to
   TASKS-FOR-BNKR → BNKR deploys ONCE → pushes `deployed/tasern-character-factory.json`.
2. **Registry sync loop** (Coordinator): watch `CharacterCreated` events → add each new character
   contract to `nft-lp-database/nfts.json` (DB-first rule) → `npm run sync-contracts` + Supabase
   shared registry → next `update-chain-data` run starts reading its LPs. No game redeploy.
3. **BNKR entry skill**: parse "I want to adventure" →
   - *Identify existing*: scan the player's wallet against GAME_NFTS (`balanceOf(wallet, 1)`
     per contract — exactly `useNftStats.checkOwnership`) → confirm "playing as <name>".
   - *New*: collect name + race (roster: human / dwarf / elf / goblin / orc / dragonborn — the 6
     live crew species; game-layer, contract stores any string ≤32 bytes) → GPT art + story start
     → `createCharacter(player, name, race)` → hand the new address to the Coordinator (step 2).
4. **Turn credits** — $1 = 50 turns, payment routed like the song booth (pay-anything → WETH →
   USDC → `deposit()` MINTS Money → …). **FLAGGED: venue TBD** (BNKR-side ledger vs small
   contract) + chain TBD. Story posts decrement; BNKR tracks per TEXT-RPG-FLOW §4.
5. **Rewards → NFTs** (reward IS progression):
   - *Cash leg (LIVE)*: pay-prize → `PrizePool.claim()` → winner's wallet (15 pools on Base).
   - *Progression leg (SMALL BUILD)*: prize → LP-zap INTO the character: swap half the prize
     token, `addLiquidity` on a KNOWN_LP_PAIR, transfer the LP tokens to the character's
     CONTRACT ADDRESS → stats grow on the next chain-data pass. The zap is the existing
     `GenericVaultRouter.powerUp` pattern with the destination = character address instead of a
     vault. **Next package candidate** (raw token transfers to the NFT do NOT move stats).
   - NOTE: renounce the factory hatch BEFORE real prize value flows into characters (pre-renounce
     the build admin can still recover from children — that is the point during test, a rug
     surface after).
6. **BNKR conventions**: don't-reply marker on our story posts + pay-prize command (TEXT-RPG-FLOW
   §3). BNKR-side, no contract.
7. **Later packages**: GearStore1155 port (GEAR), ItemTokenFactory loot (VAULT), endowment ending
   (DM-PROMPT rule 6 — CourtEndowment pattern), club sponsorship kits.

## Open decisions — FOUNDER (do not guess)

1. **Chain for character NFTs + turn credits: Base vs Robinhood.** Grounded lean = Base: the
   stats engine reads Base+Polygon LP pairs only; all 27 recent character mints are Base; MfT +
   the 12 Base pairs live there; RH has zero registered stat-LPs today (characters there would
   read all-1s until an RH pair registry exists). Package is compiled chain-agnostic (paris) —
   deploy target awaits the founder's call.
2. **Turn tracking: on-chain contract vs BNKR-side ledger.** COORDINATION says BNKR = tracking;
   an on-chain version is a small PrizePool-shaped credits contract if wanted.
3. **Open mint vs allowlist**: factory ships allowlisted (deployer + agent admin can mint;
   admin can `setOpenMint(true)` later without redeploy). Founder call on when/if to open.

## First package

`staging/gamified-nfts/character-nft/` — TasernCharacterFactory + TasernCharacter.
Compiled solc 0.8.35+commit.47b9dedd (viaIR, 200 runs, paris). Factory runtime 9,964 B, child
4,794 B. Deploy 2,289,988 gas; createCharacter 1,207,360 gas (local EVM, 34/34 checks passed:
mint / reader-exact ownership / transfer / minter gate / hatch recover / fleet-wide one-way
renounce incl. children born after). Renounce-capable from day one per the ship rule.
