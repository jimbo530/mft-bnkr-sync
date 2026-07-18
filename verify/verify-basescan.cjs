// BNKR: verify the Base community-vault IMPLEMENTATION on Basescan.
// One impl verified → ALL clones (BlackTide, Toshi, BNKR-vault 0x3531…, +14 others) become readable.
//
// RUN:  BASESCAN_API_KEY=your_key  node verify/verify-basescan.cjs
//
// The source + settings below are PROVEN exact — Sourcify already confirms this input is a
// runtime+creation exact match for 0x3bb5f84c…. This just gives Basescan its native copy.
const fs = require('fs');
const KEY = process.env.BASESCAN_API_KEY || process.env.ETHERSCAN_API_KEY || '';
if (!KEY) { console.log('❌ set BASESCAN_API_KEY first:  BASESCAN_API_KEY=xxx node verify/verify-basescan.cjs'); process.exit(1); }

const API = 'https://api.etherscan.io/v2/api';      // Etherscan V2 unified (chainid param); V1 basescan API is dead
const CHAIN = 8453;                                  // Base
const ADDR = '0x3bb5f84c797e5932656ab66830bd901637dae318';                       // the impl clones point to
const NAME = 'project/contracts/CommunityLPVaultV3Init.sol:CommunityLPVaultV3Init'; // must match the input's source key
const COMPILER = 'v0.8.35+commit.47b9dedd';          // exact solc long version
const input = fs.readFileSync(__dirname + '/CommunityLPVaultV3Init.standard-input.json', 'utf8'); // viaIR, opt 200, paris — baked in

(async () => {
  const body = new URLSearchParams({
    chainid: String(CHAIN), module: 'contract', action: 'verifysourcecode', apikey: KEY,
    codeformat: 'solidity-standard-json-input', sourceCode: input,
    contractaddress: ADDR, contractname: NAME, compilerversion: COMPILER,
    constructorArguements: '',                        // impl uses initialize() — no constructor args
  });
  const r = await fetch(API, { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' }, body });
  const j = await r.json();
  console.log('submit:', JSON.stringify(j));
  if (String(j.result || '').toLowerCase().includes('already verified')) { console.log('✅ already verified — done'); return; }
  if (j.status !== '1') { console.log('❌ submit rejected — read the message above'); return; }
  const guid = j.result;
  for (let i = 0; i < 12; i++) {
    await new Promise(s => setTimeout(s, 5000));
    const cr = await fetch(`${API}?chainid=${CHAIN}&module=contract&action=checkverifystatus&guid=${guid}&apikey=${KEY}`);
    const cj = await cr.json();
    console.log('poll', i, ':', JSON.stringify(cj));
    if (cj.result && !/pending/i.test(cj.result)) { console.log(/pass|verified/i.test(cj.result) ? '✅ VERIFIED' : '⚠️ see result'); break; }
  }
  console.log('\nNEXT: on basescan.org for each clone (0x3531…, BlackTide, Toshi) click "Is this a proxy?" → Verify → it auto-detects impl 0x3bb5f84c… → Read/Write-as-Proxy then shows withdraw / withdrawAsToken / deposit.');
})().catch(e => console.error('err:', e.message));
