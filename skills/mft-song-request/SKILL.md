---
name: mft-song-request
description: Serve a Meme for Trees song as an X reply. Use when a user on X asks to hear a song from one of the MfT bands — e.g. "play something from EBM", "post a Rish song", "give me a Bongo track", "got any DGT?". Look up the band in songs-catalog.json (in references/), pick a song (random or best match to any title hint the user gave), download the mp4, upload it as native media via the X API, and reply to the requester's tweet with the video attached and the correct caption. For band-token songs the caption MUST include the band's $TAG and CA on the same line. Never tag @bankrbot in the post. One cashtag per post only.
---

# Meme for Trees — Song Request

When a user on X asks for a song from a Meme for Trees band, Bankr:

1. **Charges the fee — ON-CHAIN, and this is the trigger.** Transfer the fee (see Fee below) in **$BNKR** from the requester to the BNKR wallet `0xd7dfc7fe6c2b582b142dbc23ad172f735106b598`. A tag with no on-chain action does not fire the agent, so this step is what makes the whole thing run. Only continue if the fee transfer succeeds.
2. Parses the band name from the request (case-insensitive, aliases accepted — see Band Name Aliases below).
3. Looks the band up in `references/songs-catalog.json`.
4. Picks a song — random by default; if the user named a title, pick the closest match.
5. The song is delivered as a reply to the requester with the correct caption (see Video delivery).

The fee is on-chain and required — it doubles as the trigger and accrues BNKR points. It is **never** charged in Money for Trees.

---

## Fee (on-chain — the trigger)

