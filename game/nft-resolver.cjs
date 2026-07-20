// NFT resolver — turns "i want to play with my NFT" into a bindable (CA, tokenId).
// READ-ONLY: Blockscout + RPC lookups, no keys, no txs.
//
//   node nft-resolver.cjs --wallet 0x.. --ca 0x.. [--chain base|robinhood]
//       -> token IDs of that collection held by the wallet (+ image urls)
//   node nft-resolver.cjs --link <url>
//       -> parse a marketplace/explorer link into { ca, tokenId }
//   node nft-resolver.cjs --verify --ca 0x.. --id N --wallet 0x.. [--chain ..]
//       -> on-chain ownerOf check (the gate before binding an OWNED character)
//   node nft-resolver.cjs --starters
//       -> the starter pack: 1-of-1s ANYONE may play unowned (founder 2026-07-20:
//          prizes/stat-LPs accrue TO the NFT, so open play is safe — free players
//          grow the starter characters for whoever holds them)
'use strict';
const fs = require('fs');
const path = require('path');

const CHAINS = {
  base: { blockscout: 'https://base.blockscout.com', rpc: 'https://mainnet.base.org' },
  robinhood: { blockscout: 'https://robinhoodchain.blockscout.com', rpc: 'https://rpc.mainnet.chain.robinhood.com' },
};
const STARTERS = path.join(__dirname, 'starter-pack.json');

const args = process.argv.slice(2);
const flag = (k) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : null; };
const chain = CHAINS[(flag('--chain') || 'base').toLowerCase()];
if (!chain) { console.error('unknown chain'); process.exit(1); }

async function holdings(wallet, ca) {
  // Blockscout: all ERC-721/1155 held by the wallet, filtered to the collection
  let url = chain.blockscout + '/api/v2/addresses/' + wallet + '/nft?type=ERC-721%2CERC-1155';
  const out = [];
  for (let page = 0; page < 10; page++) {
    const r = await fetch(url, { signal: AbortSignal.timeout(20000) });
    if (!r.ok) throw new Error('blockscout ' + r.status);
    const j = await r.json();
    for (const it of (j.items || [])) {
      if ((it.token && it.token.address || '').toLowerCase() === ca.toLowerCase()) {
        out.push({ tokenId: it.id, name: it.metadata && it.metadata.name || null, image: it.image_url || (it.metadata && it.metadata.image) || null });
      }
    }
    if (!j.next_page_params) break;
    const q = new URLSearchParams(j.next_page_params).toString();
    url = chain.blockscout + '/api/v2/addresses/' + wallet + '/nft?type=ERC-721%2CERC-1155&' + q;
  }
  return out;
}

function parseLink(link) {
  // opensea:  .../assets/<chain>/<ca>/<id>     blockscout: .../token/<ca>/instance/<id>
  let m = link.match(/assets\/[a-z-]+\/(0x[0-9a-fA-F]{40})\/(\d+)/) ||
          link.match(/token\/(0x[0-9a-fA-F]{40})\/instance\/(\d+)/);
  if (m) return { ca: m[1], tokenId: m[2] };
  return null;
}

async function ownerOf(ca, id) {
  const data = '0x6352211e' + BigInt(id).toString(16).padStart(64, '0'); // ownerOf(uint256)
  const r = await fetch(chain.rpc, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'eth_call', params: [{ to: ca, data }, 'latest'] }),
    signal: AbortSignal.timeout(20000),
  });
  const j = await r.json();
  if (j.error || !j.result || j.result === '0x') throw new Error('ownerOf failed: ' + (j.error && j.error.message || 'no result'));
  return '0x' + j.result.slice(-40);
}

(async () => {
  if (args.includes('--starters')) {
    let s = []; try { s = JSON.parse(fs.readFileSync(STARTERS, 'utf8')); } catch { console.log('no starter-pack.json yet'); return; }
    for (const c of s) console.log(`${c.name}  (${c.chain})  ${c.ca}  #${c.tokenId}  — ${c.blurb || 'starter character'}`);
    return;
  }
  if (args.includes('--link')) {
    const p = parseLink(flag('--link'));
    console.log(p ? JSON.stringify(p) : 'could not parse link');
    return;
  }
  if (args.includes('--verify')) {
    const o = await ownerOf(flag('--ca'), flag('--id'));
    const w = (flag('--wallet') || '').toLowerCase();
    console.log('ownerOf #' + flag('--id') + ' = ' + o + (w ? (o.toLowerCase() === w ? '  ✅ MATCHES wallet' : '  ❌ NOT the wallet') : ''));
    return;
  }
  const wallet = flag('--wallet'), ca = flag('--ca');
  if (!wallet || !ca) { console.log('usage: --wallet 0x.. --ca 0x..  |  --link <url>  |  --verify --ca --id --wallet  |  --starters'); return; }
  const h = await holdings(wallet, ca);
  if (!h.length) { console.log('ZERO tokens of ' + ca + ' held by ' + wallet + ' — ask for a marketplace link or recheck the CA'); return; }
  console.log(h.length + ' token(s) held:');
  for (const t of h) console.log(`  #${t.tokenId}  ${t.name || ''}  ${t.image || ''}`);
  if (h.length === 1) console.log('-> exactly one: confirm and bind #' + h[0].tokenId);
})().catch(e => { console.error('ERR:', e.message); process.exit(1); });
