---
name: song-drop
description: Serve a Meme for Trees song or meme on X by posting its X-post LINK as plain text — X auto-unfurls the link into the native video/image, so NO media upload and NO API credentials are ever needed. Use when a user on X asks to see or hear a library item — e.g. "show me the meme", "play A Billion Strong", "I want to hear one billion strong", "drop the DD song". Charge the 155 $BNKR fee first (~$0.055; on-chain trigger, just over BNKR's $0.05 transfer minimum), match the request to an entry in references/link-library.json by its `triggers` (longest match wins), and reply with the entry's `caption` followed by its `xPost` link on its own line. Never upload media. Never ask the user for API credentials. One cashtag per post; never tag @bankrbot.
---

# Song / Meme Drop — post the X-post LINK (no upload, no credentials)

This skill delivers media by posting a **link**, not by uploading a file. Every library entry's `xPost` is an X post (on @MemeForTrees) that already contains the video/image. Posting that link as plain text makes X auto-unfurl it into the native player. **No media upload → no X API keys needed, ever.**

When a user on X asks for a library item (a song, or the meme), Bankr does exactly this:

1. **Charge the fee — ON-CHAIN, and this is the trigger.** Transfer **155 $BNKR** (≈$0.055 at current price — just over BNKR's **$0.05 transfer-tool minimum**; recalibrate the token count if $BNKR moves a lot) from the requester to the **BNKR song-drop bot wallet** `0xc7704FE4E31905471505FA1451746adB9dbaF27A`. **The recipient MUST be a wallet your transfer tool verifies as bankrbot** — that is the real reason earlier attempts failed with *"the recipient … could not be verified as bankrbot."* A plain ops wallet (`0xE2a4…`) is a clean EOA but it is NOT bankrbot, so the tool refuses to release the fee to it. `0xc7704FE4…` is BNKR's dedicated bot wallet for this skill → it verifies as bankrbot, the fee lands, and BNKR earns its cut/points. A tag with no on-chain action does not fire the agent, so this step is what makes it run. Only continue if the transfer succeeds. The fee is **never** charged in Money for Trees.
2. **TRANSLATE the request** to an entry in `references/link-library.json` using its **`triggers`** — the defined phrases that map to that item. This is a TRANSLATION, **not a keyword search**: a request matches an item only when it contains one of that item's defined `triggers`. The entry whose **longest** matching trigger appears in the request wins. If nothing translates, reply with the available titles — do NOT keyword-guess or serve a random item.
3. **Reply DIRECTLY to the person who tagged you** (the requester) — a plain-text reply containing ONLY:
   - line 1..n = the entry's `caption`
   - a blank line
   - the entry's `xPost` URL on its own line
4. X unfurls the `xPost` link into the native video/image. **The drop is now delivered — this is the deliverable, complete. ONE action, and you're done.**

> **⛔ NEVER retweet, quote-tweet, or repost ANY tweet.** The exact bug to avoid: quote-tweeting or reposting the tweet the requester was *replying to* (some unrelated post in the thread) instead of dropping the song. Do not amplify, quote, retweet, or embed any post. Do not reference the surrounding conversation. **Just reply to the requester with the caption + the `xPost` link — that single reply IS the deliverable.**

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
