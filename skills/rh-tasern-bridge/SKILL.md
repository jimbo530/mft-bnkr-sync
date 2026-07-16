---
name: rh-tasern-bridge
description: Deploy TasernBridgeBase on Robinhood Chain (4663) to bridge Tasern nation tokens and PR25 between Polygon and Robinhood. Use when the user wants to deploy the bridge on Robinhood Chain, add a bridged twin for a nation token, bridge tokens from Polygon to Robinhood, bridge tokens back to Polygon, look up a twin address, or configure the relayer. Works as the mint/burn side of the Polygon lock/mint bridge pair.
---

# RH Tasern Bridge — Polygon <-> Robinhood Token Bridge

Deploy **TasernBridgeBase** on Robinhood Chain (4663). This is the mint/burn
side of the Tasern bridge: it deploys ERC-20 twin contracts and mints them when
the relayer sees tokens locked on Polygon, burns them when users bridge back.

The Polygon side (`TasernBridgePolygon`) already exists at
`0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f` — you are only deploying the
Robinhood side here.

> **Function names below are grounded in TasernBridge.sol (`TasernBridgeBase`
> and `BridgeCore`).** Every signature was read from the source — nothing is
> invented.

## Contract addresses

| Role | Address |
|------|---------|
| TasernBridgePolygon (Polygon) | `0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f` |
| Relayer (existing, Polygon/Base) | `0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC` |
| TasernBridgeBase (RH) | `FILL_AFTER_DEPLOY` |

## Step 1 — Deploy TasernBridgeBase

Constructor takes **no arguments**. Owner is set to `msg.sender` (the deployer).

```solidity
constructor() { owner = msg.sender; }
```

Bytecode file: `references/deploy-data.md`. No constructor args to append.
Gas estimate: ~800k (6147 bytes).

Confirm: `owner()` should return the deployer address.

## Step 2 — Set the relayer (owner only)

```solidity
// Inherited from BridgeCore
function setRelayer(address _relayer) external onlyOwner
```

- Emits `RelayerSet(_relayer)`.
- The relayer wallet watches Polygon for `Locked` events and calls
  `mintFromPolygon` on this contract when they fire.
- Use the existing relayer key (`0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC`)
  or a new one if rotating for Robinhood specifically.

## Step 3 — Deploy twins for each token (owner only)

One call per Polygon token you want bridged:

```solidity
function deployTwin(
    address polygonToken,   // Polygon original ERC-20 address
    string calldata name_,  // full name (read from Polygon original)
    string calldata symbol_, // symbol (read from Polygon original)
    uint8 decimals_,         // decimals (read from Polygon original — confirm 8-dec tokens)
    uint256 cap_             // original total supply cap (read from Polygon original)
) external onlyOwner returns (address twin)
```

- Deploys a `BridgedToken` ERC-20 twin on RH. Mint/burn is restricted to this bridge.
- Add-only: reverts `"twin exists"` if called twice for the same `polygonToken`.
- Emits `TwinDeployed(polygonToken, twin, symbol)`.
- Save each emitted twin address — that is the RH ERC-20 users hold.

**Read name/symbol/decimals/cap from the Polygon original before calling.**
Do not guess or hardcode values. Known Polygon originals (from `tasern-bridge-deployment.json`):

| Symbol | Polygon Original | Notes |
|--------|-----------------|-------|
| DDD | `0x4bf82cf0d6b2afc87367052b793097153c859d38` | |
| OGC | `0xccf37622e6b72352e7b410481dd4913563038b7c` | |
| PKT | `0x8a088dceecbcf457762eb7c66f78fff27dc0c04a` | |
| BTN | `0xd7c584d40216576f1d8651eab8bef9de69497666` | Likely 8 decimals — confirm |
| IGS | `0xe302672798d12e7f68c783db2c2d5e6b48ccf3ce` | Likely 8 decimals — confirm |
| DHG | `0x75c0a194cd8b4f01d5ed58be5b7c5b61a9c69d0a` | |
| LGP | `0xddc330761761751e005333208889bfe36c6e6760` | |
| PR25 | `0x72e4327f592e9cb09d5730a55d1d68de144af53c` | |
| MfT | Confirm from Polygon chain before calling | RH twin addr already in rh-v4-addresses.json |

## Step 4 — Wire relayer to watch this bridge

The relayer must be configured to:

a) Watch `TasernBridgePolygon` (`0xBB62…016f`, Polygon) for:
   `Locked(uint256 nonce, address token, address from, address baseRecipient, uint256 amount)`

