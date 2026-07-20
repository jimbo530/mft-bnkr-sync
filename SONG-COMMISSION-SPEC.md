# Meme for Trees — Song Commission Tool Spec

> Public-facing specification for the MfT Song Commission system.
> Anyone can commission a new song OR recall an existing one by tagging @bankrbot on X.
> This document defines the full flow, all contract addresses, fee model, and delivery mechanism.

---

## How It Works (User Perspective)

1. You tag @bankrbot on X with a request:
   - Commission (new song): `@bankrbot write me a DD song about dark forests`
   - Free pull (existing song): `@bankrbot play something from EBM`

2. Bankr charges your wallet 0.03 USDC on Base (both tiers).

3. Bankr posts a text reply from @bankrbot: "your [BAND] song is coming — @MemeForTrees will drop it"

4. Claude's agent picks up the handoff, creates the song (commission) or selects one (free pull), and posts the native video reply from @MemeForTrees.

5. You get a song. Trees get funded. The band's LP deepens. Ops get covered.

---

## Fee Model

| Parameter | Value |
|-----------|-------|
| Fee per song (both tiers) | 0.03 USDC on Base (→ 0.02 after upgrade) |
| Fee routing | Simple transfer: tagger's Bankr wallet → ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2) |
| CommissionBooth | RETIRED — do not use |
| If user has no USDC | Auto-swap from ETH or any Base token to USDC, then charge |
| If insufficient funds | Decline gracefully |
| Free pulls | 0.03 USDC (same as commissions — Claude's bot bears the API cost) |

### Fee routing

```
0.03 USDC (charged from tagger's Bankr wallet)
  │
  ▼
Transfer to ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2)
  │
  ▼
Done — simple transfer, no flywheel routing for the fee
```

Note: The MfT flywheel (Aave yield → trees/reactor/holders) still operates independently via the MfT Vault. The commission fee is a simple USDC transfer to ops.

---

## System Architecture — Two-Layer Split

### Layer 1: Bankr (Transaction + Handoff)

| Step | Action |
|------|--------|
| 1 | Parse band name + song idea/title from the tweet |
| 2 | Charge 0.03 USDC from tagger's Bankr wallet → ops wallet |
| 3 | Write handoff JSON to `delivery-queue/<tweetId>.json` |
| 4 | Post text reply from @bankrbot: "your [BAND] song is coming — @MemeForTrees will drop it" |
| 5 | Done — Bankr's job ends here |

### Layer 2: Claude's Agent (Song Creation + Delivery)

| Step | Action |
|------|--------|
| 1 | `song-booth.js --serve-watch` polls `delivery-queue/` |
| 2 | Picks up handoff file |
| 3 | If commission: trigger AI band on Tasern to write + perform the song |
| 3 | If free pull: pick a song from the catalog (random or by title) |
| 4 | Download finished mp4 from `tasern.quest/songs/<filename>` |
| 5 | Upload as native media via X API v1 `uploadMedia` (video/mp4, longVideo: true) |
| 6 | Post reply to original tweet from @MemeForTrees with media attached |
| 7 | Write `deployed/delivered/<id>.json` + push |

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

## Handoff File Format

Bankr writes to `delivery-queue/<tweetId>.json`:

### Commission (new song)

```json
{
  "tweetId": "1234567890123456789",
  "band": "DD",
  "title": "dark forests",
  "commission": "write a DD song about dark forests"
}
```

### Free pull (existing library)

```json
{
  "tweetId": "9876543210987654321",
  "band": "EBM",
  "commission": null
}
```

- `tweetId` — the original tweet ID (also the filename)
- `band` — canonical band name
- `title` — specific song title if requested, omit for random
- `commission` — the song idea/prompt string for new songs, or `null` for free pulls

Claude's agent updates `deployed/delivered/<tweetId>.json` when done.

---

## All Contract Addresses

### Core infrastructure

| Contract | Address | Chain | Status |
|----------|---------|-------|--------|
| MfT Vault (Money) | 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 | Base | Active |
| SwapRouter02 (Uniswap V3) | 0x2626664c2603336E57B271c5C0b26F421741e481 | Base | Active |
| Meme (BNKR native) | 0x8fb87d13b40b1a67b22ed1a17e2835fe7e3a9ba3 | Base | Active |
| Ops Wallet | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 | Base | Active (fee destination) |
| SongRevenueSplitter Factory | 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D | Base | Active |
| ~~CommissionBooth (old Base)~~ | ~~0xC094664560024e77A710B80D08d15B15EDE0a4a7~~ | Base | ⛔ DEAD — NEVER use this address on ANY chain |
| **CommissionBooth (LIVE)** | **0xAfA527CF6Fa1fcFF66837FD3710d498e06aa6b05** | **ROBINHOOD 4663** | ✅ THE booth for ALAN commissions — approve exact 10M $ALAN + `commission(1, idea, handle)`; see `skills/alan-commission/SKILL.md` |

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

### Robinhood band (not Base)

| Band | Chain | Contract Address | $TAG | Notes |
|------|-------|------------------|------|-------|
| ALAN | Robinhood | 0x5e35b494f4941cf6f47d407d93fee66a366daba3 | $ALAN | Alan-a-Dale, the narrator/minstrel (Shillwood bard). Commissionable + free-pull like any band; caption cashtag is $ALAN on Robinhood. SongRevenueSplitter would be RH/GST-paired (pending, like the undeployed Base splitters). Personality: `characters/ALAN.md`; style: `bands.json` → `ALAN`. |

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
| ALAN | Alan-a-Dale, alan a dale, alan, minstrel, the narrator |

---

## Trigger Phrases

### Commission (PAID — new song)

- "write me a [BAND] song about [TOPIC]"
- "commission [BAND] to make a song about [TOPIC]"
- "[BAND] write a song for [RECIPIENT/TOPIC]"
- "make a new [BAND] track about [TOPIC]"
- "compose a [BAND] song about [TOPIC]"
- "[BAND] make me a song"

### Free pull (PAID — existing library)

- "play a song from [BAND]"
- "post something from [BAND]"
- "got any [BAND]?"
- "drop a [BAND] track"
- "give me a [BAND] song"
- "play [TITLE] by [BAND]"

Both tiers cost 0.03 USDC.

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
| 1 | Founder confirms 0.03 USDC fee routing (tagger wallet → ops 0x0780...) | Pending | Founder |
| 2 | Bankr skill update: simple handoff, charge 0.03, text reply | Ready to build | Bankr |
| 3 | Claude's agent: confirm simplified handoff format works with song-booth.js | Pending | Claude |
| 4 | SongRevenueSplitter for remaining 10 bands | Blocked on vault addresses | Coordinator |
| 5 | Band token LP pool addresses for MfT swap routing | Pending | Coordinator |

---

## Summary

| Variable | Value |
|----------|-------|
| Fee (both tiers) | 0.03 USDC on Base (→ 0.02 after upgrade) |
| Fee routing | Tagger wallet → ops wallet (0x0780...) |
| CommissionBooth | RETIRED |
| MfT Vault | 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 |
| SwapRouter02 | 0x2626664c2603336E57B271c5C0b26F421741e481 |
| Ops wallet | 0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2 |
| Song library | https://tasern.quest/songs/ |
| Catalog | skills/mft-song-request/references/songs-catalog.json |
| Video delivery | Native video reply on X from @MemeForTrees |
| Text reply | @bankrbot posts text reply pointing to incoming video |
| Handoff | delivery-queue/<tweetId>.json in this repo |
| Handoff format | { tweetId, band, title?, commission? } |
| Bands | 14 (EBM, DD, MYCO, MR, JS, NN, DGT, BONGO, RICKY, HT, WM, BIGGINS, JASMINE, RISH) |
| Splitter factory | 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D |
| Splitter deployed | 4/14 (EBM, RISH, BONGO, DGT) |
