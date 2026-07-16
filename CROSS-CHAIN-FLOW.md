# MfT Cross-Chain Flow: Base (8453) ↔ Robinhood Chain (4663)

**Purpose:** Close the BNKR "cross-chain flow / black box in transit" gap.
**Ground truth:** local source files in `mftusd-build/` + on-chain reads 2026-07-16. VPS pm2 status unverified (SSH blocked during this session — flagged where relevant).

---

## Address Map

| Role | Label | Chain | Address | Verified |
|------|-------|-------|---------|---------|
| MfT original token | MFT-BASE | Base 8453 | `0x8FB87d13B40B1A67B22ED1a17e2835fe7e3a9bA3` | on-chain: name=MemeForTrees, sym=MfT, 18 dec, supply=100B |
| Lock vault (origin) | MRB-BASE | Base 8453 | `0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb` | on-chain: code=5234 bytes, role=TasernBridgePolygon |
| Twin factory (dest) | MRB-RH | RH 4663 | `0xa819b6D99135222f604047A3304ba53424D4779d` | on-chain: code=12206 bytes, role=TasernBridgeBase |
| MfT bridged twin | MFT-RH | RH 4663 | `0x6ae576608725677Bf8D05EA7796849E6F8F57608` | on-chain: name=MemeForTrees, sym=MfT, 18 dec |
| Relayer wallet | TB-RELAY | both | `0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC` | on-chain: set as relayer on both vaults |
| Owner / deployer | AGENT | both | `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10` | on-chain: owner on both vaults |

---

## Contract: TasernBridge (both vaults use same bytecode)

Source: `C:\Users\bigji\Documents\mftusd-build\contracts\TasernBridge.sol`

Two concrete contracts in that file:

**TasernBridgePolygon** — the LOCK / origin role (deployed on Base as MRB-BASE)
- `bridgeToBase(token, amount, baseRecipient)` — user-callable. Does `transferFrom(user → vault)`, increments `outboundNonce`, emits `Locked(nonce, token, from, baseRecipient, amount)`.
- `release(inboundNonce, token, to, amount)` — relayer-only. Transfers tokens out of vault to recipient. Marks nonce processed on-chain.
- `adminWithdraw(token, to, amount)` — owner-only escape hatch. Callable only while `escapeHatchRenounced == false`. Status on MRB-BASE: **the on-chain call to `escapeHatchRenounced()` reverted** — the function selector is not present in this deploy, which means the contract was deployed WITHOUT that storage variable, i.e., this is an earlier version of TasernBridgePolygon that does not include the escape hatch / renounce mechanism. `adminWithdraw` itself may or may not be present; cannot confirm without ABI-level selector check. **FLAG: owner (0xE2a4) may be able to withdraw locked MfT — this is a trust assumption, not a fully renounced vault.**

**TasernBridgeBase** — the TWIN / destination role (deployed on Robinhood as MRB-RH)
- `deployTwin(polygonToken, name, symbol, decimals, cap)` — owner-only. Deploys a `BridgedToken` child contract. Called once per asset.
- `mintFromPolygon(inboundNonce, polygonToken, to, amount)` — relayer-only. Mints twin tokens to recipient. Marks nonce processed on-chain.
- `bridgeToPolygon(twin, amount, polygonRecipient)` — user-callable (return direction). Burns twin from caller, increments outboundNonce, emits `Burned`.

**Replay protection:** Each outbound transfer gets a monotonically incrementing `outboundNonce`. The receiving side stores each `inboundNonce` in `processedInbound[nonce] = true` before acting. The relayer is idempotent — re-scanning cannot double-deliver.

---

## Hop 1: Base → Robinhood (MfT lock → twin mint)

### Step 1 — User: lock on Base

**Who acts:** the sender (user wallet or `bridge-mft-to-rh.cjs` running as coordinator/agent `0xE2a4`)

**Contract called:** MRB-BASE `0xD793...` on Base

**Function:** `bridgeToBase(0x8FB8..., amount, rhRecipient)`

**What happens on-chain:**
1. `transferFrom(sender, MRB-BASE_vault, amount)` — MfT moves from user wallet into the vault contract. At this point MfT is held by the lock vault.
2. `outboundNonce++` — e.g. if nonce was 1, it becomes 2 (current on-chain outboundNonce = 2, meaning 2 outbound Base→RH transfers have been initiated).
3. Emits `Locked(nonce, 0x8FB8..., sender, rhRecipient, amount)`.

