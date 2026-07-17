# Bankr Media Post Tool — Public Spec

> Anyone can post an image or video to X as native media by tagging @bankrbot.
> Small fee per post (0.03 USDC). No API keys for the user. No dev setup. Just tag and pay.
> Bankr charges + writes handoff. Claude's agent (@MemeForTrees) uploads + posts the media.

---

## How It Works (User Perspective)

1. User tags @bankrbot on X with an image/video attached to their tweet:
   - `@bankrbot post this`
   - `@bankrbot share this image`
   - `@bankrbot post my video`

2. Bankr charges the user's wallet 0.03 USDC on Base (auto-swapped from whatever token they hold if no USDC).

3. Bankr writes a handoff file to `delivery-queue/<tweetId>.json` with the tweet ID + media reference.

4. Bankr posts a text reply from @bankrbot: "posting your media — @MemeForTrees will drop it"

5. Claude's agent picks up the handoff, downloads the media from the tweet, re-uploads as native media via X API v1 `uploadMedia`, and posts the reply from @MemeForTrees with the media attached inline.

6. The media plays inline on X — no broken links, no bare URLs, no "video attached" text.

---

## Fee Model

| Parameter | Value |
|-----------|-------|
| Fee per media post | 0.03 USDC on Base (→ 0.02 after upgrade) |
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
Post the media
```

Simple: charge USDC, transfer to ops, post. No flywheel, no LP, no splits. This is a utility tool, not a yield product.

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

If the user includes caption text after the command, Bankr uses it as the post text. If not, Bankr uses a default: "Posted via @MemeForTrees" or similar.

---

## Post Behavior

| Scenario | Behavior |
|----------|----------|
| User's tweet has media + "post this" | Bankr charges 0.03, writes handoff, posts text reply. Claude's agent downloads media, re-uploads, posts native media reply from @MemeForTrees |
| User's tweet has media + "post this with [caption]" | Same but with user's caption |
| User's tweet has no media | Decline: "attach an image or video and I'll post it for 0.03 USDC" |
| User has insufficient funds | Decline: "insufficient funds — need 0.03 USDC on Base" |
| Media too large | Decline: "media too large — max 5MB images, 512MB videos" |
| Unsupported format | Decline: "unsupported format — use PNG, JPEG, GIF, or MP4" |

---

## Architecture — Two-Layer Split

### Layer 1: Bankr (transaction + handoff)

| Step | Action |
|------|--------|
| 1 | Parse the tweet for media + command |
| 2 | Charge 0.03 USDC from user wallet → ops wallet |
| 3 | Write handoff JSON to `delivery-queue/<tweetId>.json` |
| 4 | Post text reply from @bankrbot: "posting your media — @MemeForTrees will drop it" |
| 5 | Done |

### Layer 2: Claude's Agent (media delivery)

| Step | Action |
|------|--------|
| 1 | Poll `delivery-queue/` for new handoffs |
| 2 | Download media from the original tweet (X API v2 media endpoint) |
| 3 | Upload as native media via X API v1 `uploadMedia` |
| 4 | Post reply from @MemeForTrees with media attached + caption |
| 5 | Write `deployed/delivered/<tweetId>.json` + push |

### Handoff file format

```json
{
  "tweetId": "1234567890123456789",
  "type": "media-post",
  "caption": "user's caption or null",
  "commission": null
}
```

---

## No Blocker

Unlike earlier versions of this spec, there is NO architectural blocker. Claude's agent (@MemeForTrees) handles all media upload + posting using its own X API credentials. Bankr handles charging + handoff + text reply. Both sides are proven.

---

## Variables Summary

| Variable | Value |
|----------|-------|
| Tool name | Bankr Media Post |
| Fee | 0.03 USDC per post (→ 0.02 after upgrade) |
| Fee token | USDC on Base (auto-swap from any Base token if needed) |
| Fee destination | Ops wallet (0x0780b1456d5e60cf26c8cd6541b85e805c8c05f2) |
| Supported media | PNG, JPEG, GIF, MP4 |
| Max image size | 5 MB |
| Max video size | 512 MB |
| Post method | X API v1 uploadMedia + v2 reply (via Claude's agent) |
| Posting account | @MemeForTrees |
| Text reply account | @bankrbot |
| Trigger | Tag @bankrbot with media attached + "post this" or similar |
| Handoff | delivery-queue/<tweetId>.json in this repo |

---

## Relationship to MfT Song Commission

This is a general-purpose tool. The MfT Song Commission system (see SONG-COMMISSION-SPEC.md) is a specialized version that:
- Uses the same handoff + delivery architecture
- Can trigger AI band song creation on Tasern (commissions) or pull from the library (free pulls)
- Uses the same caption format for band-token songs ($TAG + contract address)

Both tools share the same delivery layer (Claude's agent, @MemeForTrees, X API media upload).
