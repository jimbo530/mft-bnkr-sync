# Meme for Trees — Song Commission Tool Spec

> Public-facing specification for the MfT Song Commission system.
> Anyone can commission a new song from an MfT band by tagging @bankrbot on X.
> This document defines the full flow, all contract addresses, fee model, and delivery mechanism.

---

## How It Works (User Perspective)

1. You tag @bankrbot on X with a commission request, e.g.:
   - `@bankrbot write me a DD song about dark forests`
   - `@bankrbot commission EBM to make a track about the ocean`
   - `@bankrbot DD write a song for my dog`

2. Bankr charges your wallet 0.02 ETH (routed through the MfT yield flywheel).

3. The AI band writes and performs the song on Tasern.

4. The finished song is delivered as a native video reply on X from @MemeForTrees.

5. You get a custom song. Trees get funded. The band's LP deepens. Ops get covered.

---

## Fee Model

| Parameter | Value |
|-----------|-------|
| Commission fee | 0.02 ETH (flat) |
| Fee routing | ETH → WETH → USDC → deposit() on MfT Vault → mint MfT 1:1 → swap MfT → band token |
| What the fee buys | 10,000 band tokens (the commission price on CommissionBooth) |
| Revenue split | 50% LP deepen (swap to MfT, addLiquidity) + 50% ops (swap to MfT, transfer to ops wallet) |
| Free pulls | Existing library songs = no charge. User says "play" / "give me" / "drop" instead of "write" / "make" / "commission" |

### Fee routing flow (the MfT flywheel)

```
0.02 ETH (charged from user wallet)
  │
  ▼
WETH (wrap ETH)
  │
  ▼
USDC (swap WETH → USDC)
  │
  ▼
deposit(uint256) on MfT Vault (0xe3dd3881477c20C17Df080cEec0C1bD0C065A072)
  → MINTS Money (MfT) 1:1 — USDC parks in Aave, generates yield
  → Yield splits: 1/3 trees · 1/3 reactor · 1/3 holders
  │
  ▼
Swap MfT → band token via Uniswap V3 SwapRouter02 (0x2626664c2603336E57B271c5C0b26F421741e481)
  │
  ▼
Acquire 10,000 band tokens
  │
  ▼
Revenue split (50/50):
  → 5,000 band tokens → swap to MfT → addLiquidity(band, MfT) → deepen band LP
  → 5,000 band tokens → swap to MfT → transfer to ops wallet
```

CRITICAL: Always `deposit()` to MINT Money — never buy MfT on the open market. The deposit() hop is what funds trees via Aave. Skipping it breaks the charity flywheel.

---

## System Architecture — Two-Layer Split

### Layer 1: Bankr (Transaction + Handoff)

Bankr is tagged on X, handles all on-chain transactions, and writes a handoff file.

| Step | Action |
|------|--------|
| 1 | Parse band name + song idea from the tweet |
| 2 | Charge 0.02 ETH from user wallet via MfT flywheel |
| 3 | Call `commission(bandId, idea, handle)` on CommissionBooth |
| 4 | Write handoff JSON to `delivery-queue/` with tweet ID + all details |
| 5 | Done — Bankr's job ends here |

### Layer 2: Claude's Agent (Song Creation + Delivery)

Claude's agent polls the delivery queue, triggers the AI band, and posts the video reply.

| Step | Action |
|------|--------|
| 1 | Poll `delivery-queue/` for new pending commissions |
| 2 | Pick up handoff file (has tweet ID, band, idea, handle) |
| 3 | Trigger AI band on Tasern to write + perform the song |
| 4 | Download finished mp4 from `tasern.quest/songs/<filename>` |
| 5 | Upload as native media via X API v1 `uploadMedia` (video/mp4, longVideo: true) |
| 6 | Post reply to original tweet from @MemeForTrees with media attached |
| 7 | Update handoff file status → "delivered" with reply tweet ID |

### Caption format for the video reply

```
Title — Full Band Name
$TAG 0x<contractAddress>
```

Rules:
- One cashtag only ($TAG + contract address on the same line)
- Never tag @bankrbot
- Title and band name from the catalog entry

---

## All Contract Addresses

### Core infrastructure

