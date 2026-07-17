# Bankr Media Post Tool — Public Spec (FINAL — Plan B Locked)

> A public-facing tool: anyone tags @bankrbot on X to post an image or video from any registered media library.
> Bankr charges 0.03 USDC + writes a handoff file. Claude's agent (@MemeForTrees) posts the media natively.
> API cost to founder: 0.02 USDC per post. Net margin: 0.01 USDC per post.
> Libraries are extensible — add new ones, same posting logic applies to all.

---

## Architecture — Two Layer (LOCKED)

```
User tags @bankrbot on X: "post this" or "play EBM A Billion Strong"
  │
  ▼
BANKR (charge + handoff layer):
  1. Parse the tweet for media + command (direct post or library call)
  2. Charge 0.03 USDC from user wallet → ops wallet (0x0780...)
  3. Write handoff JSON to delivery-queue/<tweetId>.json
  4. Post text reply from @bankrbot: "your [item] is coming — @MemeForTrees will drop it"
  5. DONE — Bankr's job ends here
  │
  ▼
CLAUDE'S AGENT (@MemeForTrees — media upload + post layer):
  1. song-booth.js --serve-watch polls delivery-queue/
  2. Picks up handoff file
  3. Fetch media — download from tweet attachment OR from registered library
  4. Upload as native media via X API v1 uploadMedia (founder's keys, @MemeForTrees account)
  5. Post reply to original tweet from @MemeForTrees with media attached inline + caption
  6. Write deployed/delivered/<id>.json + push
```

**Why two layers:** @bankrbot cannot upload media — no X media tool in Bankr's platform, no credentials in the agent sandbox (proven by test, commit 9ece966). @MemeForTrees has the keys, the uploadMedia code, and the tested pipeline. Bankr's role = charge + handoff + text reply. Claude's role = media upload + post.

---

## How It Works (User Perspective)

1. User tags @bankrbot on X with a request:
   - `@bankrbot post this` (with media attached to their tweet)
   - `@bankrbot post [library] [item]` (e.g. "post EBM A Billion Strong")
   - `@bankrbot share this image`

2. Bankr charges the user's wallet 0.03 USDC on Base (auto-swapped from whatever token they hold if no USDC).

3. Bankr writes a handoff file to `delivery-queue/<tweetId>.json`.

4. Bankr posts a text reply from @bankrbot: "your [item] is coming — @MemeForTrees will drop it shortly"

5. Claude's agent picks up the handoff, fetches the media, uploads as native media, and posts the video/image reply from @MemeForTrees to the original tweet.

6. The media plays inline on X — no broken links, no bare URLs, no "video attached" text.

---

## Fee Model

| Parameter | Value |
|-----------|-------|
| Fee per media post | 0.03 USDC on Base |
| API cost per post (founder) | 0.02 USDC |
| Net margin per post | 0.01 USDC |
| If user has no USDC | Auto-swap from ETH or any Base token to USDC, then charge |
| If user has insufficient funds | Decline gracefully, reply with "insufficient funds — need 0.03 USDC on Base" |
| Free tier | None — every media post costs 0.03 USDC |
| Refunds | No refunds once the post is live |
| Fee destination | Ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2) |

### Fee routing

```
0.03 USDC from user wallet
  │
  ▼
Transfer to ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2)
  │
  ▼
Claude's agent posts media via @MemeForTrees (0.02 API cost)
  │
  ▼
Net: 0.01 USDC margin per post
```

Simple: charge 0.03, API costs 0.02, 0.01 margin goes to ops. No flywheel, no LP, no splits. This is a utility tool, not a yield product.

---

## Handoff Format

Bankr writes to `delivery-queue/<tweetId>.json`:

```json
{
  "tweetId": "<original tweet ID>",
  "band": "<band name, for MfT library>",
  "title": "<specific title, or omit for random>",
  "commission": "<prompt string for new songs, or null for existing items>"
}
```

- `tweetId` = the original tweet to reply to
- `band` = band name (for MfT song library)
- `title` = specific song title if requested, or omit for random selection
- `commission` = song idea/prompt for new songs, or `null` for existing library items
- Filename = `<tweetId>.json`

---

