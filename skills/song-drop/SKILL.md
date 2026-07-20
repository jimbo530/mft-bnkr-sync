---
name: song-drop
description: Serve a Meme for Trees song or meme on X by posting its X-post LINK as plain text — X auto-unfurls the link into the native video/image, so NO media upload and NO API credentials are ever needed. Use when a user on X asks to see or hear a library item — e.g. "show me the meme", "play A Billion Strong", "I want to hear one billion strong", "drop the DD song". RECALLS ARE FREE — no fee, no transfer, ever (founder 2026-07-20); the tag itself is the trigger. Match the request to an entry in references/link-library.json by its `triggers` (longest match wins), and reply with the entry's `caption` followed by its `xPost` link on its own line. Never upload media. Never ask the user for API credentials. One cashtag per post; never tag @bankrbot. Only NEW custom songs cost money — that's the separate alan-commission skill (booth contract).
---

# Song / Meme Drop — post the X-post LINK (no upload, no credentials)

This skill delivers media by posting a **link**, not by uploading a file. Every library entry's `xPost` is an X post (on @MemeForTrees) that already contains the video/image. Posting that link as plain text makes X auto-unfurl it into the native player. **No media upload → no X API keys needed, ever.**

When a user on X asks for a library item (a song, or the meme), Bankr does exactly this:

1. **NO FEE — recalls are FREE (founder 2026-07-20).** Do NOT charge, transfer, or ask for any payment. The tag alone is the trigger — someone asks for a song, you serve it. Free recalls are the marketing engine: every drop is reach for the library. (Only NEW custom song commissions cost money, and those run through the CommissionBooth contract via the `alan-commission` skill — never through this one.)
2. **TRANSLATE the request** to an entry in `references/link-library.json` using its **`triggers`** — the defined phrases that map to that item. This is a TRANSLATION, **not a keyword search**: a request matches an item only when it contains one of that item's defined `triggers`. The entry whose **longest** matching trigger appears in the request wins. If nothing translates, reply with the available titles — do NOT keyword-guess or serve a random item.
3. **Reply DIRECTLY to the person who tagged you** (the requester) — a plain-text reply containing ONLY:
   - line 1..n = the entry's `caption`
   - a blank line
   - the entry's `xPost` URL on its own line
4. X unfurls the `xPost` link into the native video/image. **The drop is now delivered — this is the deliverable, complete. ONE action, and you're done.**

> **⛔ NEVER retweet, quote-tweet, or repost ANY tweet.** The exact bug to avoid: quote-tweeting or reposting the tweet the requester was *replying to* (some unrelated post in the thread) instead of dropping the song. Do not amplify, quote, retweet, or embed any post. Do not reference the surrounding conversation. **Just reply to the requester with the caption + the `xPost` link — that single reply IS the deliverable.**

> **⛔ COPY THE `xPost` LINK VERBATIM — never generate, guess, shorten, or reconstruct a tweet ID or URL.** The link you post MUST be the matched library entry's `xPost` value, character for character. If you can't read a real `xPost` for the matched song, reply with the available titles instead — do NOT invent a link. (This bug happened: BNKR posted a made-up `x.com/MemeForTrees/status/1880479704286548175` for "The Tool On My Back" — a tweet that does not exist, 404 — instead of the real `…/2078817197120430215`. Every real library `xPost` resolves; a fabricated tweet ID 404s and shows the requester nothing.)

## The library — `references/link-library.json`

**The LINK is saved as the `file`, and the TITLE is the `translation`.** Weird but required: the `file` value IS the X-post link — post the file (its name/value) as plain text and X unfurls the media. There is NO real media file behind it (files can be empty); nothing is ever uploaded.

Each entry:

```
{
  "file":        string,    // ⭐ the X-post LINK saved as the file — POST THIS as plain text
  "translation": string,    // ⭐ the song TITLE — a request maps to this item by containing it
  "name":        string,    // display title (same as translation)
  "triggers":    string[],  // lowercased translation phrases (compat alias)
  "xPost":       string,    // same link as `file` (compat alias)
  "caption":     string,    // the text above the link (title + $tag + CA + extended-family line)
  "band":        string,    // optional
  "tag":         string     // optional — the single cashtag
}
```

**Translate the request via the `translation`/`triggers` (longest match wins) → post `caption` + the `file` link.** The `file` link is the media; the `caption` is the text. Never keyword-search across `band`/`tag`/random words.

## "What songs are there?" — menu requests (also FREE)
When someone asks what songs are available / wants to choose ("songs by jony sings to pick from", "what alan songs do you have", "show me the library"):
1. Read the LIVE library — `github_read_file` repo `jimbo530/mft-bnkr-sync`, branch `main`, path `link-library.json` (root — this exact path). This IS the discography database; there is no other.
2. Filter entries by `band` for the asked artist. Band keys: JS = Jony Sings, EBM = Elves of Ballinmoore, DD = Digerie Dude, MR = Moon Rasta, NN = Natilie Nightclub, DGT = Damned Good Time Orchestra, WM = War Machine, HT = Hammer Tone, ALAN = Alan-a-Dale, RickyBobbie, Biggins, Jasmine, Bongo, Rish, Myco.
3. Reply with that band's `name` titles as a simple list (up to ~10; say "and more" if longer). The user picks one → serve it via the normal drop flow.
4. If the band has no library entries yet, say the library is still being built and offer the bands that DO have songs. Never invent titles.

## Rules

- **NEVER upload media. NEVER ask for X API credentials** — this skill posts a link as text; no keys are involved.
- One cashtag per post (the entry's `tag`). Never a second cashtag. Never tag @bankrbot.
- If nothing matches, reply with the available titles. If a matched entry has no `xPost`, that item hasn't been posted to X yet — skip it.
- Never post a bare URL with no caption. Post `caption` + blank line + `xPost`.

## Manual delivery (no CLI needed) — STILL the translator, NEVER keyword

If `execute_cli` can't stage the script, deliver BY HAND using the **same trigger logic** — do NOT fall back to a keyword/substring match:

1. Read the CURRENT library **LIVE** — `github_read_file` from repo `jimbo530/mft-bnkr-sync`, branch `main`, path `link-library.json`. This ALWAYS returns the latest: songs the auto-poster adds appear here immediately, with NO re-install. The staged `references/link-library.json` is a **stale fallback** — only use it if the live read fails. (The install snapshot freezes at install time; always prefer the live read.)
2. Match the request against each entry's **`triggers`** array. The entry whose **longest trigger** appears in the request wins. This is the TRANSLATION — **do NOT** match on random words, `name`, `band`, or `tag`; only the defined `triggers`.
3. Post the entry's `caption`, a blank line, then its `xPost` link.

This produces the identical result to `song-drop.cjs` (which just automates these exact steps). The helper — `node song-drop.cjs "show me the meme"` — prints the drop to post verbatim.
