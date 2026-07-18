// Song/meme drop TRANSLATOR — translate an X request to a library entry via its DEFINED triggers,
// then print the exact drop to post (the entry's caption + its xPost link). This is a translation
// (defined trigger phrase -> item), NOT a keyword search.
//   node song-drop.cjs "show me the meme"
const fs = require('fs');
const path = require('path');
const LIB = path.join(__dirname, 'references', 'link-library.json');
const lib = JSON.parse(fs.readFileSync(LIB, 'utf8'));
const q = (process.argv.slice(2).join(' ') || '').toLowerCase().trim();
const listing = () => lib.map(x => '  - ' + x.name + '   → say: "' + (x.triggers ? x.triggers[0] : x.name) + '"').join('\n');

if (!q) { console.log('usage: node song-drop.cjs "<what the user said>"\nlibrary:\n' + listing()); process.exit(0); }

// TRANSLATE: find the entry whose DEFINED trigger phrase appears in the request. Longest trigger wins
// (so "one billion strong" beats a shorter partial). No keyword scan of band/tag/random words.
let best = null, bestLen = 0;
for (const x of lib) {
  const triggers = (x.triggers && x.triggers.length ? x.triggers : [x.name]).map(s => String(s).toLowerCase());
  for (const t of triggers) {
    if (t && q.includes(t) && t.length > bestLen) { best = x; bestLen = t.length; }
  }
}

if (!best) { console.log('no library item matches "' + q + '" — nothing to translate. Available:\n' + listing()); process.exit(1); }
if (!best.xPost) { console.log('⚠️ "' + best.name + '" has no xPost link yet — post it to X first.'); process.exit(1); }
console.log('--- POST THIS VERBATIM ---');
console.log((best.caption || best.name) + '\n\n' + best.xPost);
