# Impact Leaderboard — Data Spec (make the bankr.bot board MATCH tasern.quest)

**Board:** https://bankr.bot/apps/mft-impact-leaderboard — currently showing WRONG data.

**Root cause (confirmed live 2026-07-18):** it pulls `tasern.quest/api/leaderboard`, which is **404 — dead.** So it renders a stale/empty cache.

**THE FIX (one line):** pull **`https://tasern.quest/api/trees/by-token`** instead. That is the live, correct, already-ranked board. Read `.leaderboard` + `.summary`, render in order → it matches ours exactly.

---

## 1. THE board — `GET https://tasern.quest/api/trees/by-token`

Returns `{ summary, leaderboard }`. **`leaderboard` is already ranked — render in the given order, never re-sort.**

```json
{
  "summary": {
    "totalDeposited": 1944.63,
    "totalTreesFunded": 14.509,
    "treesPerYear": 194.46,
    "vaultCount": 2,
    "tokenCount": 53,
    "pendingYieldUsd": 0,
    "totalYieldSentUsd": 0
  },
  "leaderboard": [
    {
      "rank": 1,
      "token": "Meme for Trees",
      "totalDeposited": 591.14,
      "treesFunded": 6.171,
      "treesPerYear": 59.11,
      "funds": {
        "Trees (MfT)":        { "deposited": 586.03, "treesFunded": 6.165 },
        "Polyraiders (PRGT)": { "deposited": 5.11,   "treesFunded": 0.006 }
      }
    }
    // ... 53 entries total, LIVE ...
  ]
}
```

**Entry fields (per token):**

| field | meaning | example |
|---|---|---|
| `rank` | 1-based, pre-sorted | `1` |
| `token` | display name | `"Meme for Trees"` |
| `totalDeposited` | USD deposited through this token's vault | `591.14` |
| `treesFunded` | headline impact, blended across the token's funds | `6.171` |
| `treesPerYear` | projected annual | `59.11` |
| `funds` | per-fund breakdown `{ "<Fund Name>": { deposited, treesFunded } }` | see above |

**Live top of the board right now — the bankr.bot board MUST show exactly this:**

| rank | token | deposited | trees funded | /yr |
|---|---|---|---|---|
| 1 | Meme for Trees | $591.14 | 6.171 | 59.11 |
| 2 | Elven Gold Piece | $103.91 | 1.332 | 10.39 |
| 3 | REGEN Network | $91.41 | 1.227 | 9.14 |
| 4 | Direct Holders | $49.55 | 0.661 | 4.95 |

Header stats come straight from `summary`: **$1,944.63 deposited · 14.509 trees funded · 53 tokens.**

---

## 2. Fund / cause breakdown — `GET https://tasern.quest/api/trees/by-fund`

For the "by cause" view. Returns `{ summary, funds }`. There are **2 funds** — and each has its OWN label/unit, so DON'T hardcode "trees" for all:

```json
{
  "summary": { "...same summary block..." },
  "funds": {
    "Trees (MfT)": {
      "vault": "MfT",
      "impactLabel": "Trees Funded",
      "impactUnit": "trees",
      "totalDeposited": 1571.87,
      "totalTreesFunded": 14.416,
      "pendingYieldUsd": 0,
      "totalYieldSentUsd": 0
    },
    "Polyraiders (PRGT)": {
      "vault": "PRGT",
      "impactLabel": "Funds Sent to Help Kids",
      "impactUnit": "USD",
      "totalDeposited": 373.02,
      "totalTreesFunded": 0.431
    }
  }
}
```

Use each fund's own `impactLabel` + `impactUnit` on its card.

---

## 3. Summary only — `GET https://tasern.quest/api/trees`

Same `summary` block, no arrays. Use for a lightweight header refresh.

---

## Endpoint status (probed live 2026-07-18)

| endpoint | status | use |
|---|---|---|
| `/api/trees/by-token` | ✅ LIVE | **THE board** (summary + ranked leaderboard) |
| `/api/trees/by-fund` | ✅ LIVE | fund / cause breakdown |
| `/api/trees` | ✅ LIVE | summary only |
| `/api/leaderboard` | ❌ 404 | **dead — this is what you're wrongly pulling** |
| `/api/leaderboard.json` | ❌ 404 | dead |
| `/api/impact` | ❌ 404 | dead |
| `/api/vaults` | ❌ 404 | dead |

## Render rules (to MATCH tasern.quest)

1. Fetch `/api/trees/by-token`. Render `leaderboard` **in the given order** (already ranked — never re-sort).
2. Per row: `rank` · `token` · `$totalDeposited` · `treesFunded` trees · `treesPerYear`/yr.
3. Header: from `summary` — total deposited, total trees funded, token count.
4. "By cause" tab: `/api/trees/by-fund` → one card per fund, using that fund's own `impactLabel` / `impactUnit`.
5. Numbers are LIVE (deposits accrue). Poll ~2 min (your existing appKV cadence is fine) — just point it at the LIVE url, not the dead one.
6. Logos (optional): `https://tasern.quest/<symbol-lower>-logo.png|jpg|webp`; map token name → symbol via `token-lp-registry.json` if you add them.

---

**Bottom line: change the one URL from `/api/leaderboard` → `/api/trees/by-token`, read `.leaderboard` + `.summary`, render in order. The board matches ours.**
