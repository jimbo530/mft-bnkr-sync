# Video Library Post Skill — Spec

> Bankr posts music videos from registered libraries as native X video replies.
> Anyone tags @bankrbot on X → Bankr fetches the video from the library → posts it inline → charges $0.03.
> Libraries are extensible — add new ones, same posting logic applies to all.

---

## What It Does

1. User tags @bankrbot on X: `@bankrbot play an EBM song` or `@bankrbot drop a DD track`
2. Bankr parses the request, looks up the band/artist in the registered library
3. Bankr picks a song (random or by title if named)
4. Bankr downloads the mp4 from the library's URL
5. Bankr uploads as native media via X API and posts a reply with the video inline
6. Bankr charges $0.03 to the user's wallet

The video plays inline on X. No bare URLs, no "video attached" text, no broken posts.

---

## Fee

| Parameter | Value |
|-----------|-------|
| Fee per video post | $0.03 USD |
| Fee token | USDC on Base (auto-swap from ETH or any Base token if no USDC) |
| If insufficient funds | Decline gracefully |
| Fee destination | Bankr treasury |

$0.03 covers the X API media upload cost + margin. Simple charge, no flywheel, no LP routing.

---

## Library System

A library = a collection of videos hosted at a public URL, with a catalog that maps requests to files.

### Library registry

Each library is registered with:

```json
{
  "name": "MfT Songs",
  "baseUrl": "https://tasern.quest/songs/",
  "catalogFile": "skills/mft-song-request/references/songs-catalog.json",
  "aliases": {
    "EBM": ["elves of ballinmoore", "elves", "ebm"],
    "DD": ["digerie dude", "dude", "dd"],
    "MYCO": ["myconid", "mushroom bard", "myco"]
  },
  "captionFormat": "{title} — {band}\n${TAG} {contractAddress}",
  "tagField": "tag",
  "addressField": "address"
}
```

### Adding a new library

To register a new library, add an entry to the library registry with:
- `name` — display name
- `baseUrl` — where the video files are hosted
- `catalogFile` — JSON mapping of songs/artists to filenames
- `aliases` — what names the user can type to request from this library
- `captionFormat` — how the reply caption is formatted

The posting logic stays the same for every library. Only the source URL and catalog change.

### First library: MfT Songs

- Base URL: `https://tasern.quest/songs/`
- Catalog: 302 songs, 14 bands
- Catalog file: `skills/mft-song-request/references/songs-catalog.json`
- Each entry: `band`, `title`, `filename`, `videoUrl`
- Caption: `Title — Full Band Name` / `$TAG 0x<contractAddress>`

---

## Request Parsing

When @bankrbot is tagged on X:

1. Parse the tweet text for a library name or band/artist name
2. Match against all registered library aliases (case-insensitive)
3. If a title is mentioned, find the closest match in the catalog
4. If no title, pick a random song from that band/artist
5. If no band/artist matches, reply with available options

### Trigger phrases

- `@bankrbot play a [BAND] song`
- `@bankrbot drop a [BAND] track`
- `@bankrbot give me [BAND]`
- `@bankrbot play [TITLE] by [BAND]`
- `@bankrbot post a [BAND] video`
- `@bankrbot got any [BAND]?`

---

## Posting Flow

```
User tags @bankrbot on X
  │
  ▼
Parse request → match library + band/artist + optional title
  │
  ▼
Look up song in catalog → get filename
  │
  ▼
Download mp4 from library baseUrl + filename
  │
  ▼
Upload as native media via X API v1 uploadMedia (video/mp4, longVideo: true)
  │
  ▼
Post reply from @bankrbot with media attached + caption
  │
  ▼
Charge $0.03 to user wallet (USDC on Base)
```

### Caption format

```
Title — Full Band Name
$TAG 0x<contractAddress>
```

Rules:
- One cashtag per post
- Never tag @bankrbot in the caption
- Title and band name from the catalog entry

---

## What's Built vs What's Needed

| Component | Status |
|-----------|--------|
| MfT song catalog (302 songs) | ✅ Live in repo |
| tasern.quest video hosting | ✅ Live (HTTP 200, video/mp4) |
| Request parsing (band aliases) | ✅ In mft-song-delivery skill |
| Caption formatting | ✅ In mft-song-delivery skill |
| Fee charging ($0.03 USDC) | ✅ Bankr handles transfers natively |
| Library registry (extensible) | 🔲 Needs building |
| Native video upload + post | 🔲 Needs X API media upload capability |

### The one blocker

Native video upload requires X API credentials with media upload permission. Bankr's current X posting pipeline posts text only — it does not upload media.

To enable video posting, Bankr needs one of:
1. X API OAuth1 credentials provisioned for @bankrbot (read+write, media upload)
2. A native Bankr tool that handles media upload + posting (like the text reply pipeline, but for video)

Once either is in place, the skill runs end-to-end: fetch video → upload → post → charge.

---

## Variables Summary

| Variable | Value |
|----------|-------|
| Skill name | Video Library Post |
| Fee | $0.03 USD per video post |
| Fee token | USDC on Base |
| First library | MfT Songs (tasern.quest/songs/) |
| Library count | Extensible — add more via registry |
| Catalog | 302 songs, 14 bands (MfT) |
| Post method | X API v1 uploadMedia + v2 reply |
| Posting account | @bankrbot |
| Trigger | Tag @bankrbot + band/artist name + "play/drop/give me/post" |
| Blocker | X API media upload capability |