**Who holds the value during transit:** MRB-BASE vault contract `0xD793...` holds the MfT. No wallet or EOA touches it. The vault cannot move these funds autonomously — only `release()` (relayer) or `adminWithdraw()` (owner, if callable) can move them.

**Custody risk:** See FLAG above re: adminWithdraw. The deployer/owner `0xE2a4` has not demonstrably renounced withdrawal rights on this vault version.

---

### Step 2 — Relayer: watch Base, mint on Robinhood

**Who acts:** automated relayer bot, pm2 process name `mft-robinhood-relayer`, running on VPS `147.93.58.149` at `/root/mft-robinhood-bridge/`.

Source: `C:\Users\bigji\Documents\mftusd-build\rh-relayer.cjs`

**Keys used:** `BRIDGE_RELAYER_KEY` sourced from `/root/tasern-bridge/.env` on the VPS. The relayer wallet is `0x849639...` (separate from the owner/deployer 0xE2a4 — key segregation is intentional).

**Automation:** The relayer runs a 30-second polling loop (`LOOP_MS = 30_000`). On each tick:
1. Queries `getLogs` on MRB-BASE for `Locked` events, in 2000-block chunks, from a stored cursor.
2. Waits 20 Base confirmations (~40 seconds) before acting — avoids reorg risk.
3. For each unprocessed `Locked` event, calls `mintFromPolygon(nonce, MFT_BASE, rhRecipient, amount)` on MRB-RH.
4. Advances the local cursor (`rh-relayer-state.json`) only after delivery.

**VPS pm2 status:** NOT verified in this session (SSH access blocked). The name from source code is `mft-robinhood-relayer`. The relayer was deployed 2026-07-12 per the bridge UI comment. Relayer gas balances as of this session's on-chain read: **Base ETH: 0.0, RH ETH: 0.0** (relayer wallet holds no gas on either chain at time of query). This is a live operational risk — if the relayer wallet is unfunded, deliveries will fail.

**What happens on-chain (RH side):**
- `mintFromPolygon(nonce, 0x8FB8..., rhRecipient, amount)` called by relayer on MRB-RH.
- MRB-RH looks up `twinOf[0x8FB8...]` → returns `0x6ae5...` (MfT twin, verified on-chain).
- `BridgedToken(0x6ae5...).mint(rhRecipient, amount)` — twin tokens created from nothing and sent directly to `rhRecipient`. No intermediate wallet holds them.
- Nonce marked `processedInbound[nonce] = true`.

**Black box period:** Between the `Locked` event on Base and the `mintFromPolygon` tx on RH, the value is physically in the MRB-BASE vault. The relayer bot is the gating factor — if it is down, the MfT is locked in the vault with no automatic release path. The relayer must be up and funded on both chains for normal operation.

**Typical latency:** ~20 Base confirmations + one 30s polling interval = roughly 1–3 minutes total.

---

## Hop 2: Robinhood → Base (twin burn → MfT release)

### Step 1 — User: burn twin on Robinhood

**Contract called:** MRB-RH `0xa819...` on Robinhood Chain

**Function:** `bridgeToPolygon(0x6ae5..., amount, baseRecipient)`

**What happens:** `BridgedToken.burn(msg.sender, amount)` — twin tokens destroyed from user's wallet. `outboundNonce++` (current RH outboundNonce = 1). Emits `Burned(nonce, 0x6ae5..., from, baseRecipient, amount)`.

**Value custody during transit:** The twin is destroyed immediately. No contract or wallet holds any value mid-transit on this hop. The corresponding MfT remains locked in MRB-BASE until the relayer acts.

---

### Step 2 — Relayer: watch RH, release on Base

Same relayer bot, same polling loop. On the RH→Base leg:
1. Queries `getLogs` on MRB-RH for `Burned` events, 10 RH confirmations required.
2. Calls `release(nonce, 0x8FB8..., baseRecipient, amount)` on MRB-BASE.
3. MRB-BASE transfers MfT from vault to `baseRecipient`.

---

## Invariant Check (on-chain, 2026-07-16)

