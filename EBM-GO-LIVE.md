# EBM GO-LIVE — the reference song-booth loop

**Founder directive (2026-07-17): get EBM working end-to-end. Every other band is THIS file with `band` swapped.**

**Goal:** someone tags **@bankrbot** asking for an EBM song → their Bankr wallet is charged → our bot replies with the EBM song as native video (we capture the X creator revenue).

---

## Status

- ✅ **Our delivery end — PROVEN 2026-07-17.** `node song-booth.js --test EBM` (DRY, no post):
  - picks **"Grove Report Jun 26 2026"**, mp4 resolves **HTTP 200 (9.0MB)** at tasern.quest
  - caption built correctly: `$EBM 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d`
  - parser: `"can I get an EBM song"` → **EBM**
  - So the moment a `delivery-queue/*.json` appears, we deliver. Our half needs nothing more.
- ✅ **EBM SongRevenueSplitter — LIVE** `0x3366340eCB42AC8c209fA5B6f21e03E439521501` (the revenue destination).
- ⬜ **BNKR's charge + queue-write — the ONE open piece.**

---

## The loop (who does what)

1. **Customer** tweets, tagging **@bankrbot**: e.g. *"@bankrbot can I get an EBM song?"*

2. **BNKR** (transactions only — never posts to X):
   - **a. Charge** the tagging customer's Bankr wallet the song fee — start at **0.02 USDC** (or a set EBM-token amount; your call on the exact debit).
   - **b. Route** the fee to the **EBM splitter `0x3366340eCB42AC8c209fA5B6f21e03E439521501`** so it feeds the EBM LP + charity flywheel.
     *If your charge→splitter path isn't wired yet, a plain debit still proves the loop — say so in COORDINATION and we layer splitter routing in next. Do NOT block the loop on this.*
   - **c. Write the hand-off file** to the repo:
     ```
     delivery-queue/<anything-unique>.json
     ```
     ```json
     { "band": "EBM", "tweetId": "<the customer's tweet id>" }
     ```
     - `tweetId` = the tweet that tagged you (so we reply to the right person).
     - optional `"title": "..."` to request a specific song; omit and we pick an EBM song.
   - **d. Commit + push.** That's it — delivery is ours.

3. **Our bot** (`song-booth.js --serve-watch`, our X creds, running local now / VPS soon):
   - pulls the repo, sees the queue file
   - replies to `tweetId` with the EBM song as **native video** (X creator revenue → us)
   - writes `deployed/delivered/<id>.json`, removes the queue file, pushes.

---

## The gate — what BNKR must confirm (reply in COORDINATION.md)

1. You **can debit a tagging user's Bankr wallet** for the fee. *(You raised this question — confirm it here.)*
2. You can **write + push** `delivery-queue/<id>.json` in the exact format above.

When both are true, we run one **live EBM test**: a real tag → your charge + queue file → our delivery.
That proves the whole booth. Then bands 2–15 are literally this file with `"EBM"` swapped for the next band.
