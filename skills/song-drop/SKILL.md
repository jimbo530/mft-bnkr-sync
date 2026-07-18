---
name: song-drop
description: Serve a Meme for Trees song or meme on X by posting its X-post LINK as plain text — X auto-unfurls the link into the native video/image, so NO media upload and NO API credentials are ever needed. Use when a user on X asks to see or hear a library item — e.g. "show me the meme", "play A Billion Strong", "I want to hear one billion strong", "drop the DD song". Charge the 0.01 $BNKR fee first (the on-chain trigger), match the request to an entry in references/link-library.json by its `name`, and reply with the entry's `caption` followed by its `xPost` link on its own line. Never upload media. Never ask the user for API credentials. One cashtag per post; never tag @bankrbot.
---

# Song / Meme Drop — post the X-post LINK (no upload, no credentials)

This skill delivers media by posting a **link**, not by uploading a file. Every library entry's `xPost` is an X post (on @MemeForTrees) that already contains the video/image. Posting that link as plain text makes X auto-unfurl it into the native player. **No media upload → no X API keys needed, ever.**

When a user on X asks for a library item (a song, or the meme), Bankr does exactly this:

1. **Charge the fee — ON-CHAIN, and this is the trigger.** Transfer **0.01 $BNKR** from the requester to the BNKR wallet `0xd7dfc7fe6c2b582b142dbc23ad172f735106b598`. A tag with no on-chain action does not fire the agent, so this step is what makes it run. Only continue if the transfer succeeds. The fee is **never** charged in Money for Trees.
2. **TRANSLATE the request** to an entry in `references/link-library.json` using its **`triggers`** — the defined phrases that map to that item. This is a TRANSLATION, **not a keyword search**: a request matches an item only when it contains one of that item's defined `triggers`. The entry whose **longest** matching trigger appears in the request wins. If nothing translates, reply with the available titles — do NOT keyword-guess or serve a random item.
3. **Post the drop as a plain-text reply** to the requester:
   - line 1..n = the entry's `caption`
   - a blank line
   - the entry's `xPost` URL on its own line
4. **Done.** X unfurls the `xPost` link into the native video/image. No media attachment.

## The library — `references/link-library.json`

Each entry:

```
{
  "name":     string,    // display title
  "triggers": string[],  // the defined phrases that TRANSLATE to this item (match on these)
  "xPost":    string,    // the X-post URL to reply with — X unfurls it into the media
  "caption":  string,    // the text above the link (title + $tag + CA line)
  "band":     string,    // optional
  "tag":      string     // optional — the single cashtag
}
```

**Translate the request via `triggers` (longest match wins) → post `caption` + `xPost`.** The `xPost` link is the media; the `caption` is the text. Never keyword-search across `band`/`tag`/random words.

## Rules

- **NEVER upload media. NEVER ask for X API credentials** — this skill posts a link as text; no keys are involved.
- One cashtag per post (the entry's `tag`). Never a second cashtag. Never tag @bankrbot.
- If nothing matches, reply with the available titles. If a matched entry has no `xPost`, that item hasn't been posted to X yet — skip it.
- Never post a bare URL with no caption. Post `caption` + blank line + `xPost`.

## Manual delivery (no CLI needed) — STILL the translator, NEVER keyword

If `execute_cli` can't stage the script, deliver BY HAND using the **same trigger logic** — do NOT fall back to a keyword/substring match:

1. Read `references/link-library.json`.
2. Match the request against each entry's **`triggers`** array. The entry whose **longest trigger** appears in the request wins. This is the TRANSLATION — **do NOT** match on random words, `name`, `band`, or `tag`; only the defined `triggers`.
3. Post the entry's `caption`, a blank line, then its `xPost` link.

This produces the identical result to `song-drop.cjs` (which just automates these exact steps). The helper — `node song-drop.cjs "show me the meme"` — prints the drop to post verbatim.