| Metric | Value |
|--------|-------|
| MfT locked in MRB-BASE | 4,000,000 MfT |
| MfT twin totalSupply on RH | 4,000,000 MfT |
| **Invariant holds** | **YES** — locked = minted, no excess twins |
| MRB-BASE outboundNonce | 2 (two Base→RH transfers initiated) |
| MRB-RH outboundNonce | 1 (one RH→Base transfer initiated) |
| MfT twin: twinOf(MFT_BASE) on RH vault | 0x6ae576... (correct) |
| MfT twin: originalOf(MFT_TWIN) on RH vault | 0x8FB87d... (correct) |
| Both vaults: paused | false |
| Both vaults: relayer | 0x849639... (same wallet, same key) |
| Both vaults: owner | 0xE2a4... (agent/coordinator wallet) |
| MfT total supply on Base | 100,000,000,000 MfT (canonical, unchanged) |

---

## Full Hop Summary

```
BASE                                  RELAYER BOT                  ROBINHOOD
                                   (VPS pm2, 30s loop)
                                   key: BRIDGE_RELAYER_KEY
                                   wallet: 0x849639...

User wallet
  │
  ├─ approve(MRB-BASE, amount)
  │
  └─ bridgeToBase(MFT, amount, rhRecipient)
       │
       ├─ transferFrom(user → MRB-BASE vault)    ← MfT held HERE
       └─ emit Locked(nonce, ...)
                                    │
                            watches Locked events
                            waits 20 Base confs
                            calls mintFromPolygon()
                                    │
                                                    MRB-RH vault
                                                      └─ BridgedToken.mint(rhRecipient, amount)
                                                           └─ MfT twin arrives in user wallet

RETURN DIRECTION:

User wallet (RH)
  └─ bridgeToPolygon(MFT_TWIN, amount, baseRecipient)
       ├─ BridgedToken.burn(user, amount)         ← twin destroyed
       └─ emit Burned(nonce, ...)
                                    │
                            watches Burned events
                            waits 10 RH confs
                            calls release()
                                    │
       MRB-BASE vault
         └─ transfer(baseRecipient, amount)
              └─ MfT returned to user on Base
```

---

## Open Flags for BNKR

1. **Relayer gas is zero on both chains** (on-chain confirmed, 2026-07-16). If the relayer wallet `0x849639...` has no ETH, all pending and future bridge transfers will stall with MfT locked in MRB-BASE. Fund before any bridge operations.

2. **Escape hatch status unconfirmed.** The `escapeHatchRenounced()` selector is not present on MRB-BASE. The contract may be an earlier version of TasernBridgePolygon without renounce support, meaning `adminWithdraw` (owner pulls locked tokens) may be live. Owner is `0xE2a4` (coordinator/agent wallet). This is a trust assumption, not a code guarantee.

3. **VPS pm2 relayer live status unverified** in this session. Expected pm2 name: `mft-robinhood-relayer`, path: `/root/mft-robinhood-bridge/rh-relayer.cjs`. Confirm with `pm2 status mft-robinhood-relayer` and `pm2 logs mft-robinhood-relayer --lines 20` on the VPS before any bridge transfer.

4. **No black box in the token path itself.** MfT goes: user wallet → MRB-BASE vault → (relayer mints twin) → user wallet on RH. No EOA or intermediary wallet holds MfT at any point. The vault is the only custodian.

5. **Owner key (`0xE2a4`) controls both vaults.** Can `setRelayer`, `setPaused`, `setOwner`, and potentially `adminWithdraw`. This is the standard trust model for a MfT-operated bridge — no multisig or timelock on these vaults.

---

## Source Files Referenced

- Contract logic: `C:\Users\bigji\Documents\mftusd-build\contracts\TasernBridge.sol`
- Relayer bot: `C:\Users\bigji\Documents\mftusd-build\rh-relayer.cjs` (VPS copy at `/root/mft-robinhood-bridge/rh-relayer.cjs`)
- Deploy script: `C:\Users\bigji\Documents\mftusd-build\rh-deploy.cjs`
- Manual bridge script: `C:\Users\bigji\Documents\mftusd-build\bridge-mft-to-rh.cjs`
- Bridge UI: `C:\Users\bigji\Documents\mftusd-build\mft-robinhood-bridge.html`
- Network CSV (address registry): `C:\Users\bigji\Documents\mftusd-build\bankr-impact-network.csv` lines 194–201
- Deploy state (VPS only): `/root/mft-robinhood-bridge/robinhood-bridge-deployed.json` (not present locally)
- Relayer cursor (VPS only): `/root/mft-robinhood-bridge/rh-relayer-state.json`
