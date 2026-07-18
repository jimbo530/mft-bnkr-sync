// Song/meme drop TRANSLATOR — translate an X request to a library entry via its DEFINED triggers,
// then print the exact drop to post (the entry's caption + its xPost link). This is a translation
// (defined trigger phrase -> item), NOT a keyword search.
//   node song-drop.cjs "show me the meme"
//
// The library is read LIVE from GitHub main on every run, so songs the auto-poster adds appear
// immediately with NO re-install. Falls back to the staged references/link-library.json only if
// the live fetch fails.
const fs = require('fs');
const path = require('path');
const LIVE_URL = 'https://raw.githubusercontent.com/jimbo530/mft-bnkr-sync/main/link-library.json';
const STAGED = path.join(__dirname, 'references', 'link-library.json');

async function loadLibrary() {
  try {
    const r = await fetch(LIVE_URL, { headers: { accept: 'application/json' } });
    if (r.ok) {
      const data = await r.json();
      if (Array.isArray(data) && data.length) return { lib: data, src: 'live' };
    }
  } catch (e) { /* fall back to staged snapshot */ }
  return { lib: JSON.parse(fs.readFileSync(STAGED, 'utf8')), src: 'staged(fallback)' };
}

(async () => {
  const { lib, src } = await loadLibrary();
  const q = (process.argv.slice(2).join(' ') || '').toLowerCase().trim();
  const listing = () => lib.map(x => '  - ' + x.name + '   → say: "' + (x.triggers ? x.triggers[0] : x.name) + '"').join('\n');

  if (!q) { console.log('usage: node song-drop.cjs "<what the user said>"\nlibrary (' + src + ', ' + lib.length + ' entries):\n' + listing()); return; }

  // TRANSLATE: find the entry whose DEFINED trigger phrase appears in the request. Longest trigger wins
  // (so "one billion strong" beats a shorter partial). No keyword scan of band/tag/random words.
  let best = null, bestLen = 0;
  for (const x of lib) {
    const triggers = (x.triggers && x.triggers.length ? x.triggers : [x.name]).map(s => String(s).toLowerCase());
    for (const t of triggers) {
      if (t && q.includes(t) && t.length > bestLen) { best = x; bestLen = t.length; }
    }
  }

  if (!best) { console.log('no library item matches "' + q + '" — nothing to translate. Available (' + src + '):\n' + listing()); process.exitCode = 1; return; }
  if (!best.xPost) { console.log('⚠️ "' + best.name + '" has no xPost link yet — post it to X first.'); process.exitCode = 1; return; }
  console.log('--- POST THIS VERBATIM --- (library: ' + src + ')');
  console.log((best.caption || best.name) + '\n\n' + best.xPost);
})();