## Media Libraries (Extensible)

Libraries are registered collections of media that Claude's agent can fetch and post. New libraries can be added at any time — the posting logic stays the same.

### Library Registry

| Library | Catalog URL | Media Base URL | Status |
|---------|-------------|----------------|--------|
| MfT Songs | songs-catalog.json (this repo) | https://tasern.quest/songs/ | Live |
| _more to come_ | _TBD_ | _TBD_ | _Planned_ |

### Adding a New Library

To register a new library, add an entry with:
- `name` — library identifier
- `catalogUrl` — JSON catalog mapping item names to filenames
- `mediaBaseUrl` — base URL where media files are hosted
- `captionFormat` — optional caption template (e.g. MfT songs use "$TAG 0xCONTRACT")

Claude's agent reads the registry, fetches the catalog, downloads the media file, and posts it. No code changes needed — just add the entry.

### MfT Songs Library (First Library)

- 302 songs across 14 bands
- Catalog: `skills/mft-song-request/references/songs-catalog.json`
- Media base: `https://tasern.quest/songs/<filename>`
- Caption format: `Title — Band Name` + `$TAG 0xCONTRACT`
- Band aliases accepted (e.g. "elves" = EBM, "dude" = DD)

---

## Supported Media Types

| Type | Format | Max Size |
|------|--------|----------|
| Image | PNG, JPEG, GIF | 5 MB |
| Video | MP4 | 512 MB |
| Animated GIF | GIF | 15 MB |

---

## Trigger Phrases

### Direct media post (user attaches media)
- `@bankrbot post this`
- `@bankrbot share this`
- `@bankrbot post my image`
- `@bankrbot post my video`
- `@bankrbot post this with [caption text]`

### Library call (user names a library + item)
- `@bankrbot post [library] [item]`
- `@bankrbot play [band] [song]` (MfT library)
- `@bankrbot drop a [band] track` (MfT library)
- `@bankrbot give me a [band] song` (MfT library)

---

## Post Behavior

| Scenario | Bankr does | Claude's agent does |
|----------|-----------|---------------------|
| User's tweet has media + "post this" | Charge 0.03, write handoff with media reference, post text reply | Download media, upload as native, post reply from @MemeForTrees |
| User names a library item | Charge 0.03, write handoff with library + item, post text reply | Fetch from library, upload as native, post reply from @MemeForTrees |
| User has insufficient funds | Decline: "insufficient funds — need 0.03 USDC on Base" | Nothing |
| Media too large | Decline: "media too large — max 5MB images, 512MB videos" | Nothing |
| Library item not found | Decline: "couldn't find that item in the library" | Nothing |

---

## Variables Summary

| Variable | Value |
|----------|-------|
| Tool name | Bankr Media Post |
| Fee | 0.03 USDC per post |
| API cost (founder) | 0.02 USDC per post |
| Net margin | 0.01 USDC per post |
| Fee token | USDC on Base (auto-swap from any Base token if needed) |
| Fee destination | Ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2) |
| Supported media | PNG, JPEG, GIF, MP4 |
| Max image size | 5 MB |
| Max video size | 512 MB |
| Posting account | @MemeForTrees (Claude's agent, founder's X API keys) |
| Bankr's role | Charge 0.03 USDC + write handoff + post text reply from @bankrbot |
| Claude's role | Poll delivery-queue/ + fetch media + upload native + post from @MemeForTrees |
| Handoff path | delivery-queue/<tweetId>.json |
| Libraries | Extensible registry — MfT Songs (live), more to come |
| Trigger | Tag @bankrbot with media + "post this" or library call |

---

## Relationship to MfT Song Delivery

The MfT Song Delivery system is the first registered library in this tool:
- Free pulls: Bankr charges 0.03, writes handoff with `commission: null` → Claude's agent picks a song from the catalog, downloads, uploads, posts from @MemeForTrees
- Commissions: Bankr charges 0.03, writes handoff with `commission: "<idea>"` → Claude's agent triggers AI band on Tasern, creates the song, uploads, posts from @MemeForTrees

Both paths use the same handoff format + the same @MemeForTrees posting pipeline. The library registry makes it extensible to any future media collection.
