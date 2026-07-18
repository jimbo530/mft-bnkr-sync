# Drop from library — title → clean X drop (NEVER a raw URL)

Turns a **name/keyword** into the ready-to-post drop: the `caption` + the `xPost` link. X auto-unfurls the link into the video/image. A bare URL looks bad — **always run this and post its output verbatim.**

## Usage
```
node skills/song-drop/song-drop.cjs "instrument from every land"
```
- **1 match** → prints `--- POST THIS VERBATIM ---` then `caption` + blank line + `xPost` link. Post exactly that.
- **multiple matches** → lists them; narrow the keyword.
- **no arg / no match** → lists the whole library.

## The library — `link-library.json` (repo root)
Each entry: `name` (title) + `xPost` (the x.com post link) + `caption` (the nice text) [+ optional `band`, `tag`, `ca`].
Add an entry only AFTER the media is posted to X (the post link is what makes the video/image render).

**Rule of thumb: match by name → post caption + xPost. Never post the bare name, never post a bare URL.**
