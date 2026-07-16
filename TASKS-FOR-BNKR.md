# TASKS FOR BNKR — Deploy Queue (Robinhood chain 4663)

**BNKR: this is your work queue. Do the tasks top-to-bottom.** After each deploy, push the
result to `deployed/<name>.json` (schema at the bottom) so the Coordinator can verify it
on-chain, wire the next piece, and update the fee-flow map.

- **Gas (all RH deploys):** `maxFeePerGas 0.15 gwei` / `maxPriorityFeePerGas 0.01 gwei`
- **Compiler (all):** `solc 0.8.35+commit.47b9dedd`, `viaIR:true`, optimizer 200, `evmVersion paris`
- **RPC:** `https://rpc.mainnet.chain.robinhood.com`

---

## Task 0 — Handshake (confirm read + write) ⬜
Push a one-line file `deployed/HELLO-FROM-BNKR.txt` (your address + a timestamp is fine).
**Why first:** proves the deploy key has working read+write **before** any gas is spent. The
Coordinator confirms it the instant it lands. No on-chain action.

## Task 1 — PrizePool ⬜  *(START HERE — simplest, proves the deploy pipeline)*
- **Folder:** `prize-pool-rh/`  ·  **Read:** `prize-pool-rh/FOR-BNKR.txt`
- **What:** USDG prize/achievement vault. Add-only, claim-only — **no adminWithdraw, no-rug by design.**
- **Constructor args (2):**
  - prizeToken (USDG) `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`
  - admin `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`
- **No AMM.** Smallest contract — the clean proof that deploys land (this is the one the free agent botched to `0x0`; land it here).
- **Push:** `deployed/prize-pool.json`

## Task 2 — TasernBridgeBase (RH leg) ⬜
- **Folder:** `tasern-bridge-rh/`  ·  **Read:** `tasern-bridge-rh/FOR-BNKR.txt`
- **What:** mint/burn side of the POL↔RH nation-token bridge. **No constructor args** (owner = deployer). No adminWithdraw on this side.
- **Post-deploy (owner-only):** `setRelayer(0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC)`, then `deployTwin(...)` per token — read name/symbol/decimals/cap from the Polygon original, **don't guess cap.** Start `setPaused(true)` while testing.
- **Push:** `deployed/tasern-bridge.json` (include every `TwinDeployed` twin address)

## Task 3 — RHReactorFactory ⬜  *(HIGH — reactor infra for every launch token)*
- **Folder:** `rh-reactor-factory/`  ·  **Read:** `rh-reactor-factory/FOR-BNKR.txt`
- **What:** stamps one V4 child reactor per token (burns core fees, compounds paired, 10% upstream to the live prime `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D`).
- **Constructor args (6):** ABI-encoded in `constructor-args-encoded.hex`. Full deploy data = `creation-bytecode.txt` **+** `constructor-args-encoded.hex` concatenated.
- **Post-deploy:** `createReactor(coreToken)` per token → then `reactor.acceptAdmin()` on the new child.
- **Renounce:** child reactors expose one-way `renounceAdminWithdraw()` — **keep withdrawable while testing; renounce at ship** (Coordinator signals when).
- **Push:** `deployed/reactor-factory.json`

## Task 4 — RHVaultFactory ⬜  *(HIGH — public community-vault creation; most steps)*
- **Folder:** `rh-vault-factory/`  ·  **Read:** `rh-vault-factory/FOR-BNKR.txt`
- **What:** CREATE2-deploys a fresh BurgersCommunityVault per call — all RH addresses baked in, **no constructor args.**
- **Deploy:** full tx.data from `creation-bytecode.txt` ("FULL deploy tx.data" section), ~2.2M gas.
- **Post-deploy:** `createVault(owner, tickLower=416600, tickUpper=424800, salt)` → mint a BURGERS/FTP position to the vault → `vault.adoptPosition(tokenId)` to activate.
- **Renounce:** vault exposes one-way `renounceAdminWithdraw()` — **withdrawable during test, renounce at ship.**
- **Push:** `deployed/vault-factory.json`

---

## After EVERY deploy — push `deployed/<name>.json`
```json
{
  "contract": "PrizePool",
  "chainId": 4663,
  "address": "0x...",
  "txHash": "0x...",
  "deployer": "0x...",
  "constructorArgs": ["0x5fc5360D...", "0xE2a4A8b9..."],
  "abi": [ ... ],
  "deployedAt": "2026-07-16T00:00:00Z",
  "explorerUrl": "https://robinhoodchain.blockscout.com/address/0x...",
  "verified": false,
  "notes": ""
}
```
The Coordinator reads `deployed/`, verifies each on-chain, wires the next piece, and updates
`FEE-FLOW-MAP.md` / `GAPS-CLOSED.md`. Also verify source on the RH Blockscout explorer when possible.

## Renounce rule (all fund-holding contracts)
Build **withdrawable**, renounce at **ship**. PrizePool + BridgeBase have **no** adminWithdraw
(already locked). Reactors + vaults expose one-way `renounceAdminWithdraw()` — do **NOT** call it
during testing; the Coordinator signals ship-time.

## HELD — do NOT deploy yet (needs a founder decision or a missing RH dependency)
Grounded from `PORT-MAP.md`:
- **BTCTVaultFactory / ETHTVaultFactory / PRGTVaultFactoryFOT** — need RH cbBTC / WETH / PRGT + a confirmed RH V2 (or a V4-seed rewrite). Parked.
- **CharityFundFactory / CharityFund / MoneyForTreesV2 / CourtEndowment** — Aave-specific; RH uses Morpho (FTP/GST already live). Need a Morpho-clone rewrite. Parked.
- **FundVaultFactory / MfTVaultFactory(FOT)** — depend on a confirmed RH V2 factory/router (not found in any file). Gate before deploy.
- **Game-economy factories** (ItemTokenFactory, LocationLPFactory, StructureFactory, ManufacturingPool) — no local `.sol`; source lives on the VPS. Coordinator recovers first.

## COMING NEXT (Coordinator is building — new packages will appear here)
- **Character NFT** + **item tokens** + **stats system** for the X text-RPG. Each lands in its own
  folder with a `FOR-BNKR.txt` and gets added to this queue.
