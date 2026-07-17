# Bankr Media Post Tool — Public Spec

> Anyone can post an image or video to X as native media by tagging @bankrbot.
> Small fee per post (0.03 USDC). No API keys for the user. No dev setup. Just tag and pay.
> Bankr posts the media directly from @bankrbot — no handoff, no second agent, no blocker.

---

## How It Works (User Perspective)

1. User tags @bankrbot on X with an image/video attached to their tweet:
   - `@bankrbot post this`
   - `@bankrbot share this image`
   - `@bankrbot post my video`

2. Bankr charges the user's wallet 0.03 USDC on Base (auto-swapped from whatever token they hold if no USDC).

3. Bankr downloads the media from the tweet, re-uploads as native media, and posts the reply from @bankrbot with the media attached inline.

4. The media plays inline on X — no broken links, no bare URLs, no "video attached" text.

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

| Type | Format | Max Size |
|------|--------|----------|
| Image | PNG, JPEG, GIF | 5 MB |
| Video | MP4 | 512 MB |
| Animated GIF | GIF | 15 MB |

---

## Trigger Phrases

- `@bankrbot post this`
- `@bankrbot share this`
- `@bankrbot post my image`
- `@bankrbot post my video`
- `@bankrbot share this image/video`
- `@bankrbot post this with [caption text]`

If the user includes caption text after the command, Bankr uses it as the post text. If not, Bankr uses a default caption.

---

## Post Behavior

| Scenario | Behavior |
|----------|----------|
| User's tweet has media + "post this" | Bankr charges 0.03, downloads media, re-uploads as native media, posts reply from @bankrbot |
| User's tweet has media + "post this with [caption]" | Same but with user's caption |
| User's tweet has no media | Decline: "attach an image or video and I'll post it for 0.03 USDC" |
| User has insufficient funds | Decline: "insufficient funds — need 0.03 USDC on Base" |
| Media too large | Decline: "media too large — max 5MB images, 512MB videos" |
| Unsupported format | Decline: "unsupported format — use PNG, JPEG, GIF, or MP4" |

---

## Architecture — Single Layer (Bankr Direct)

| Step | Action |
|------|--------|
| 1 | Parse the tweet for media + command |
| 2 | Charge 0.03 USDC from user wallet → ops wallet |
| 3 | Download media from the original tweet |
| 4 | Upload as native media (Bankr's existing media posting capability) |
| 5 | Post reply from @bankrbot with media attached inline + caption |
| 6 | Done |

No handoff. No second agent. No external API keys. Bankr posts directly.

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
| Post method | Bankr's native media posting capability |
| Posting account | @bankrbot |
| Trigger | Tag @bankrbot with media attached + "post this" or similar |

---

## Relationship to MfT Song Delivery

The MfT Song Delivery system (see SONG-COMMISSION-SPEC.md) uses the same Bankr media posting capability:
- Free pulls: Bankr fetches video from tasern.quest library → posts native video reply from @bankrbot
- Commissions: Bankr charges fee → triggers Tasern for song creation → posts finished video from @bankrbot

Both the general media post tool and MfT song delivery use Bankr's existing ability to post images and videos natively on X.
