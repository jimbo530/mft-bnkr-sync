# Bankr Media Post Tool — Public Spec

> Anyone can post an image or video to X as native media by tagging @bankrbot.
> Small fee per post ($0.01). No API keys for the user. No dev setup. Just tag and pay.

---

## How It Works (User Perspective)

1. User tags @bankrbot on X with an image/video attached to their tweet:
   - `@bankrbot post this`
   - `@bankrbot share this image`
   - `@bankrbot post my video`

2. Bankr charges the user's wallet $0.01 (USDC on Base, or auto-swapped from whatever token they hold).

3. Bankr downloads the media from the tweet, re-uploads it as native media via X API v1 `uploadMedia`, and posts a reply (or quote tweet) from @bankrbot with the media attached inline.

4. The media plays inline on X — no broken links, no bare URLs, no "video attached" text.

---

## Fee Model

| Parameter | Value |
|-----------|-------|
| Fee per media post | $0.01 USD (charged in USDC on Base) |
| If user has no USDC | Auto-swap from ETH or any Base token to USDC, then charge |
| If user has insufficient funds | Decline gracefully, reply with "insufficient funds — need $0.01 USDC on Base" |
| Free tier | None — every media post costs $0.01 |
| Refunds | No refunds once the post is live |

### Fee routing

```
$0.01 from user wallet
  │
  ▼
USDC on Base (swap if needed from ETH/other token)
  │
  ▼
Transfer to Bankr ops/treasury wallet
  │
  ▼
Post the media
```

Simple: charge USDC, transfer to treasury, post. No flywheel, no LP, no splits. This is a utility tool, not a yield product.

---

## Supported Media Types

| Type | Format | Max Size | X API |
|------|--------|----------|-------|
| Image | PNG, JPEG, GIF | 5 MB | v1 uploadMedia |
| Video | MP4 | 512 MB | v1 uploadMedia (longVideo: true) |
| Animated GIF | GIF | 15 MB | v1 uploadMedia |

---

## Trigger Phrases

- `@bankrbot post this`
- `@bankrbot share this`
- `@bankrbot post my image`
- `@bankrbot post my video`
- `@bankrbot share this image/video`
- `@bankrbot post this with [caption text]`

If the user includes caption text after the command, Bankr uses it as the post text. If not, Bankr uses a default: "Posted via @bankrbot" or similar.

---

## Post Behavior

| Scenario | Behavior |
|----------|----------|
| User's tweet has media + "post this" | Bankr downloads media, re-uploads, posts as reply to user's tweet |
| User's tweet has media + "post this with [caption]" | Same but with user's caption |
| User's tweet has no media | Decline: "attach an image or video and I'll post it for $0.01" |
| User has insufficient funds | Decline: "insufficient funds — need $0.01 USDC on Base" |
| Media too large | Decline: "media too large — max 5MB images, 512MB videos" |
| Unsupported format | Decline: "unsupported format — use PNG, JPEG, GIF, or MP4" |

---

## Architecture

### Current Bankr posting pipeline

Bankr already posts text from @bankrbot through an internal X integration. This pipeline does NOT currently expose:
- Media download from tweets
- Media upload via X API v1 `uploadMedia`
- Native media attachment to v2 tweet/reply posts

### What's needed to enable this tool

| Component | Status | Owner |
|-----------|--------|-------|
| X API OAuth1 credentials (read+write, media upload) | NOT configured — Bankr platform decision | Bankr platform team |
| Media download from tweet (fetch attached image/video) | Not built — needs X API v2 media endpoint or tweet lookup | Bankr |
| Media upload via v1 uploadMedia | Skill code exists (twitter-api-v2), but no credentials to run it | Bankr |
| Fee charging (USDC transfer) | Bankr already handles transfers — this is solved | Bankr |
| Reply/quote-tweet with media_ids | Skill code exists, needs credentials | Bankr |

### The one blocker

X API credentials. Bankr's text-posting pipeline is a closed abstraction that doesn't expose OAuth1 keys to the agent sandbox. For media upload, the sandbox needs the 4 keys directly:

- `X_API_KEY`
- `X_API_KEY_SECRET`
- `X_ACCESS_TOKEN`
- `X_ACCESS_TOKEN_SECRET`

These must be authorized for @bankrbot's account with Read+Write permissions (media upload requires write).

This is a platform-level decision: does Bankr provision X API credentials for media upload, or does it stay text-only?

If yes → this tool is live, $0.01 per post, anyone can use it.
If no → this tool cannot function. The architectural blocker is the same one that blocks native video for MfT songs.

---

## Variables Summary

| Variable | Value |
|----------|-------|
| Tool name | Bankr Media Post |
| Fee | $0.01 USD per post |
| Fee token | USDC on Base (auto-swap from any Base token if needed) |
| Fee destination | Bankr treasury/ops wallet |
| Supported media | PNG, JPEG, GIF, MP4 |
| Max image size | 5 MB |
| Max video size | 512 MB |
| Post method | X API v1 uploadMedia + v2 reply/quote with media_ids |
| Posting account | @bankrbot |
| Trigger | Tag @bankrbot with media attached + "post this" or similar |
| Blocker | X API credentials not provisioned for media upload |

---

## Relationship to MfT Song Commission

This is a general-purpose tool. The MfT Song Commission system (see SONG-COMMISSION-SPEC.md) is a specialized version that:
- Charges 0.02 ETH (not $0.01)
- Routes through the MfT flywheel (not a simple USDC transfer)
- Triggers AI band song creation on Tasern (not just re-posting user media)
- Delivers from @MemeForTrees (not @bankrbot)

The Media Post Tool could eventually serve as the delivery layer for MfT songs too — if Bankr provisions credentials, both tools use the same `uploadMedia` path.
