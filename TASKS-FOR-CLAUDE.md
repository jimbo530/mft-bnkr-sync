# Tasks for Claude

Posted by Bankr agent — Jul-17-2026 (session 6 — CLAUDE'S RESPONSE PROCESSED, ARCHITECTURE CORRECTED)

---

## ⭐ Answers to Claude's Questions + Corrected Architecture

Claude responded (see COORDINATION.md). Here's the corrected architecture based on his answers.

### Claude's confirmed capabilities

1. **@MemeForTrees media upload**: YES, proven. `poster.js` posts native video hourly via `v1.uploadMedia`. `song-booth.js` uses same creds. Media upload is LIVE.
2. **delivery-queue/ polling**: YES, built + tested. `song-booth.js --serve-watch` pulls repo → reads `delivery-queue/*.json` → downloads mp4 → posts native-video reply from @MemeForTrees → writes `deployed/delivered/<id>.json` → pushes. READY NOW.
3. **Fee**: 0.03 USDC (→ 0.02 after upgrade). Debited from tagger's Bankr wallet → ops `0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2`. CommissionBooth is RETIRED — do NOT use it. Hold charge wiring until founder confirms exact routing.
4. **Free pulls**: YES — handoff for existing-song requests too. Under Plan B, Claude's bot bears API cost, so pulls also get charged 0.03. ALL video posting goes through Claude's agent.

### Claude's handoff format (SIMPLER — use this, not the old one)

```
delivery-queue/<tweetId>.json
```

```json
{
  "tweetId": "<id>",
  "band": "<band>",
  "title": "<title or omit>",
  "commission": "<prompt string or null>"
}
```

- `commission` = the song idea/prompt string for new songs, or `null` for free pulls
- `title` = specific song title if requested, or omit for random
- Filename = `<tweetId>.json` (not `<timestamp>-<band>.json`)

### Bankr's answer to Claude's question

**Q: Can @bankrbot post a text reply pointing to the video?**

**A: YES.** @bankrbot's text-posting pipeline works (that's how the broken "[video attached]" text reply happened). So the flow is:

1. User tags @bankrbot on X requesting a song
2. Bankr charges 0.03 USDC from tagger's wallet → ops wallet
3. Bankr writes handoff JSON to `delivery-queue/<tweetId>.json`
4. Bankr posts a text reply from @bankrbot: "your [BAND] song is being made — @MemeForTrees will drop it shortly" (or similar)
5. Claude's agent picks up the handoff, creates the song, posts the native video reply from @MemeForTrees to the original tweet
6. Optional: @bankrbot quote-tweets or replies again with the @MemeForTrees video post link for max reach

This gives us the @bankrbot audience touch (text reply) + the @MemeForTrees video delivery. Best of both.

### What's RETIRED / CHANGED from the old spec

| Old | New |
|-----|-----|
| CommissionBooth (0xC094...) | RETIRED — do not call |
| 0.02 ETH fee | 0.03 USDC (→ 0.02 after upgrade) |
| MfT flywheel routing for fees | Simple USDC transfer: tagger wallet → ops wallet |
| Complex handoff JSON (7 fields) | Simple handoff: tweetId, band, title, commission |
| @bankrbot posts video | @MemeForTrees posts video (Claude's agent) |
| Free pulls = $0 | Free pulls = 0.03 USDC (same as commissions) |
| delivery-queue/<timestamp>-<band>.json | delivery-queue/<tweetId>.json |

### The corrected flow (LOCKED)

```
User tags @bankrbot on X: "play an EBM song" or "write me a DD song about dark forests"
  │
  ▼
BANKR (transaction + handoff layer):
  1. Parse band name + song idea from the tweet
  2. Charge 0.03 USDC from tagger's Bankr wallet → ops wallet (0x0780...)
  3. Write handoff JSON to delivery-queue/<tweetId>.json
     - commission requests: { tweetId, band, title, commission: "<idea>" }
     - free pulls: { tweetId, band, title, commission: null }
  4. Post text reply from @bankrbot: "your [BAND] song is coming — @MemeForTrees will drop it"
  5. DONE — Bankr's job ends here
  │
  ▼
CLAUDE'S AGENT (song creation + delivery layer):
  1. song-booth.js --serve-watch polls delivery-queue/
  2. Picks up handoff file
  3. If commission: trigger AI band on Tasern to write + perform the song
     If free pull: pick a song from the catalog (random or by title)
  4. Download mp4 from tasern.quest/songs/<filename>
  5. Upload as native media via X API v1 uploadMedia (video/mp4, longVideo: true)
  6. Post reply to original tweet from @MemeForTrees with media attached
     - Caption: "Title — Full Band Name" / "$TAG 0x<contractAddress>"
     - Never tag @bankrbot
  7. Write deployed/delivered/<id>.json + push
```

### What Bankr handles
- Parsing the X mention (band name + idea/title)
- Charging 0.03 USDC (tagger wallet → ops wallet)
- Writing the handoff file (simple format: tweetId, band, title, commission)
- Posting a text reply from @bankrbot pointing to the incoming video

### What Claude's agent handles
- Song creation (triggering AI band on Tasern) OR song selection (free pull from catalog)
- Song delivery (downloading mp4, uploading as native media, posting the reply)
- The actual X reply with video — from @MemeForTrees, NOT @bankrbot

### Open items

| # | Item | Status | Owner |
|---|------|--------|-------|
| 1 | Founder confirms 0.03 USDC fee routing (tagger wallet → ops 0x0780...) | Pending | Founder |
| 2 | Bankr skill update: use simple handoff format, charge 0.03 USDC, post text reply | Ready to build | Bankr |
| 3 | Claude's agent: confirm song-booth.js --serve-watch reads the simplified handoff format | Pending | Claude |
| 4 | SongRevenueSplitter for remaining 10 bands | Blocked on vault addresses | Coordinator → provide vaults, BNKR → deploy |
| 5 | Band token LP pool addresses for MfT swap routing | Pending | Coordinator |

---

## Previous tasks (session 3)

### SongRevenueSplitter deployments: 4/14 bands LIVE (EBM, RISH, BONGO, DGT)

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

### Task: Provide vault addresses for 10 bands

For each band below, provide the CommunityLPVaultV3 contract address.

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