Every request charges a fee, paid in **$BNKR** (Bankr's own token), sent from the requester to the BNKR wallet:

- **Fee token:** `$BNKR` — Bankr's native token on Base. *(BNKR: use/confirm your own $BNKR token contract — the MfT side did not hardcode it, to avoid a wrong address.)*
- **Fee amount:** **0.01 $BNKR** per request. *(MfT-settable — change this one number to reprice.)*
- **Destination:** `0xd7dfc7fe6c2b582b142dbc23ad172f735106b598` — the BNKR wallet that collects fees for season points.

Why a fee at all: the agent acts on **on-chain intent**. A tag with no transaction gives it nothing to trigger on (an earlier "no on-chain required" version of this skill got no reply). The fee IS the trigger, and it's the point-earning "$BNKR flavor" the audience likes. Charge the fee first; only deliver the song if the transfer succeeds. Fees are **never** charged in Money for Trees.

---

## Trigger phrases (natural language)

- "play a song from [BAND]"
- "post something from [BAND]"
- "got any [BAND]?"
- "drop a [BAND] track"
- "give me a [BAND] song"
- "play [TITLE] by [BAND]"
- Any combination of a band name + "song / track / music / tune / bop"

---

## Band name aliases

Accept any of these as the canonical band name:

| Canonical   | Also accepts                                        |
|-------------|-----------------------------------------------------|
| EBM         | Elves of Ballinmoore, elves, ballinmoore            |
| DD          | Digerie Dude, digerie, dude, didgeridoo dude        |
| Myco        | myconid, mushroom bard, myco                        |
| MR          | Moon Rasta, moon rasta, rasta                       |
| JS          | Jony Sings, jony, jony sings                        |
| NN          | Natilie Nightclub, natalie nightclub, nightclub      |
| CB          | CB, coinbase band (note: CB has no band token CA)   |
| DGT         | Damned Good Time Orchestra, damned good time, dgt   |
| Bongo       | bongo, the monkey, monkey drummer                   |
| Rish        | rish, the fairy, fairy folk                         |
| RickyBobbie | Ricky Bobbie, ricky, rickybobbie, grandus fortuna   |
| HammerTone  | Hammer Tone, hammertone, dwarven band, ht           |
| WarMachine  | War Machine, warmachine, orks of orklin, wm         |
| Biggins     | Biggins Mcjammin, biggins, sasquatch punk           |
| Jasmine     | Jasmine the Tiger, jasmine, tiger                   |
| SEAS        | Seize the Seas OST, seas, port royal, shanty        |

---

## Catalog lookup

All songs are in `references/songs-catalog.json`. Each entry has:

```
{
  "band":     string,          // canonical band name
  "title":    string,          // song title
  "type":     string,          // band-token-song | mft-song | game-anthem | news
  "tag":      string | null,   // cashtag e.g. "$EBM" — null for SEAS
  "ca":       string | null,   // contract address — null for CB and SEAS
  "videoUrl": string,          // https://tasern.quest/songs/<encoded-filename>
  "filename": string           // exact on-disk name
}
```

Filter by `band` field (case-insensitive match against canonical name). If the user named a title, filter further by `title` (fuzzy/partial match). Otherwise pick randomly from the band's entries, excluding entries with `band:"unmapped"`.

---

## Caption rules

Build the reply caption as follows. The caption is the TEXT of the tweet — the video is attached separately as native media (see Video delivery), NOT pasted as a URL.

### Band-token songs (type = "band-token-song")

```
[Title] — [Full band name]

[tag] [ca]
```

Example for EBM "Canopy Law":
```
Canopy Law — Elves of Ballinmoore

$EBM 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d
```

### CB band songs (tag = "$MfT", ca = null)

```
[Title] — CB

$MfT
```

### MfT-songs (type = "mft-song")

Same format as band-token-song. The band still has a tag and/or CA — include them.

### Game anthems (type = "game-anthem", tag = null)

```
[Title] — Seize the Seas OST

tasern.quest
```

### News songs (type = "news")

```
[Title] — EBM Grove Report / Base Wire

$EBM 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d
```

---

## One-cashtag rule

**One cashtag per post, maximum.** Never add a second cashtag. Never tag @bankrbot.
The `tag` field in the catalog entry is the single cashtag to use. CB tracks use `$MfT`
(no CA). SEAS tracks use no cashtag at all.

---

## Video delivery (CRITICAL — native media, not URL embed)

X does NOT inline-play arbitrary mp4 URLs. A bare `videoUrl` pasted into the tweet body
will render as a plain text link, not a video player. The video only plays inline if it
is uploaded as native media and the resulting media id is attached to the tweet.

Delivery flow (via `execute_cli` with `twitter-api-v2@1.17.2`, env vars required):

1. Download the mp4 from the catalog entry's `videoUrl` to a local temp file.
2. Upload it as native media using the X API v1 media endpoint:
   - `client.v1.uploadMedia(fileBuffer, { mimeType: 'video/mp4', longVideo: true })`
   - Returns a `mediaIdString`.
   - `longVideo: true` is required for videos > ~15s / larger chunks.
3. Post the reply with the media attached:
   - `client.v2.reply(captionText, originalTweetId, { media: { media_ids: [mediaIdString] } })`
4. The caption text follows the Caption rules above (title + band name + cashtag line).
   Do NOT include the `videoUrl` in the tweet body — the video is attached as media.

Required env vars (set under Tools → Environment Variables):
- `X_API_KEY`, `X_API_KEY_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_TOKEN_SECRET`
  (from the X Developer Portal, Read and Write permissions)

If X API credentials are not configured, the delivery CANNOT attach a video — report
that the credentials are missing rather than falling back to a URL-in-body post.

Do NOT include the on-disk file path in the public post. Do NOT include `videoUrl`
in the public post. The video is attached as native media only.

---

## Unmapped entries

Songs with `band:"unmapped"` are pipeline artifacts with no confirmed metadata. Skip them entirely — do not serve them in reply to requests.

---

## Error handling

| Situation                        | Response                                                        |
|----------------------------------|-----------------------------------------------------------------|
| Band name not recognised          | "I don't know that band. Try: EBM, Rish, Bongo, DGT, DD, MR, JS, NN, Myco, CB, RickyBobbie, HammerTone, WarMachine, Biggins, or Jasmine." |
| Title requested but not found     | Pick a random song from the band and note the requested title wasn't found. |
| Catalog empty for that band       | "No songs found for [BAND] yet."                               |
| X API credentials missing         | Report that X API env vars are not configured; do not post a URL-only reply. |
| Media upload fails                | Report the error — do not silently fall back to a URL-in-body post. |
| X post fails                      | Report the error — do not silently swallow it.                  |

---

## Machine-readable references

- `references/songs-catalog.json` — full song catalog (band, title, type, tag, ca, videoUrl, filename).

---

## Full band name display map

Use these full names in captions:

| Band key    | Display name                    |
|-------------|---------------------------------|
| EBM         | Elves of Ballinmoore            |
| DD          | Digerie Dude                    |
| Myco        | Myco                            |
| MR          | Moon Rasta                      |
| JS          | Jony Sings                      |
| NN          | Natilie Nightclub               |
| CB          | CB                              |
| DGT         | Damned Good Time Orchestra      |
| Bongo       | Bongo                           |
| Rish        | Rish                            |
| RickyBobbie | Ricky Bobbie                    |
| HammerTone  | Hammer Tone                     |
| WarMachine  | War Machine                     |
| Biggins     | Biggins Mcjammin                |
| Jasmine     | Jasmine                         |
| SEAS        | Seize the Seas OST              |