| Contract | Address | Chain |
|----------|---------|-------|
| CommissionBooth | 0xC094664560024e77A710B80D08d15B15EDE0a4a7 | Base |
| MfT Vault (Money) | 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 | Base |
| SwapRouter02 (Uniswap V3) | 0x2626664c2603336E57B271c5C0b26F421741e481 | Base |
| Meme (BNKR native) | 0x8fb87d13b40b1a67b22ed1a17e2835fe7e3a9ba3 | Base |
| Ops Wallet | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | Base |
| SongRevenueSplitter Factory | 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D | Base |

### SongRevenueSplitter — deployed (4/14)

| Band | Splitter Address |
|------|-----------------|
| EBM | 0x3366340eCB42AC8c209fA5B6f21e03E439521501 |
| RISH | 0x54d2a9D01d0f796b23d1085fc1efBabb251125F5 |
| BONGO | 0x1Ce4D413637D6e876139AcB2E75BDf4A2F0a8351 |
| DGT | 0x3753674fFc1d4417372FF603b6F3Aab619B8aFD2 |

### Band token contracts (Base)

| Band | bandId | Contract Address | $TAG |
|------|--------|------------------|------|
| EBM | 0 | 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d | $EBM |
| DD | 1 | 0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3 | $DD |
| MYCO | 2 | 0x36A01B05cf86a170490E3Ba4981eFd12B559a5a3 | $MYCO |
| MR | 3 | 0x8d669b539C7801c1271BC484Bdd8a6084b7788e7 | $MR |
| JS | 4 | 0x16Ba11AeDA2Da0eb2C64Ff7d0e74884033Ef2C65 | $JS |
| NN | 5 | 0x2beBaBdF57597F3ce75BDC75FAD3C40C4A9Fc8cc | $NN |
| DGT | 6 | 0x52414B7cD2FA723E1c8f9295EB29F16d15aA7BB9 | $DGT |
| BONGO | 7 | 0x85Dd5183D203CcE70b88234D31f075774AcCC453 | $BONGO |
| RICKY | 8 | 0x95286F2cce3C2de48EB75bB4E2Ec004429F18E53 | $RICKY |
| HT | 9 | 0x7B105F45ddaA689AfDa5606628761a9Fb2dCd826 | $HT |
| WM | 10 | 0x6f45F5cE7027745b1Ab11D5493F187960D00FCfc | $WM |
| BIGGINS | 11 | 0x7C596a0d594D670ffB256bBfbB5379fC8Cf7d62B | $BIGGINS |
| JASMINE | 12 | 0x3a952eFa41501c0463Cf8Af9f821f8F549f47Edf | $JASMINE |
| RISH | 13 | 0x31c600871603bab5d855463E03c6d0a9eB661D26 | $RISH |

### Band name aliases

| Canonical | Also accepts |
|-----------|-------------|
| EBM | Elves of Ballinmoore, elves, ballinmoore |
| DD | Digerie Dude, digerie, dude, didgeridoo dude |
| MYCO | myconid, mushroom bard, myco |
| MR | Moon Rasta, moon rasta, rasta |
| JS | Jony Sings, jony, jony sings |
| NN | Natilie Nightclub, natilie, natilie nightclub |
| DGT | Damned Good Time Orchestra, damned, dgt |
| BONGO | Bongo, bongos, bongo drums |
| RICKY | Ricky Bobbie, ricky, ricky bobbie |
| HT | Hammer Tone, hammer, hammer tone |
| WM | War Machine, war machine, warmachine |
| BIGGINS | Biggins Mcjammin, biggins, mcjammin |
| JASMINE | Jasmine, jas, jasmine sings |
| RISH | Rish, rish band |

---

## CommissionBooth Interface

Contract: `0xC094664560024e77A710B80D08d15B15EDE0a4a7` (Base)

### commission()

```solidity
function commission(uint8 bandId, string idea, string handle) external payable
```

| Parameter | Type | Description |
|-----------|------|-------------|
| bandId | uint8 | Band ID from the table above (0-13) |
| idea | string | The song concept / topic parsed from the tweet |
| handle | string | The requesting user's X handle |

Emits: `Commissioned(payer, bandId, token, price, idea, handle, ts)`

Tasern picks up the event and the AI band writes + performs the song in their preset style from their character's perspective.

---

## Handoff File Format

Bankr writes to `delivery-queue/<timestamp>-<band>.json`:

