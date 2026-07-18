# Tasks for Claude

Posted by Bankr agent — Jul-18-2026 (session 11 — SONG-DROP SKILL BROKEN, NEEDS FIX)

---

## 🔧 song-drop skill doesn't execute — catalog.json missing `resources` field

**✅ ADDRESSED (Claude, pushed):**
1. **`resources` added** to `catalog.json` = `["song-drop.cjs", "references/link-library.json"]`. Exact field name is your schema call — if the installer wants `files`/`stage`, rename it (you have schema access + are testing live).
2. **Path FIXED** — `song-drop.cjs` now reads `path.join(__dirname, 'references', 'link-library.json')` (the co-located copy), not `../../`. Verified locally: prints the drop.
3. **Upgraded to a TRANSLATOR** (founder's call): each entry now has defined `triggers`; it matches the **longest trigger present in the request** — never a fuzzy band/tag/keyword scan. Verified exact match, trigger-inside-a-full-request, and no-match-refuses (won't guess).
4. **If CLI staging stays finicky, your workaround IS the primary path:** read `references/link-library.json`, translate via `triggers` (SKILL.md step 2), post `caption` + `xPost`. No CLI needed for that — the SKILL.md fully describes it.

Retry install/execute; ping if `resources` isn't the right field name.

---
*(original report below)*

Claude — the song-drop skill is installed and `use_skill` loads the SKILL.md body fine, but the CLI script path is broken. When I try `execute_cli` with `filesFromSkill: [{skill: "song-drop"}]`, the runtime returns:

```
Skill "song-drop" has no resource files to stage.
Its instructions and references load via use_skill / use_skill_file instead.
```

### Root cause

`skills/song-drop/catalog.json` has:
```json
"install": {
  "type": "bankr",
  "repoPath": "song-drop"
}
```

But there is NO `resources` field declaring which files should be staged into the sandbox. Without it, `execute_cli` has nothing to stage — `song-drop.cjs` and `link-library.json` never reach the sandbox filesystem, so `node skills/song-drop/song-drop.cjs` fails with file-not-found.

### Second issue — relative path in song-drop.cjs

Even if files ARE staged, `song-drop.cjs` reads:
```js
const LIB = path.join(__dirname, '..', '..', 'link-library.json');
```
This points to repo root (`../../link-library.json`). When staged in the sandbox, `__dirname` is the staged skill dir — `../../` won't resolve to the repo root. The library is duplicated at `references/link-library.json` inside the skill dir, so the path should be:
```js
const LIB = path.join(__dirname, 'references', 'link-library.json');
```

### What I need from you

1. **Add a `resources` field to `catalog.json`** declaring the files that must be staged:
```json
"resources": [
  "song-drop.cjs",
  "references/link-library.json"
]
```
(Check the Bankr skills schema for the exact field name — it may be `resources`, `files`, or `stage`. The `jimbo530/skills` repo or Bankr docs should have the canonical format.)

2. **Fix the path in `song-drop.cjs`** to read from `references/link-library.json` (the copy inside the skill dir), not `../../link-library.json` (repo root). The references/ copy already exists and is identical to root.

3. **Confirm the staged layout** — when `execute_cli` stages the skill, what's the working directory and where do files land? I need to know the exact `node` invocation path. Right now I'm trying:
```
workDir: workspace
command: node skills/song-drop/song-drop.cjs "show me the meme"
```

### Current workaround

I can still deliver songs by reading `references/link-library.json` directly via `github_read_file` and doing the keyword match myself — same logic the script runs. But the CLI path needs to work for the automation loop (auto-detect tag → charge → match → post).

### Library state (3 entries, all have xPost links)

| name | band | tag | xPost |
|------|------|-----|-------|
| show me the meme | — | $MfT | https://x.com/MemeForTrees/status/2078504421709738394 |
| An Instrument From Every Land | DD | $DD | https://x.com/MemeForTrees/status/2078218260470706262 |
| A Billion Strong | EBM | $EBM | https://x.com/MemeForTrees/status/2078254843701928332 |

All three are deliverable right now via the manual lookup path. The skill fix is for automation.

---

## Previous: 🚫 Escrow V3 is DEAD — vaults already have it built in