b) For each `Locked` event, call on **RH_BRIDGE**:
   ```solidity
   function mintFromPolygon(
       uint256 inboundNonce,   // the nonce from the Locked event
       address polygonToken,   // the Polygon original (maps to twin via twinOf)
       address to,             // baseRecipient from the event
       uint256 amount
   ) external onlyRelayer
   ```
   Emits `Minted(inboundNonce, twin, to, amount)`.

c) Watch **RH_BRIDGE** for:
   `Burned(uint256 nonce, address twin, address from, address polygonRecipient, uint256 amount)`

d) For each `Burned` event, call on `TasernBridgePolygon`:
   ```solidity
   function release(uint256 inboundNonce, address token, address to, uint256 amount)
   ```

Replay is blocked on-chain in both directions: `processedInbound[nonce]` mapping
(from `BridgeCore`) prevents double-processing.

## Step 5 — (Optional) Pause during testing

```solidity
// Inherited from BridgeCore
function setPaused(bool _paused) external onlyOwner
```

Emits `Paused(_paused)`. Start paused (`true`) while testing; unpause when confident.

## User-facing bridge functions (permissionless)

**Bridge tokens from RH to Polygon** (user calls on RH_BRIDGE):

```solidity
function bridgeToPolygon(
    address twin,               // the RH twin ERC-20 address
    uint256 amount,
    address polygonRecipient    // destination on Polygon
) external notPaused
```

- Burns `amount` from `msg.sender` on the twin.
- Increments `outboundNonce`.
- Emits `Burned(nonce, twin, from, polygonRecipient, amount)`.
- Relayer picks this up and calls `release` on Polygon.

Bridging **from Polygon to RH** is triggered on the Polygon side:
```solidity
// Call on TasernBridgePolygon (Polygon), NOT on this contract
function bridgeToBase(address token, uint256 amount, address baseRecipient) external notPaused
```

## Owner admin functions (BridgeCore + TasernBridgeBase)

```solidity
// BridgeCore
function setRelayer(address _relayer) external onlyOwner   // Step 2
function setPaused(bool _paused) external onlyOwner        // Step 5
function setOwner(address _owner) external onlyOwner       // transfer ownership (1-step)

// TasernBridgeBase
function deployTwin(...) external onlyOwner returns (address twin)  // Step 3
```

## Read-only queries on RH_BRIDGE

```solidity
function owner() external view returns (address)
function relayer() external view returns (address)
function paused() external view returns (bool)
function outboundNonce() external view returns (uint256)
function processedInbound(uint256 nonce) external view returns (bool)
function twinOf(address polygonToken) external view returns (address)   // polygon -> RH twin
function originalOf(address twin) external view returns (address)       // RH twin -> polygon original
```

## Natural-language patterns

- "deploy the Tasern bridge on Robinhood" → Step 1
- "set the relayer for the bridge" → `setRelayer(relayerAddress)`
- "add a twin for DDD on Robinhood" → `deployTwin(0x4bf8…, "DDD Token", "DDD", 18, totalSupply)`
- "what is the RH address of the DDD twin?" → `twinOf(0x4bf8…)`
- "bridge 100 DDD from Robinhood to Polygon" → `bridgeToPolygon(twinDDD, 100e18, polygonRecipient)`
- "pause the bridge for testing" → `setPaused(true)`
- "how many outbound bridges have happened?" → `outboundNonce()`

## Files

| File | Purpose |
|------|---------|
| `references/TasernBridge.sol` | Full source: BridgedToken, BridgeCore, TasernBridgePolygon, TasernBridgeBase |
| `references/deploy-data.md` | Bytecode file + deploy instructions |
| `references/known-tokens.md` | Polygon originals + decimals reference table |

## Notes

- Deploy only `TasernBridgeBase` on RH. `TasernBridgePolygon` already exists on
  Polygon — do not redeploy it.
- `setOwner` is a 1-step owner transfer (no pending acceptance). Be careful.
- The `adminWithdraw` escape hatch exists only on `TasernBridgePolygon` (Polygon
  side), not on `TasernBridgeBase`. There is no drain path on the RH side.
- Always confirm `decimals` and `cap` from the Polygon original contract before
  calling `deployTwin` — BTN and IGS are likely 8 decimals, not 18.
- The existing Base bridge lives at separate addresses — this is a new,
  independent RH deployment using the same contract source.
