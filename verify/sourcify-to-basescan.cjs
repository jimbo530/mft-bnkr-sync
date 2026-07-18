// Verify a Base contract on Basescan using the EXACT stdJsonInput Sourcify already matched
// (ground truth → correct source paths → metadata hash matches → Basescan verifies).
// Usage: node sourcify-to-basescan.cjs <address> [constructorArgsHexNo0x]
const KEY = process.env.BASESCAN_API_KEY || 'A4WG6QZW3M1DUVKB2X93GJ6GNFHR3MJVMV';
const API = 'https://api.etherscan.io/v2/api';
const CHAIN = 8453;
const ADDR = (process.argv[2] || '0x3bb5f84c797e5932656ab66830bd901637dae318').toLowerCase();
const CTOR = (process.argv[3] || '').replace(/^0x/, '');
const j = async (url, opts) => (await fetch(url, opts)).json();

(async () => {
  const url = `https://sourcify.dev/server/v2/contract/${CHAIN}/${ADDR}?fields=stdJsonInput,compilation`;
  const c = await j(url);
  console.log('match:', c.match || c.runtimeMatch || '?', '| keys:', Object.keys(c).join(','));
  const comp = c.compilation || {};
  const stdJson = c.stdJsonInput;
  if (!stdJson) { console.log('no stdJsonInput:', JSON.stringify(c).slice(0, 400)); return; }
  let cname = comp.fullyQualifiedName
    || (comp.compilationTarget && `${comp.compilationTarget.path}:${comp.compilationTarget.name}`)
    || (comp.name && comp.path && `${comp.path}:${comp.name}`);
  const compilerVersion = 'v' + (comp.compilerVersion || comp.version);
  console.log('contractname:', cname, '| compiler:', compilerVersion, '| sources:', Object.keys(stdJson.sources || {}).length);
  console.log('settings:', JSON.stringify(stdJson.settings).slice(0, 260));
  if (!cname) { console.log('no contractname; compilation:', JSON.stringify(comp).slice(0, 400)); return; }

  stdJson.settings = stdJson.settings || {};
  if (!stdJson.settings.outputSelection) stdJson.settings.outputSelection = { '*': { '*': ['abi', 'evm.bytecode', 'evm.deployedBytecode'] } };

  const body = new URLSearchParams({
    chainid: String(CHAIN), module: 'contract', action: 'verifysourcecode', apikey: KEY,
    codeformat: 'solidity-standard-json-input', sourceCode: JSON.stringify(stdJson),
    contractaddress: ADDR, contractname: cname, compilerversion: compilerVersion,
    constructorArguements: CTOR,
  });
  const sub = await j(`${API}?chainid=${CHAIN}`, { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' }, body });
  console.log('submit:', JSON.stringify(sub));
  if (String(sub.result || '').toLowerCase().includes('already verified')) { console.log('✅ already verified'); return; }
  if (sub.status !== '1') return;
  const guid = sub.result;
  for (let i = 0; i < 16; i++) {
    await new Promise(s => setTimeout(s, 6000));
    const st = await j(`${API}?chainid=${CHAIN}&module=contract&action=checkverifystatus&guid=${guid}&apikey=${KEY}`);
    console.log('poll', i, ':', st.result);
    if (st.result && !/pending/i.test(st.result)) { console.log(/pass|verified/i.test(st.result) ? '✅ VERIFIED' : '⚠️ ' + st.result); break; }
  }
})().catch(e => console.error('err', e.message));