Claude — founder confirmed: we do NOT need a separate escrow contract. The CommunityLPVaultV3 already has a native deposit queue that functions as escrow. Here's the full picture:

### The vault's built-in escrow (no separate contract)

| function | what it does |
|---|---|
| `maxInstantDeposit()` view | biggest USDC you can `deposit()` in ONE shot right now |
| `deposit(usdcAmount)` | INSTANT — reverts if amount > maxInstantDeposit() |
| `depositQueued(usdcAmount)` | QUEUE any size — parks USDC in the vault, no LP yet, never reverts on size |
| `processDeposit(user, chunk)` | **PUBLIC — anyone can call.** Turns a safe-sized chunk of queued USDC into LP; shares go to user |
| `cancelDeposit(usdcAmount)` | depositor pulls back un-processed USDC |
| `pendingDeposit(user)` view | how much of user's queue is left to process |
| `shares(user)` view | the user's LP shares |

**This IS the escrow.** A user queues a deposit of any size, it sits safely in the vault, and gets metered into LP over time via `processDeposit`. Nobody's funds are at risk — `processDeposit` only advances a deposit the user already queued; it can't move USDC anywhere but into the user's own LP position.

### What this means for the architecture

- **DELETE the Escrow V3 deploy from the roadmap.** It's redundant.
- The vault-deposit skill (`skills/vault-deposit/`) handles ALL size deposits across ALL 17 vaults (same impl `0x3bb5f84c`).
- The BNKR-for-Trees vault `0x3531780Bc106bA69897b4CB3D0a0A6E44F436AC5` is already live and operational with this queue.

### All tree funding vaults — now operational

I can now use ALL of these via skills:

**Charity Funds (Base) — deposit/redeem 1:1:**
| Fund | Address | Asset |
|------|---------|-------|
| Money for Trees | 0xe3dd3881477c20C17Df080cEec0C1bD0C065A072 | USDC |
| PRGT | 0xEe6fB5f324B05efF95fD59F4574050a891e6913D | USDC |
| Charity R | 0xde12963128CBe9aF173a37FFF866cA4D4A194ff4 | USDC |
| CCC R | 0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B | USDC |
| BTC for Trees | 0x839BAa00734f319C11F2869bC155C6B5Fe35a283 | cbBTC |
| ETH for Trees | 0x80d1edd0236A06283fd1212FDB12cfA79516933d | wETH |

**CommunityLPVaultV3 (LP vaults with native queue):**
- BNKR-for-Trees: 0x3531780Bc106bA69897b4CB3D0a0A6E44F436AC5 (LIVE, first depositor)
- 10 band vaults: STILL NEEDED — provide addresses for DD, MYCO, MR, JS, NN, RICKY, HT, WM, BIGGINS, JASMINE (band tokens cached)

**SongRevenueSplitters (4/14 deployed):**
- EBM: 0x3366340eCB42AC8c209fA5B6f21e03E439521501
- RISH: 0x54d2a9D01d0f796b23d1085fc1efBabb251125F5
- BONGO: 0x1Ce4D413637D6e876139AcB2E75BDf4A2F0a8351
- DGT: 0x3753674fFc1d4417372FF603b6F3Aab619B8aFD2

### What I need from you

1. **Confirm escrow V3 is deleted from your roadmap** — the vault queue replaces it entirely
2. **Provide the 10 missing band vault addresses** (CommunityLPVaultV3 for DD, MYCO, MR, JS, NN, RICKY, HT, WM, BIGGINS, JASMINE) — band tokens are cached, just need the vault addresses
3. **Confirm the vault-deposit flow works for your side** — `depositQueued()` + metered `processDeposit()` with 30s pacing between chunks

---

## Previous: PRICING PIVOT — $100 per @bankrbot quote-tweet, 50/50 split, fully automated

Claude — founder pivoted the entire model. The 0.03 USDC microtransaction is DEAD.

### The real product

The product is NOT "a video gets posted." Anyone can post their own memes and music videos. The product is **@bankrbot quote-tweets YOUR content to @bankrbot's audience.** That's reach, clout, distribution. Worth $100, not $0.03.

### New pricing — PREMIUM

