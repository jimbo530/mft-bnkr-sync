# BNKR App Request — Impact Leaderboard Token + LP Tracking

## What I Built
I deployed a BNKR app: **MfT Impact Leaderboard** (slug: `mft-impact-leaderboard`)
- URL: https://bankr.bot/apps/mft-impact-leaderboard
- Fetches from `https://tasern.quest/api/leaderboard` every 6h + manual refresh
- Shows: network summary, top-20 token leaderboard, per-vault fund breakdowns
- Cached in appKV (`leaderboard_snapshot`)

## What I Need From Claude

### 1. Full Token + LP Address Registry
The tasern.quest API tracks ~53 tokens but `impact-network.json` has 361 tokens across 14 categories. I need a complete registry to track ALL tokens and their LPs.

**For each token, provide:**
- Token name + symbol
- Contract address (Base or Robinhood Chain)
- Chain (base / robinhood)
- Category (Band Token, Nation Coin, Ecosystem Token, Carbon Credit, Game Currency, Ship Token, Reactor, Impact Vault, etc.)
- **LP pair address** (Uniswap V2 or V3 pair contract)
- **Router** used (V2: `0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24`, V3: `0x3fC91A3e7035Cf3F6F8e6cC0c23F6C6D4c7e2D5b`, or other)
- Which vault/fund it belongs to (if any)
- Whether it has a deployed impact vault

### 2. Confirmed Band Token Status (14 bands)

**Have vaults + LPs (4):**
| Band | Token | Vault | LP Pair |
|------|-------|-------|---------|
| EBM | 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d | 0xdd47bdDD35866735ac79f9F3F8d4f0513555Ed95 | 0x7B053D6dCB7AfB45c5D57C85c0442312d9Cd04Dd |
| RISH | 0x31c600871603bab5d855463E03c6d0a9eB661D26 | 0x131bd427935980bbE43c30c3d0aF49e33c0E98E1 | 0x87E363B27A77C593965e8FAE9466d5f98fc3E408 |
| BONGO | 0x85Dd5183D203CcE70b88234D31f075774AcCC453 | 0x3aF2d7CCc05FdF3bC6Be14d1F159826b0f31198f | 0xEdA306F5ebC51144890E6b6Efc3511dc5593056D |
| DGT | 0x52414B7cD2FA723E1c8f9295EB29F16d15aA7BB9 | 0x43ebB722e17dBe698AA70A55Cb428b171A5da367 | 0x3E2F276Af52ED472b8f727083f1cBD047fE45692 |

**No vaults yet (10) — need LP addresses too:**
| Band | Token Address |
|------|---------------|
| DD | 0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3 |
| MYCO | 0x36A01B05cf86a170490E3Ba4981eFd12B559a5a3 |
| MR | 0x8d669b539C7801c1271BC484Bdd8a6084b7788e7 |
| JS | 0x16Ba11AeDA2Da0eb2C64Ff7d0e74884033Ef2C65 |
| NN | 0x2beBaBdF57597F3ce75BDC75FAD3C40C4A9Fc8cc |
| RICKY | 0x95286F2cce3C2de48EB75bB4E2Ec004429F18E53 |
| HT | 0x7B105F45ddaA689AfDa5606628761a9Fb2dCd826 |
| WM | 0x6f45F5cE7027745b1Ab11D5493F187960D00FCfc |
| BIGGINS | 0x7C596a0d594D670ffB256bBfbB5379fC8Cf7d62B |
| JASMINE | 0x3a952eFa41501c0463Cf8Af9f821f8F549f47Edf |

**For the 10 without vaults:** Do they have Uniswap V2/V3 LP pairs? If yes, give me the pair addresses so I can track LP TVL even before vaults are deployed.

### 3. Non-Band Tokens — Full LP Map
I need LP addresses for ALL tracked categories:
- **Nation Coins** (17 tokens) — LP pair + chain
- **Ecosystem Tokens** (27 tokens) — LP pair + chain
- **Carbon Credits** (8 tokens) — LP pair + chain
- **Game Currencies** (15 tokens) — LP pair + chain
- **Ship Tokens** (4 tokens) — LP pair + chain
- **Reactors** (35 tokens) — LP pair + chain
- **Impact Vaults** (24 tokens) — vault address + LP pair

### 4. Tasern API Endpoints — Confirm Shape
I'm using `https://tasern.quest/api/leaderboard`. Are there additional endpoints I should hit?
- `/api/trees/by-token` — per-token tree funding?
- `/api/trees/by-fund` — per-fund breakdown?
- Any endpoint for LP TVL or pair reserves?
- Any endpoint for yield flow / pending yield per token?

### 5. Logo URLs
Pattern seems to be `https://tasern.quest/<token>-logo.<ext>`. Confirm:
- Exact pattern (case-sensitive? extension?)
- Which tokens have logos available?
- Any tokens missing logos?

### 6. What I'll Do With This
Once I have the full token + LP registry, I'll upgrade the app to:
- Show ALL 361 tokens (not just top 20) with search/filter by category
- Display LP TVL alongside deposited amount
- Show LP pair address + router for each token
- Category-based leaderboard views (bands only, nation coins only, etc.)
- Per-token detail view with LP reserves, vault status, yield flow
- Band vault deployment status tracker (4/14 done, 10 pending)

## Format
Please output as a JSON file: `token-lp-registry.json` in this repo. Structure:
```json
{
  "tokens": [
    {
      "symbol": "EBM",
      "name": "Ethereal Band Music",
      "address": "0x...",
      "chain": "base",
      "category": "Band Token",
      "lpPair": "0x...",
      "lpRouter": "0x...",
      "lpVersion": "v2",
      "vault": "0x...",
      "hasVault": true,
      "fund": "MfT",
      "logoUrl": "https://tasern.quest/EBM-logo.png"
    }
  ],
  "endpoints": {
    "leaderboard": "https://tasern.quest/api/leaderboard",
    "byToken": "https://tasern.quest/api/trees/by-token",
    "byFund": "https://tasern.quest/api/trees/by-fund",
    "lpTvl": "https://tasern.quest/api/lp/tvl"
  }
}
```

## Priority
1. Band tokens (14) — LP addresses for all, vault status
2. Impact Vaults (24) — vault + LP addresses
3. All other categories — LP addresses
4. API endpoint confirmation
5. Logo URL confirmation

Drop the JSON in this repo and I'll wire it into the app.
