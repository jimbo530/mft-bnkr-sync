# Video Library Post Skill — Spec

> Bankr posts music videos from registered libraries as native X video replies.
> Anyone tags @bankrbot on X → Bankr charges 0.03 USDC → writes handoff → Claude's agent (@MemeForTrees) posts the video inline.
> Libraries are extensible — add new ones, same posting logic applies to all.

---

## What It Does

1. User tags @bankrbot on X: `@bankrbot play an EBM song` or `@bankrbot drop a DD track`
2. Bankr parses the request, looks up the band/artist in the registered library
3. Bankr charges 0.03 USDC from the user's wallet → ops wallet
4. Bankr writes a handoff file to `delivery-queue/<tweetId>.json`
5. Bankr posts a text reply from @bankrbot: "your [BAND] song is coming — @MemeForTrees will drop it"
6. Claude's agent picks up the handoff, fetches the video, uploads as native media, posts the video reply from @MemeForTrees

The video plays inline on X. No bare URLs, no "video attached" text, no broken posts.

---

## Fee

| Parameter | Value |
|-----------|-------|
| Fee per video post | 0.03 USDC on Base (→ 0.02 after upgrade) |
| Fee routing | Tagger's Bankr wallet → ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2) |
| If user has no USDC | Auto-swap from ETH or any Base token to USDC, then charge |
| If insufficient funds | Decline gracefully |
| Free tier | None — every video post costs 0.03 USDC |

$0.03 covers the X API media upload cost (borne by Claude's agent) + margin. Simple charge, no flywheel, no LP routing.

---

## Architecture — Two-Layer Split

### Layer 1: Bankr (transaction + handoff)

| Step | Action |
|------|--------|
| 1 | Parse band/artist name + optional title from the tweet |
| 2 | Charge 0.03 USDC from tagger's wallet → ops wallet |
| 3 | Write handoff JSON to `delivery-queue/<tweetId>.json` |
| 4 | Post text reply from @bankrbot pointing to the incoming video |
| 5 | Done |

### Layer 2: Claude's Agent (video delivery)

| Step | Action |
|------|--------|
| 1 | `song-booth.js --serve-watch` polls `delivery-queue/` |
| 2 | Picks up handoff file |
| 3 | Looks up song in catalog (random or by title) |
| 4 | Downloads mp4 from library baseUrl + filename |
| 5 | Uploads as native media via X API v1 `uploadMedia` (video/mp4, longVideo: true) |
| 6 | Posts reply from @MemeForTrees with media attached + caption |
| 7 | Writes `deployed/delivered/<tweetId>.json` + pushes |

### Handoff file format

```
delivery-queue/<tweetId>.json
```

```json
{
  "tweetId": "1234567890123456789",
  "band": "EBM",
  "title": "A Billion Strong",
  "commission": null
}
```

- `commission` = null for library pulls (existing songs)
- `commission` = prompt string for new song commissions
- `title` = specific song title if requested, omit for random

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

## Caption format

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
| MfT song catalog (302 songs) | Live in repo |
| tasern.quest video hosting | Live (HTTP 200, video/mp4) |
| Request parsing (band aliases) | In mft-song-delivery skill |
| Caption formatting | In mft-song-delivery skill |
| Fee charging (0.03 USDC transfer) | Bankr handles transfers natively |
| Handoff file writing | Ready to build |
| Text reply from @bankrbot | Bankr's text pipeline works |
| Claude's agent video delivery | LIVE — song-booth.js --serve-watch, poster.js |
| Library registry (extensible) | Needs building |

### No blocker

Unlike the earlier specs, there is NO architectural blocker. Claude's agent (@MemeForTrees) handles all media upload + posting. Bankr handles charging + handoff + text reply. Both sides are proven.

---

## Variables Summary

| Variable | Value |
|----------|-------|
| Skill name | Video Library Post |
| Fee | 0.03 USDC per video post (→ 0.02 after upgrade) |
| Fee token | USDC on Base |
| Fee destination | Ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2) |
| First library | MfT Songs (tasern.quest/songs/) |
| Library count | Extensible — add more via registry |
| Catalog | 302 songs, 14 bands (MfT) |
| Video delivery | @MemeForTrees via X API v1 uploadMedia + v2 reply |
| Text reply | @bankrbot posts text reply pointing to incoming video |
| Handoff | delivery-queue/<tweetId>.json in this repo |
| Handoff format | { tweetId, band, title?, commission? } |
| Trigger | Tag @bankrbot + band/artist name + "play/drop/give me/post" |
