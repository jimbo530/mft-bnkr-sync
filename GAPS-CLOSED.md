# BNKR Verification Audit — Resolution (grounded on-chain 2026-07-16)

BNKR flagged 3 verification / trust gaps. Every claim below is from an on-chain read or a verified explorer this session.

---

## Gap 2 — Reactor ownership & mutability — ✅ CLOSED
- **ReactorPrimeV3** `0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA` is **verified on Basescan** (compiler v0.8.34+commit.80d5c536, evmVersion cancun, optimizer 200). https://basescan.org/address/0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA#code
- BNKR's `owner()` reverted because the reactor uses **`admin()`**, not `owner()`.
- On-chain: `admin()` = `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10` — a **single admin, NOT a proxy or multisig** (`owner()` / `core()` have no selector).
- **How to read:** call `admin()`.

## Gap 3 — FTP recipient weights — ✅ CLOSED
- **FTP / FeedingPeopleVault** `0x873739aeD7b49f005965377b5645914b1D78Ccd3` is **verified on RH Blockscout** (since 2026-07-15). NOTE: use Blockscout's **v2** API — the v1 `/api` returns HTTP 500 (broken), which gives false "unverified" reads.
- BNKR's `getRecipients()` reverted — no such function. Read via **`recipients(i)`** + **`totalRecipientWeight()`**.
- **Live split (grounded):** every harvest splits in thirds —
  - LEG 1 → opsWallet `0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2`
  - LEG 2 → memeReactor / prime `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D` (as backed FTP)
  - LEG 3 → 4 recipients, total ACTIVE weight = 300:
    - `0x3dB6BF508060b51FFC2622b81B888442e7B60458` — BURGERS reactor — weight 100 → **33.3%**
    - `0x7562593D18e47aA40EfCd04468b3D5222A40bbf3` — weight 100 → **33.3%**
    - `0x261F76D20983f299962b1481d7968d2F27b79BB1` — community vault v2 — weight 100 → **33.3%**
    - `0xD3B0f45eF1924dB341DE9f02eC80f1d8D14e123F` — weight 100, **PAUSED (0%)**
  - Matches BNKR's doc: 4 slots, 3 active + 1 paused, includes the BURGERS reactor.
- Registry owner = `0xE2a4…` ; `memeReactor` + `opsWallet` are IMMUTABLE; recipient registry is ADD-ONLY (pause, never remove).

## Gap 1 — RH↔Base cross-chain flow — 📄 DOCUMENTED (see CROSS-CHAIN-FLOW.md)
- Bridge contracts: MRB-BASE `0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb` = `TasernBridgePolygon` (lock, 5234 B). MRB-RH `0xa819b6D99135222f604047A3304ba53424D4779d` = `TasernBridgeBase` (mint, 12206 B).
- **No black box in transit:** invariant holds — **4,000,000 MfT locked on Base = 4,000,000 MfT twin totalSupply on RH.** Neither vault paused; relayer address matches both sides. No EOA holds value mid-transit (user → lock vault → relayer mints twin → user on RH).
- ⚠️ **Grounded caveats:**
  1. Relayer `0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC` has **0 ETH on both chains** → any bridge transfer stalls until it is funded.
  2. MRB-BASE **`escapeHatchRenounced()` selector is absent** → `adminWithdraw` may be callable by owner `0xE2a4` → the lock vault is **NOT provably locked** (trust caveat; would require a redeploy with the renounce mechanism to make immutable).
  3. Relayer bot `mft-robinhood-relayer` is **ONLINE** — confirmed via pm2 on the VPS, ~3-day uptime (and `tasern-bridge-relayer` online ~9d). The bot is running and watching; the stall is purely caveat #1 (relayer wallet has 0 ETH for gas), not the bot being down. Fund `0x849639…` on both chains to make the running bot operational.

---
**Summary:** 2 of 3 gaps were not holes — the contracts were already verified; BNKR simply called the wrong getters (`owner()`→`admin()`, `getRecipients()`→`recipients(i)`). Gap 1's flow is clean, with 2 operational/trust caveats + 1 unconfirmed item flagged above.
