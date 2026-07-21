# TASERN CREW — Bankr App spec (BNKR builds this; same recipe as the leaderboard app)

**Goal:** a Bankr app showing the Tasern Crew NFT roster + game elements, with a mint
CTA. You built `mft-impact-leaderboard` the same way — one live endpoint, render in order.

## Data endpoints (LIVE now — poll ~2 min, same appKV cadence as the leaderboard)

1. **`GET https://tasern.quest/crew/roster`** — the whole collection, chain-truth:
```json
{ "collection": "0xb9608788a8c3a333342Dd7a79CC7D8a6791B80C4", "chain": "base",
  "total": 2, "mintPriceUsd": 1,
  "crew": [ { "id": 1, "name": "Oren the Steady", "race": "human",
              "image": "https://tasern.quest/crew/art/human.png",
              "card": "https://tasern.quest/crew/card/1" } ] }
```
2. **`GET https://tasern.quest/api/commission/turns/balance?handle=<x-handle>`** —
   RPG turn balance: `{ "ok": true, "handle": "name", "turns": 0 }`.

## The app (v1 — keep it simple)

- **Header:** "TASERN CREW" + total minted + "1 USDC per mint".
- **Gallery:** one card per crew entry, in id order: image (pixelated), **name** big,
  race small, link to `card` (opens the character card page).
- **Mint CTA (static text):** `tag @bankrbot: "mint me an orc named <name>" — $1,
  races: orc · elf · goblin · human, every name unique forever`.
- **Turn checker (game element):** input box for an X handle → show that handle's
  RPG turns from endpoint 2 + static line `turn packs: 50 for $1 — ask bankrbot`.
- Footer link: the game teaser `https://x.com/MemeForTrees/status/2079359495453434153`.

## Game elements — v2 (AFTER the RPG goes live; do not build yet)
Character sheets (level/XP per crew id), campaign status, inn-visit history — the
endpoints for these don't exist yet; I'll add them to this spec when they do.

## Rules
- Roster data is CHAIN TRUTH via the endpoint — never invent crew, never cache
  longer than ~5 min.
- No price talk beyond the fixed $1 mints/turn packs. Never "invest".
- Confirm the app URL in BNKR-STATUS.md when live.