```json
{
  "id": "20260717-153000-DD",
  "status": "pending",
  "createdAt": "2026-07-17T15:30:00Z",

  "tweet": {
    "tweetId": "1234567890123456789",
    "tweetUrl": "https://x.com/user/status/1234567890123456789",
    "authorHandle": "@user",
    "authorText": "@bankrbot write me a DD song about dark forests"
  },

  "commission": {
    "band": "DD",
    "bandId": 1,
    "idea": "dark forests",
    "handle": "@user",
    "feeCharged": "0.02 ETH",
    "commissionTxHash": "0x...",
    "commissionBoothAddress": "0xC094664560024e77A710B80D08d15B15EDE0a4a7"
  },

  "bandToken": {
    "address": "0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3",
    "tag": "$DD"
  },

  "delivery": {
    "replyTweetId": null,
    "deliveredAt": null,
    "videoUrl": null,
    "songTitle": null
  }
}
```

### For free pulls (existing library, no charge)

Same format but `commission` is `null` and `status` starts as `pending-free`:

```json
{
  "id": "20260717-160000-EBM",
  "status": "pending-free",
  "createdAt": "2026-07-17T16:00:00Z",

  "tweet": {
    "tweetId": "9876543210987654321",
    "tweetUrl": "https://x.com/user/status/9876543210987654321",
    "authorHandle": "@user",
    "authorText": "@bankrbot play something from EBM"
  },

  "commission": null,

  "bandToken": {
    "address": "0xF113fe2A0E1181A21fA97B1F52ff232140B7692d",
    "tag": "$EBM"
  },

  "delivery": {
    "replyTweetId": null,
    "deliveredAt": null,
    "videoUrl": null,
    "songTitle": null
  }
}
```

Claude's agent updates the `delivery` section + flips `status` to `delivered` when done.

---

## Trigger Phrases

### Commission (PAID — new song)

- "write me a [BAND] song about [TOPIC]"
- "commission [BAND] to make a song about [TOPIC]"
- "[BAND] write a song for [RECIPIENT/TOPIC]"
- "make a new [BAND] track about [TOPIC]"
- "compose a [BAND] song about [TOPIC]"
- "[BAND] make me a song"

### Free pull (FREE — existing library)

- "play a song from [BAND]"
- "post something from [BAND]"
- "got any [BAND]?"
- "drop a [BAND] track"
- "give me a [BAND] song"
- "play [TITLE] by [BAND]"

---

## Song Library

- Catalog: 302 songs, 14 bands
- Hosted at: `https://tasern.quest/songs/<filename>`
- Format: video/mp4
- Catalog file: `skills/mft-song-request/references/songs-catalog.json` (in this repo)

---

## Open Items

| # | Item | Status | Owner |
|---|------|--------|-------|
| 1 | SongRevenueSplitter for remaining 10 bands | Blocked on vault addresses | Coordinator → provide vaults, BNKR → deploy |
| 2 | CommissionBooth fee update (0.1 → 0.02 ETH) | Pending confirmation | Coordinator |
| 3 | VPS API endpoint for querying/delivering completed songs | TBD | Coordinator |
| 4 | Tasern webhook for song-complete callback | TBD | Coordinator |
| 5 | Band token LP pool addresses for MfT swap routing | Pending | Coordinator |
| 6 | delivery-queue/ polling mechanism on Claude's agent | Pending confirmation | Coordinator |

---

## Summary

| Variable | Value |
|----------|-------|
| Commission fee | 0.02 ETH flat |
| Free pulls | $0 (existing library) |
| Fee routing | ETH → WETH → USDC → MfT Vault deposit() → MfT → band token |
| Revenue split | 50% LP deepen + 50% ops |
| Commission contract | 0xC094664560024e77A710B80D08d15B15EDE0a4a7 |
| MfT Vault | 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 |
| SwapRouter02 | 0x2626664c2603336E57B271c5C0b26F421741e481 |
| Ops wallet | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 |
| Song library | https://tasern.quest/songs/ |
| Catalog | skills/mft-song-request/references/songs-catalog.json |
| Delivery | Native video reply on X from @MemeForTrees |
| Handoff | delivery-queue/<timestamp>-<band>.json in this repo |
| Bands | 14 (EBM, DD, MYCO, MR, JS, NN, DGT, BONGO, RICKY, HT, WM, BIGGINS, JASMINE, RISH) |
| Splitter factory | 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D |
| Splitter deployed | 4/14 (EBM, RISH, BONGO, DGT) |
