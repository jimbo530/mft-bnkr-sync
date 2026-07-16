---
name: mft-song-request
description: Serve a Meme for Trees song as an X reply. Use when a user on X asks to hear a song from one of the MfT bands — e.g. "play something from EBM", "post a Rish song", "give me a Bongo track", "got any DGT?". Look up the band in songs-catalog.json (in references/), pick a song (random or best match to any title hint the user gave), and reply to the requester's tweet with the video URL embedded and the correct caption. For band-token songs the caption MUST include the band's $TAG and CA on the same line. Never tag @bankrbot in the post. One cashtag per post only.
---

# Meme for Trees — Song Request

When a user on X asks for a song from a Meme for Trees band, Bankr:

1. Parses the band name from the request (case-insensitive, aliases accepted — see Band Name Aliases below).
2. Looks the band up in `references/songs-catalog.json`.
3. Picks a song — random by default; if the user named a title, pick the closest match.
4. Posts a reply to the requesting tweet with the video URL and the correct caption.

No wallet transactions. No approvals. X post only.

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

Build the reply caption as follows:

### Band-token songs (type = "band-token-song")

```
[Title] — [Full band name]

[videoUrl]

[tag] [ca]
```

Example for EBM "Canopy Law":
```
Canopy Law — Elves of Ballinmoore

https://tasern.quest/songs/Canopy%20Law.mp4

$EBM 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d
```

### CB band songs (tag = "$MfT", ca = null)

```
[Title] — CB

[videoUrl]

$MfT
```

### MfT-songs (type = "mft-song")

Same format as band-token-song. The band still has a tag and/or CA — include them.

### Game anthems (type = "game-anthem", tag = null)

```
[Title] — Seize the Seas OST

[videoUrl]

tasern.quest
```

### News songs (type = "news")

```
[Title] — EBM Grove Report / Base Wire

[videoUrl]

$EBM 0xF113fe2A0E1181A21fA97B1F52ff232140B7692d
```

---

## One-cashtag rule

**One cashtag per post, maximum.** Never add a second cashtag. Never tag @bankrbot.
The `tag` field in the catalog entry is the single cashtag to use. CB tracks use `$MfT`
(no CA). SEAS tracks use no cashtag at all.

---

## Video delivery

- Include `videoUrl` in the post body — X will embed the video if the integration supports direct URL embed.
- If Bankr's X integration supports file attachment: the file is at `D:\suno-pipeline\auto\output\[filename]` on the originating machine. Prefer URL embed; note attachment path as fallback only.
- Do NOT include the file path in the public post — URL only.

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
