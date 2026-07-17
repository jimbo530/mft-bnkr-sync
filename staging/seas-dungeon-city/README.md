# seas-dungeon-city — package index

Builder pass 2026-07-17. Inventory + ordered plan for the Seize the Seas DUNGEON and
CITY-BUILDING systems, plus three factory-deployable packages. All chain claims
re-grounded on-chain that day (see the two read-only scripts).

| File / folder | What it is |
|---|---|
| `INVENTORY.md` | LIVE / GATED / MISSING state of both systems, every address verified |
| `PLAN.md` | Ordered phases A→D, founder decisions F1-F6, premature-lock watchlist |
| `verify-onchain.cjs` | Read-only re-grounding: 15 pools, StructureFactory, endowments, LootPoolV2 |
| `probe-artifact-provenance.cjs` | Proves PrizePool.json == the live pools' creation bytes (via live deploy tx) |
| `build-packages.cjs` | Deterministic builder of the three packages below (local files only) |
| `dungeon-coin-pools/` | READY: 3× PrizePool (COPPER/SILVER/GOLD dungeon prize pools) — FOR-BNKR.txt |
| `weth-court-endowments/` | READY: 5× CourtEndowment (WETH line taxing system, wired at construction) — FOR-BNKR.txt |
| `manufacturing-pool/` | HOLD: fork-verified artifact + recipe; founder-go pending — FOR-BNKR.txt |

Deploy rule for the READY packages: normal tx, `to` = DeployerFactory
`0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D` (Base 8453), `data` = the calldata file's
final blob, value 0. Deploy EMPTY only — no funding, no tribute(), no seal(); funding
is founder-paced (see PLAN.md F1/F2).

Provenance note: this package's files were committed inside the Coordinator's commit
`1993330` (a parallel session committed while these files were staged — content
unchanged); this README was added right after as the package's own marker.