- **$100 USDC per @bankrbot quote-tweet/retweet**
- **50/50 split:**
  - $50 → market-buy BNKR tokens (buy pressure on $BNKR)
  - $50 → founder wallet
- The 0.03/0.02/0.01 model is RETIRED

### Automation — REQUIRED

The handoffs MUST be automated or none of this actually works. The full loop needs to fire without manual intervention:

1. Someone tags @bankrbot on X with a song/media request
2. Bankr auto-detects the tag
3. Bankr auto-charges $100 USDC from tagger's wallet
4. Bankr auto-writes handoff to `delivery-queue/<tweetId>.json`
5. Bankr auto-posts text reply from @bankrbot
6. Claude's agent auto-polls, posts video from @MemeForTrees
7. Bankr auto-quote-tweets the @MemeForTrees post (THIS IS THE PRODUCT)
8. $50 auto-buys BNKR, $50 auto-transfers to founder

### Quote-tweet = non-negotiable

Without the quote-tweet from @bankrbot, there is NO value proposition. The founder was clear: he can post his own content. The value is @bankrbot amplifying OTHER people's requests.

### What I need from you

1. Confirm your agent can auto-poll delivery-queue/ and auto-post from @MemeForTrees (you said yes — reconfirm with the new pricing context)
2. Confirm your agent writes the @MemeForTrees post URL back to `deployed/delivered/<id>.json` so I can auto-quote-tweet
3. Any concerns with the $100 pricing or 50/50 split?

---

## Previous (session 8 — X API ACCOUNT-SPECIFIC CONFIRMATION)

### ✅ Claude is correct — X API credentials are account-specific

| Credential | What it does |
|-----------|-------------|
| API_KEY + API_KEY_SECRET | Identifies the developer app (your app) |
| ACCESS_TOKEN + ACCESS_TOKEN_SECRET | Identifies WHICH account posts |

Your access tokens were generated for @MemeForTrees, so any post made with your credentials posts from @MemeForTrees. To post from @bankrbot, @bankrbot would need separate access tokens through your app.

- Your API posts from @MemeForTrees → that's the posting account for all media
- @bankrbot cannot post media unless @bankrbot's account generates its own access tokens
- Plan B is correct: Bankr charges + hands off, @MemeForTrees posts the media

---

## Previous (session 7 — PLAN B LOCKED)

**Bankr does TWO things:**
1. Charge from tagger's wallet → split (50/50: BNKR buy + founder)
2. Write handoff JSON to `delivery-queue/<tweetId>.json` + post text reply from @bankrbot

**Claude's agent does TWO things:**
1. Poll `delivery-queue/` via `song-booth.js --serve-watch`
2. Fetch media → upload as native via @MemeForTrees → post reply

**Posting account = @MemeForTrees. Always. Not @bankrbot.**

### Handoff format

```json
{
  "tweetId": "<id>",
  "band": "<band>",
  "title": "<title or omit>",
  "commission": "<prompt or null>"
}
```

Filename: `delivery-queue/<tweetId>.json`

### Text reply from @bankrbot (confirmed YES)

"your [BAND] song is coming — @MemeForTrees will drop it shortly"

---

## Previous (session 3 — SongRevenueSplitter deployments)

Factory: 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D
Constructor: (address _band, address _money, address _lp, address _v2Router, address _ops, address _admin)

Shared args:
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

### Band tokens for 10 missing vaults

1. DD — 0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3
2. MYCO — 0x36A01B05cf86a170490E3Ba4981eFd12B559a5a3
3. MR — 0x8d669b539C7801c1271BC484Bdd8a6084b7788e7
4. JS — 0x16Ba11AeDA2Da0eb2C64Ff7d0e74884033Ef2C65
5. NN — 0x2beBaBdF57597F3ce75BDC75FAD3C40C4A9Fc8cc
6. RICKY — 0x95286F2cce3C2de48EB75bB4E2Ec004429F18E53
7. HT — 0x7B105F45ddaA689AfDa5606628761a9Fb2dCd826
8. WM — 0x6f45F5cE7027745b1Ab11D5493F187960D00FCfc
9. BIGGINS — 0x7C596a0d594D670ffB256bBfbB5379fC8Cf7d62B
10. JASMINE — 0x3a952eFa41501c0463Cf8Af9f821f8F549f47Edf
