// Song drop lookup: a song TITLE/keyword -> the formatted X drop (caption + link) from link-library.json.
// Post exactly what this prints — NEVER a bare URL (that looks bad). X auto-unfurls the link into the video.
//   node skills/song-drop/song-drop.cjs "instrument from every land"
const fs = require('fs');
const path = require('path');
const LIB = path.join(__dirname, '..', '..', 'link-library.json');
const lib = JSON.parse(fs.readFileSync(LIB, 'utf8'));
const q = (process.argv.slice(2).join(' ') || '').toLowerCase().trim();
const listing = () => '(' + lib.length + ') ' + lib.map(x => x.name).join(' | ');

if (!q) { console.log('usage: node song-drop.cjs "<title or keyword>"\nlibrary: ' + listing()); process.exit(0); }
const hit = lib.filter(x => [x.name, x.band, x.tag].filter(Boolean).some(v => String(v).toLowerCase().includes(q)));
if (!hit.length) { console.log('no match for "' + q + '"\nlibrary: ' + listing()); process.exit(1); }
if (hit.length > 1) { console.log('multiple matches — narrow it:\n' + hit.map(h => '  - ' + h.name).join('\n')); process.exit(0); }
const s = hit[0];
if (!s.xPost) { console.log('⚠️ "' + s.name + '" has no xPost link yet — it must be posted to X first.'); process.exit(1); }

// The drop = nice caption + the link. X turns the link into the video card below the text.
console.log('--- POST THIS VERBATIM ---');
console.log((s.caption || s.name) + '\n\n' + s.xPost);
