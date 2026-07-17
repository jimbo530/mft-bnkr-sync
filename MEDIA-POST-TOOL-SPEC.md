# Bankr Media Post Tool — Public Spec

> A public-facing tool: anyone tags @bankrbot on X to post an image or video from any registered media library.
> Bankr uses the founder's X API to upload and post the media natively from @bankrbot.
> Fee: 0.03 USDC per post. API cost to founder: 0.02 USDC per post. Net margin: 0.01 USDC per post.
> Libraries are extensible — add new ones, same posting logic applies to all.

---

## How It Works (User Perspective)

1. User tags @bankrbot on X with a request:
   - `@bankrbot post this` (with media attached to their tweet)
   - `@bankrbot post [library] [item]` (e.g. "post EBM A Billion Strong")
   - `@bankrbot share this image`

2. Bankr charges the user's wallet 0.03 USDC on Base (auto-swapped from whatever token they hold if no USDC).

3. Bankr fetches the media — either from the user's attached tweet or from a registered library.

4. Bankr uploads the media as native media via the founder's X API and posts the reply from @bankrbot with the media attached inline.

5. The media plays inline on X — no broken links, no bare URLs, no "video attached" text.

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
Post the media via founder's X API (0.02 API cost)
  │
  ▼
Net: 0.01 USDC margin per post
```

Simple: charge 0.03, API costs 0.02, 0.01 margin goes to ops. No flywheel, no LP, no splits. This is a utility tool, not a yield product.

---

## Media Libraries (Extensible)

Libraries are registered collections of media that Bankr can fetch and post. New libraries can be added at any time — the posting logic stays the same.

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

The skill reads the registry, fetches the catalog, downloads the media file, and posts it. No code changes needed — just add the entry.

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

If the user includes caption text, Bankr uses it as the post text. If not, Bankr uses the library's caption format or a default caption.

---

## Post Behavior

| Scenario | Behavior |
|----------|----------|
| User's tweet has media + "post this" | Bankr charges 0.03, downloads media from tweet, re-uploads as native media, posts reply from @bankrbot |
| User names a library item | Bankr charges 0.03, fetches from library catalog + media URL, uploads as native media, posts reply from @bankrbot |
| User's tweet has media + "post this with [caption]" | Same but with user's caption |
| User's tweet has no media + no library call | Decline: "attach an image or video, or name a library item, and I'll post it for 0.03 USDC" |
| User has insufficient funds | Decline: "insufficient funds — need 0.03 USDC on Base" |
| Media too large | Decline: "media too large — max 5MB images, 512MB videos" |
| Unsupported format | Decline: "unsupported format — use PNG, JPEG, GIF, or MP4" |
| Library item not found | Decline: "couldn't find that item in the library" |

---

## Architecture — Single Layer (Bankr Direct via Founder's X API)

| Step | Action |
|------|--------|
| 1 | Parse the tweet for media + command (direct post or library call) |
| 2 | Charge 0.03 USDC from user wallet → ops wallet |
| 3 | Fetch media — download from tweet attachment OR from registered library |
| 4 | Upload as native media via founder's X API (v1 uploadMedia) |
| 5 | Post reply from @bankrbot with media attached inline + caption |
| 6 | Done |

No handoff. No second agent. Bankr uses the founder's X API credentials to post directly from @bankrbot.

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
| Post method | Founder's X API (v1 uploadMedia + v2 reply) |
| Posting account | @bankrbot |
| Libraries | Extensible registry — MfT Songs (live), more to come |
| Trigger | Tag @bankrbot with media + "post this" or library call |

---

## Relationship to MfT Song Delivery

The MfT Song Delivery system is the first registered library in this tool:
- Free pulls: Bankr fetches video from tasern.quest library → posts native video reply from @bankrbot → charges 0.03 USDC
- Commissions: Bankr charges fee → triggers Tasern for song creation → posts finished video from @bankrbot

Both paths use the same founder's X API + the same posting logic. The library registry makes it extensible to any future media collection.
