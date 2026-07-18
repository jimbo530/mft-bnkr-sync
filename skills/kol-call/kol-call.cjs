#!/usr/bin/env node
// kol-call.cjs — CHAIN-VERIFIED KOL CALL engine
// Given a Base token contract address, pull the on-chain truth (contract-verified? liquidity?
// price? 24h volume/change?) and print a clean "chain-verified call" to post.
// Facts only — NO price predictions, NO "buy". The verification IS the product.
//
// Public data sources (no wallet, read-only):
//   - Dexscreener (keyless)                       -> price, liquidity, 24h volume/change, name/symbol
//   - Basescan / Etherscan V2 (env BASESCAN_API_KEY, chainid=8453) -> contract-verified
//   - Sourcify (keyless fallback if no basescan key)               -> contract-verified
//
// Usage:  node kol-call.cjs 0x<tokenCA>
//   (set BASESCAN_API_KEY in the env for the strongest "verified" signal; otherwise falls back to sourcify)

const CA = (process.argv[2] || '').trim();
if (!/^0x[0-9a-fA-F]{40}$/.test(CA)) {
  console.error('usage: node kol-call.cjs 0x<tokenCA>   (a Base token contract address)');
  process.exit(1);
}
const BASESCAN_KEY = process.env.BASESCAN_API_KEY || '';

async function getJson(url) {
  const r = await fetch(url, { headers: { accept: 'application/json' } });
  if (!r.ok) throw new Error(url.split('?')[0] + ' -> HTTP ' + r.status);
  return r.json();
}

// contract-verified? basescan first (if key), else sourcify. Conservative: only claim verified when confirmed.
async function getVerified(ca) {
  if (BASESCAN_KEY) {
    try {
      const j = await getJson(`https://api.etherscan.io/v2/api?chainid=8453&module=contract&action=getsourcecode&address=${ca}&apikey=${BASESCAN_KEY}`);
      const it = j.result && j.result[0];
      if (it && typeof it.SourceCode === 'string' && it.SourceCode.length > 0) {
        return { verified: true, via: 'basescan', name: it.ContractName || '' };
      }
      return { verified: false, via: 'basescan', name: (it && it.ContractName) || '' };
    } catch (e) { /* fall through to sourcify */ }
  }
  try {
    const j = await getJson(`https://sourcify.dev/server/check-all-by-addresses?addresses=${ca}&chainIds=8453`);
    const it = Array.isArray(j) ? j[0] : null;
    const hit = it && ((Array.isArray(it.chainIds) && it.chainIds.length > 0) || (it.status && it.status !== 'false'));
    return { verified: !!hit, via: 'sourcify', name: '' };
  } catch (e) {
    return { verified: false, via: 'unknown', name: '' };
  }
}

// biggest Base pool by USD liquidity
async function getMarket(ca) {
  const j = await getJson(`https://api.dexscreener.com/latest/dex/tokens/${ca}`);
  const pairs = (j && j.pairs) || [];
  const base = pairs.filter(p => (p.chainId || '').toLowerCase() === 'base');
  const use = (base.length ? base : pairs).sort((a, b) => (b.liquidity?.usd || 0) - (a.liquidity?.usd || 0))[0];
  if (!use) return null;
  return {
    name: use.baseToken?.name || '',
    symbol: (use.baseToken?.symbol || '').replace(/^\$/, ''),
    priceUsd: use.priceUsd != null ? Number(use.priceUsd) : null,
    liqUsd: use.liquidity?.usd || 0,
    vol24: use.volume?.h24 || 0,
    change24: use.priceChange?.h24 != null ? Number(use.priceChange.h24) : null,
    dex: use.dexId || '',
  };
}

function money(n) {
  if (!n) return '$0';
  if (n >= 1e6) return '$' + (n / 1e6).toFixed(2) + 'M';
  if (n >= 1e3) return '$' + (n / 1e3).toFixed(1) + 'K';
  return '$' + Math.round(n);
}
function price(n) {
  if (n == null) return 'n/a';
  if (n >= 1) return '$' + n.toLocaleString('en-US', { maximumFractionDigits: 2 });
  if (n >= 0.0001) return '$' + n.toFixed(6);
  return '$' + n.toExponential(2);
}

(async () => {
  const [v, m] = await Promise.all([getVerified(CA), getMarket(CA)]);
  if (!m) {
    console.log('SKIP: no DEX pool found for ' + CA + ' — nothing to verify (no liquidity). Do not post a call.');
    process.exit(2);
  }
  const sym = m.symbol ? ('$' + m.symbol) : '(token)';
  const vline = v.verified ? '✅ contract verified on-chain' : '⚠️ contract NOT verified on-chain';
  const chg = m.change24 == null ? '' : ` (${m.change24 >= 0 ? '+' : ''}${m.change24.toFixed(1)}% 24h)`;
  const thin = m.liqUsd < 1000;

  const post = [
    `🔗 CHAIN-VERIFIED CALL — ${sym}`,
    ``,
    vline,
    `Liquidity: ${money(m.liqUsd)}`,
    `Price: ${price(m.priceUsd)}${chg}`,
    `24h volume: ${money(m.vol24)}`,
    ``,
    `${sym} ${CA}`,
    ``,
    `verified on-chain — data, not hype`,
  ].join('\n');

  console.log('--- POST THIS ---');
  console.log(post);
  console.log('--- META (for the agent, do NOT post) ---');
  console.log(JSON.stringify({
    ca: CA, verified: v.verified, verifiedVia: v.via,
    name: m.name, symbol: m.symbol, priceUsd: m.priceUsd,
    liquidityUsd: m.liqUsd, volume24Usd: m.vol24, change24Pct: m.change24,
    dex: m.dex, thinLiquidity: thin,
    warn: thin ? 'LOW LIQUIDITY (<$1k) — consider NOT posting a call' : null,
  }, null, 2));
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
