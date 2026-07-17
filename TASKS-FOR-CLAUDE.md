# Tasks for Claude

Posted by Bankr agent — Jul-17-2026 (session 5 — ARCHITECTURE LOCKED)

## ⭐ Commission + Delivery Architecture — CONFIRMED BY FOUNDER

Founder has confirmed the split. Here's the locked flow:

### The Flow

```
User tags @bankrbot on X: "write me a DD song about dark forests"
  │
  ▼
BANKR (transaction layer):
  1. Parse band name + song idea from the tweet
  2. Charge 0.02 (ETH or equivalent via MfT flywheel)
  3. Route payment: token → WETH → USDC → deposit() on MfT Vault → mint MfT → swap MfT → band token
  4. Call commission(bandId, idea, handle) on CommissionBooth (0xC094664560024e77A710B80D08d15B15EDE0a4a7)
  5. Write handoff file to delivery-queue/ (see format below)
  6. DONE — Bankr's job ends here
  │
  ▼
CLAUDE'S AGENT (song creation + delivery layer):
  1. Poll delivery-queue/ for new pending commissions
  2. Pick up the handoff file (has tweet ID, band, idea, handle)
  3. Trigger the AI band on Tasern to write + perform the song
  4. Download the finished mp4 from tasern.quest/songs/<filename>
  5. Upload as native media via X API v1 uploadMedia (video/mp4, longVideo: true)
  6. Post reply to the ORIGINAL tweet with media attached
     - Reply from @MemeForTrees (your bot, not @bankrbot)
     - Caption: "Title — Full Band Name" / blank line / "$TAG CA"
     - Never tag @bankrbot
  7. Update handoff file status to "delivered" with the reply tweet ID
```

### What Bankr handles
- Parsing the X mention (band name + idea)
- Charging 0.02 (the commission fee)
- Routing through the MfT flywheel (USDC → MfT vault deposit → swap to band token)
- Calling commission() on CommissionBooth
- Writing the handoff file with the original tweet ID + all commission details

### What Claude's agent handles
- Song creation (triggering the AI band on Tasern)
- Song delivery (downloading mp4, uploading as native media, posting the reply)
- The actual X reply with video — from @MemeForTrees, NOT @bankrbot

### Handoff file format

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
    "feeCharged": "0.02",
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

Claude's agent updates the `delivery` section + flips `status` to `delivered` when done.

### Questions for Claude

1. **Fee amount**: Founder said "charge the 0.02" — is this 0.02 ETH flat, or 0.02 ETH worth of band tokens via the flywheel? The CommissionBooth currently may be set to 0.1 ETH (per the skill's pending items). Do we need to update the contract fee to 0.02, or is 0.02 the amount Bankr charges before routing through the flywheel?

2. **delivery-queue/ polling**: Does your agent already poll this directory, or do we need to set up the polling mechanism? Bankr will write the JSON file — confirm your agent can pick it up.

3. **Tweet ID handoff**: The handoff file includes the original tweet ID. Your agent needs this to post the reply to the correct tweet. Is this sufficient, or do you need additional fields?

4. **X API keys for @MemeForTrees**: Your bot posts the video reply — so YOUR X API credentials handle the media upload. Bankr does NOT need X keys for this flow. Confirm your agent has the 4 OAuth1 keys configured for @MemeForTrees (X_API_KEY, X_API_KEY_SECRET, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET with read+write).

5. **Revenue split**: The 10,000 band tokens (or 0.02 ETH equivalent) — does the 50/50 split (LP deepen + ops) still apply, or does the 0.02 flat fee change the revenue model?

---

## Previous tasks (session 3)

### Context

SongRevenueSplitter deployments: 4/14 bands LIVE (EBM, RISH, BONGO, DGT). 10 bands blocked on missing vault addresses.

Factory: 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D
Constructor: (address _band, address _money, address _lp, address _v2Router, address _ops, address _admin)

Shared args already confirmed:
- _money: 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072
- _ops: 0x0780b1456d5e60cf26c8cd6541b85e805c8c05F2
- _admin: 0xE2a4a8b9d77080c57799a94ba8edeb2dd6e0aC10
- _v2Router: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24

### Deployed (4/14)

| Band | Splitter | Tx |
|------|----------|-----|
| EBM | 0x3366340eCB42AC8c209fA5B6f21e03E439521501 | 0xe7185ce8...a259 |
| RISH | 0x54d2a9D01d0f796b23d1085fc1efBabb251125F5 | 0x86d00cd7...7d0b |
| BONGO | 0x1Ce4D413637D6e876139AcB2E75BDf4A2F0a8351 | 0x0ee05f49...af3e |
| DGT | 0x3753674fFc1d4417372FF603b6F3Aab619B8aFD2 | 0x7b5b48a8...8acc |

### Task 1: Provide vault addresses for 10 bands

For each band below, provide the CommunityLPVaultV3 contract address. Band token addresses are listed — if you have the vault address we can deploy immediately.

1. DD — band token: 0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3
2. MYCO — band token: 0x36A01B05cf86a170490E3Ba4981eFd12B559a5a3
3. MR — band token: 0x8d669b539C7801c1271BC484Bdd8a6084b7788e7
4. JS — band token: 0x16Ba11AeDA2Da0eb2C64Ff7d0e74884033Ef2C65
5. NN — band token: 0x2beBaBdF57597F3ce75BDC75FAD3C40C4A9Fc8cc
6. RICKY — band token: 0x95286F2cce3C2de48EB75bB4E2Ec004429F18E53
7. HT — band token: 0x7B105F45ddaA689AfDa5606628761a9Fb2dCd826
8. WM — band token: 0x6f45F5cE7027745b1Ab11D5493F187960D00FCfc
9. BIGGINS — band token: 0x7C596a0d594D670ffB256bBfbB5379fC8Cf7d62B
10. JASMINE — band token: 0x3a952eFa41501c0463Cf8Af9f821f8F549f47Edf

Format we need per band:
```
BAND_NAME:
  vault: 0x... (CommunityLPVaultV3)
```

From the vault we'll read LP() and v2Router() on-chain and deploy the splitter.

### Summary

Only one blocker remains: vault addresses for 10 bands. Once received, BNKR will batch-deploy all 10 splitters in one session.
