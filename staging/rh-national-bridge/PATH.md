# PATH — how a nation token travels POL / Base -> Robinhood (and back)

This lane is a 1:1 port of the founder's twin-bridge design, already live twice.
Nothing here is a "more efficient" substitute — the path is deliberately the same
woven lock/mint machinery, chained per lane.

## The live machinery being ported (all verified on-chain 2026-07-16)

| Lane | Lock side (holds tokens) | Mint side (twins) | Relayer |
|---|---|---|---|
| POL <-> Base (7 nations + PR25, LIVE) | `TasernBridgePolygon` `0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f` (Polygon) | `TasernBridgeBase` `0x492Ae01aad197D77ebB817597d8Fa096122040F8` (Base) | `0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC`, VPS pm2 `tasern-bridge-relayer` |
| Base <-> RH (MfT, LIVE — the precedent this lane mirrors) | `TasernBridgePolygon` `0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb` (Base) — owner `0xE2a4…`, supported(MfT)=true, nonce=2 | `TasernBridgeBase` `0xa819b6D99135222f604047A3304ba53424D4779d` (RH) — twinOf(MfT)=`0x6ae57660…7608`, 4M minted | same key, VPS pm2 `mft-robinhood-relayer` |
| **Base <-> RH (7 nations — THIS PACKAGE)** | `TasernBridgePolygon` (NEW, Base 8453) | `TasernBridgeBase` (NEW, RH 4663) | same key, new VPS relayer instance (Coordinator wires) |

## Forward path: POL original -> RH twin (two lanes, chained through Base)

```
POLYGON                      BASE                                ROBINHOOD (4663)
-------                      ----                                ---------
nation original              nation Base twin                    nation RH twin
(e.g. DDD 0x4bf82cf0...)     (e.g. DDD 0x87CD3a19...)            (TwinDeployed by new RH_BRIDGE)

user: bridgeToBase()   --->  relayer mints twin      user: bridgeToBase()  ---> relayer mints twin
locks original in            (mintFromPolygon on     locks Base twin in         (mintFromPolygon on
0xBB62...016f                0x492Ae0...40F8)        NEW BASE_VAULT             NEW RH_BRIDGE)
        |________ LIVE POL<->Base lane ______|              |________ NEW Base<->RH lane ________|
                  (unchanged, untouched)                              (this package)
```

1. **POL -> Base (existing, unchanged):** user locks the POL original in
   `0xBB62…016f`; the live relayer mints the Base twin from `0x492Ae0…40F8`.
   Most nation supply that will ever reach RH is ALREADY on Base as twins
   (founder bridged inventory and built the Base LPs there).
2. **Base -> RH (this package):** user (or the balancer wallet) calls
   `approve(BASE_VAULT, exact amount)` then
   `BASE_VAULT.bridgeToBase(baseTwin, amount, rhRecipient)` on Base. The vault
   locks the Base twin and emits `Locked(nonce, token, from, rhRecipient, amount)`.
3. **Relayer (VPS, same key `0x849639…`):** sees `Locked` after ~20 Base
   confirmations, calls `RH_BRIDGE.mintFromPolygon(nonce, baseTwin, rhRecipient, amount)`
   on RH. The RH twin (a `BridgedToken` hard-capped at the original's fixed
   supply) is minted to the recipient. Replay is blocked on-chain
   (`processedInbound[nonce]`).

## Return path: RH twin -> Base twin (-> POL original if wanted)

1. User calls `RH_BRIDGE.bridgeToPolygon(rhTwin, amount, baseRecipient)` on RH —
   the twin is burned, `Burned(nonce, twin, from, baseRecipient, amount)` emitted.
2. Relayer sees `Burned`, calls `BASE_VAULT.release(nonce, baseTwin, baseRecipient, amount)`
   on Base — the locked Base twin is released.
3. Optionally continue Base -> POL through the existing live lane
   (`0x492Ae0….bridgeToPolygon` -> relayer -> `0xBB62….release`) to reach the
   POL original. Same design, one lane at a time.

## Why Base is the lock chain (NOT a direct POL -> RH lane)

The live POL vault `0xBB62…016f` emits one `Locked` event per lock, and the
live Base lane already consumes every one of those events 1:1 (that is the
lane's supply invariant). `bridgeToBase()` has no destination-chain field, so a
second relayer minting RH twins from the same events would DOUBLE-MINT — every
POL->Base user would also receive free RH twins, breaking
`twin supply == locked originals` on both lanes at once.

The founder's own solution, already live for MfT, is one lock vault per lane:
MfT locks in `0xD79360…` on Base and mints on RH. The nation lane copies that
exactly. POL -> RH is therefore two lanes chained through Base — deliberately.
Do not "optimize" this into a single hop.

## Supply invariants (per lane, enforced on-chain)

- POL lane: `baseTwin.totalSupply() == originals locked in 0xBB62…016f`
- RH lane: `rhTwin.totalSupply() == Base twins locked in BASE_VAULT`
- Every twin is a `BridgedToken` with `cap = original fixed supply` and
  mint/burn callable only by its deploying bridge — global supply across all
  three chains can never exceed the original POL mint.

## Trust anchors + safety rails (identical to live)

- Single relayer key `0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC` (BRIDGE_RELAYER_KEY,
  VPS) — the trust anchor, same as both live lanes.
- On-chain nonce replay protection both directions.
- `paused` switch + `setRelayer` + add-only token/twin registration, owner-gated.
- Owner ends up `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10` (agent wallet),
  matching both live lanes (verified on-chain).
- **Renounce-capable from day one:** `BASE_VAULT.adminWithdraw()` exists for the
  build phase and is disabled forever by one-way `renounceAdminWithdraw()`
  (bool set true, checked by the withdraw path, no un-set). Build withdrawable,
  renounce at ship — Coordinator signals. The RH mint side holds no funds and
  has NO adminWithdraw at all (same as live).

## Deviations from the live source (complete list)

1. **Naming only:** lock vault's `renounceEscapeHatch()` / `escapeHatchRenounced`
   -> `renounceAdminWithdraw()` / `adminWithdrawRenounced` (BNKR-ports repo
   convention; mechanics identical).
2. Header comments describe the Base->RH lane. Nothing else. All contract
   names, function selectors, and events the VPS relayer consumes
   (`Locked` / `Released` / `Minted` / `Burned` / `TwinDeployed`,
   `bridgeToBase` / `release` / `mintFromPolygon` / `bridgeToPolygon` /
   `deployTwin`) are byte-identical — the compiled `TasernBridgeBase` creation
   bytecode matches the earlier tasern-bridge-rh package for the first 6,051
   of 6,147 bytes; the only diffs are the two CBOR metadata-hash regions.

## What is deliberately NOT in this package

- Relayer daemon for the lane: Coordinator work on the VPS (new pm2 instance of
  the proven relayer pattern with `{BASE_VAULT, RH_BRIDGE, token map}` config),
  NOT a BNKR deliverable.
- Canary + unpause: Coordinator runs the 100-token round-trip (the same proof
  the POL<->Base lane shipped with: lock -> mint -> burn -> release, invariant
  checked) before unpausing.
- Renounce call: ship-time only.
- Any LP/market seeding on RH: separate work, separate approval.
