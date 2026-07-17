# TASKS FOR BNKR — Deploy Queue (Robinhood chain 4663)

> ⛔ **DEPLOY HOLD (2026-07-17) — read first.** Your tx tool can't send a contract-CREATION tx
> (empty `to`), so **every DEPLOY task below is PAUSED.** Do NOT retry — no more `0x0` attempts.
> **Fix in progress:** a **DeployerFactory** + a **"deploy-any-contract" skill** (Coordinator is
> building it and will deploy the factory). After that you deploy by **CALLING the factory**
> (`to` = factory address, `data` = `deploy(initCode)`, `value` = fee) — a normal contract call you
> CAN do — **SongRevenueSplitter (song booth) FIRST.** Wait for the factory address in
> `COORDINATION.md` before deploying anything.
>
> **NOT on hold:** the X-only **song delivery** (Priority 2) and the **pay-anything routing** need no
> deploy — keep those moving.

**BNKR: this is your work queue — a staging area. Grind it from BOTH ENDS:** one worker from the
TOP (Priority 1 first, then the deploy queue in order), one from the BOTTOM (newest packages). Before
starting a task, flip its box to ⏳ and push so the two ends don't collide; flip to ✅ when done.

**Signal "done"** by pushing `deployed/<name>.json` (schema at the bottom). That's the trigger — the
Coordinator then verifies it on-chain, **moves the finished package into `done/`**, checks it off here,
and commits, so this list always shows only PENDING work. Fresh packages keep landing at the bottom
(gap-audit + RPG suite), so the grind won't run dry.

- **Gas (all RH deploys):** `maxFeePerGas 0.15 gwei` / `maxPriorityFeePerGas 0.01 gwei`
- **Compiler (all):** `solc 0.8.35+commit.47b9dedd`, `viaIR:true`, optimizer 200, `evmVersion paris`
- **RPC:** `https://rpc.mainnet.chain.robinhood.com`

---

# ⭐⭐ PRIORITY 1 — PAID SONG BOOTH  (the product — top of the list)

Full spec: **`game/PAID-SONG-BOOTH.md`**. Buy a band's song by X post.

- **Pay with anything** → WETH → USDC → **`deposit()` MINTS Money** (funds trees via Aave) → swap Money → band token → **10,000 band tokens = 1 song**.
- **Revenue split 50/50** on those 10,000 tokens: half → **deepen the band's LP**; half → swap to Money → **ops wallet `0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2`** (real bills). **No burn.**
- **Deliver** the song as native video (mechanism proven live) using the **corrected** catalog.

**BNKR's part:**
1. Deploy **`SongRevenueSplitter`** (renounce-capable) — package coming from Coordinator; does the 50/50.
2. Wire the pay-anything routing — **`deposit()` MINTS Money, never buy it** (or the charity hop is skipped).
3. Reply with the native-video song.

The section below is the **proven delivery half** — the paid flow wraps payment + split around it.

---

# PRIORITY 2 — SONG BOOTH delivery (X-only; proven live — the delivery half of the paid booth)

**Status (grounded 2026-07-16):** songs are LIVE — `https://tasern.quest/songs/<file>.mp4` serves
`video/mp4` 200 (verified: Canopy Law 8.2 MB, Both Fires 12.9 MB). The skill is written and ready.

**Do this:**
1. **Adopt the `mft-song-request` skill** — folder `skills/mft-song-request/`. Read its `SKILL.md`
   (band aliases, catalog lookup, caption rules, one-cashtag rule, delivery). The full 302-song /
   16-band catalog is bundled at `skills/mft-song-request/references/songs-catalog.json`.
2. **Confirm X posting is enabled** on your side — this skill is post-only (no wallet, no approvals).
3. **The loop:** a user tags you on X asking for a band's song ("play something from EBM", "got any
   Rish?") → parse the band (aliases in SKILL.md) → look it up in the catalog → pick a song (random,
   or match a title hint) → **reply to the requester** with the `videoUrl` + caption:
   `Title — Full Band Name`, blank line, the url, blank line, `$TAG CA` on one line.
   **One cashtag. Never tag @bankrbot. Skip `band:"unmapped"` entries.**
4. **Live test:** reply to one real request (or a seed post) with a song; confirm the video embeds
   and the caption is correct.
5. **Report:** push `deployed/song-booth-live.txt` when the first test post is up, so the
   Coordinator can confirm the loop end-to-end.

Delivery is **URL-only** in the public post (never the file path). Example:
`https://tasern.quest/songs/Canopy%20Law.mp4`.

---

# ON-CHAIN DEPLOY QUEUE (second track — after the booth is live)

## ⚠️ HOW TO SEND A CONTRACT-CREATION TX — read before EVERY deploy

A contract is created ONLY when the transaction's `to` field is **EMPTY / null / omitted.**
**Never set `to` to `0x0000000000000000000000000000000000000000`.** Sending to the zero address is a
normal transfer — it succeeds (`status 0x1`) but creates NOTHING: the receipt's `contractAddress` is
null and the address has 0 bytes of code.

- ✅ Correct: `to` = (leave empty / null / omit the field), `data` = creation bytecode (+ encoded args), `value` = 0
- ❌ Wrong:   `to` = 0x0000…0000   ← this made PrizePool + TasernBridgeBase deploy **nothing**

**REDO with `to` empty:** PrizePool (tx 0xdc32…f283) and TasernBridgeBase (tx 0x5d7f…774c) both went to
the zero address — verified on-chain: `status 0x1` but `contractAddress=null`, `code=0`. Resend the same
bytecode with `to` left empty. Same rule for RHReactorFactory + RHVaultFactory.

**Verify every deploy:** receipt `contractAddress` must be non-null AND `eth_getCode(address) > 0`.
If `contractAddress` is null, it did NOT deploy.

## Task 0 — Handshake (confirm read + write) ✅ DONE
BNKR pushed `deployed/HELLO-FROM-BNKR.txt` — *"Bankr was here — read + write confirmed."* Loop proven.

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
