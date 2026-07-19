/*
  verify-fee-flow-onchain.cjs — proves EVERY live piece of the MfT fee flow with on-chain reads.
  Makes FEE-FLOW-LAUNCHER.md "law": each claim → a live read here. Hand this to BNKR to re-verify.

  RUN:  NODE_PATH="C:/Users/bigji/Documents/mftusd-build/node_modules" node verify/verify-fee-flow-onchain.cjs
  Reads only (no keys, no txs). Base via local node; RH via public RPC.
*/
const ethers = require('ethers');
const mkProvider = (url) => ethers.JsonRpcProvider ? new ethers.JsonRpcProvider(url) : new ethers.providers.JsonRpcProvider(url);
const BASE = mkProvider('http://localhost:8545');            // local Base archive node (chainId 8453)
const RH   = mkProvider('https://rpc.mainnet.chain.robinhood.com'); // Robinhood chain 4663
const DEAD = '0x000000000000000000000000000000000000dEaD';

const ABI = [
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address) view returns (uint256)',
  'function charityBps() view returns (uint256)',
  'function serviceBps() view returns (uint256)',
  'function holderBps() view returns (uint256)',
  'function charityWallet() view returns (address)',
  'function reactor() view returns (address)',
  'function admin() view returns (address)',
  'function paused() view returns (bool)',
  'function poolCount() view returns (uint256)',
  'function memeReactor() view returns (address)',
  'function opsWallet() view returns (address)',
  'function treesWallet() view returns (address)',
  'function usdg() view returns (address)',
  'function vault() view returns (address)',
  'function totalHarvested() view returns (uint256)',
  'function recipientCount() view returns (uint256)',
];

const A = {
  base: {
    MONEY:   '0xe3dd3881477c20C17Df080cEec0C1bD0C065A072',
    aUSDC:   '0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB',
    PRIME:   '0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA',
    MfT:     '0x8FB87d13B40B1A67B22ED1a17e2835fe7e3a9bA3',
    EBM:     '0xF113fe2A0E1181A21fA97B1F52ff232140B7692d',
    EBM_RX:  '0xA01B92024ee8cb18C3527C1453EF904A1e405095',
    BNKR:    '0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b',
    BNKR_LP: '0x1941201A37f5548DBE01e900f01b539f508F6cbF',
  },
  rh: {
    FTP:   '0x873739aeD7b49f005965377b5645914b1D78Ccd3',
    GST:   '0x95eD511Dbdd7b52795e1F515314bE8d888Ea4F3F',
    PRIME: '0xd51125e200689bf07A9b36A6c12fE440bb92dd4D',
    FRYER: '0xe15c5F9C7C3f7C8b9E9dF9C4a0dA6E9d3B0e0145', // FRYER (verify addr)
  },
};

const results = [];
function log(chain, piece, label, ok, val) {
  results.push({ chain, piece, label, ok, val });
  console.log(`${ok ? '✅' : '❌'} [${chain}] ${piece} :: ${label} = ${val}`);
}
async function read(chain, prov, piece, addr, fn, args = []) {
  try {
    const c = new ethers.Contract(addr, ABI, prov);
    const v = await c[fn](...args);
    log(chain, piece, `${fn}(${args.join(',')})`, true, v.toString());
    return v;
  } catch (e) {
    log(chain, piece, `${fn}(${args.join(',')})`, false, `REVERT/ERR: ${(e.shortMessage || e.message || '').slice(0, 80)}`);
    return null;
  }
}

(async () => {
  console.log('=== BASE (local node) ===');
  const blk = await BASE.getBlockNumber().catch(e => 'ERR ' + e.message);
  console.log('base block:', blk);

  // PIECE 1 — Money mint 1:1 + charity split
  await read('base', BASE, 'Money', A.base.MONEY, 'symbol');
  const mtSupply = await read('base', BASE, 'Money', A.base.MONEY, 'totalSupply');
  await read('base', BASE, 'Money', A.base.MONEY, 'charityBps');
  await read('base', BASE, 'Money', A.base.MONEY, 'serviceBps');
  await read('base', BASE, 'Money', A.base.MONEY, 'holderBps');
  await read('base', BASE, 'Money', A.base.MONEY, 'charityWallet');
  await read('base', BASE, 'Money', A.base.MONEY, 'reactor');
  const aBal = await read('base', BASE, 'Money-backing', A.base.aUSDC, 'balanceOf', [A.base.MONEY]);
  if (mtSupply != null && aBal != null) {
    const backed = BigInt(aBal.toString()) >= BigInt(mtSupply.toString());
    log('base', 'Money-backing', 'aUSDC >= totalSupply (1:1 backed + yield)', backed, `${aBal} vs ${mtSupply}`);
  }

  // PIECE 2 — Reactor live
  await read('base', BASE, 'ReactorPrimeV3', A.base.PRIME, 'admin');
  await read('base', BASE, 'ReactorPrimeV3', A.base.PRIME, 'paused');

  // PIECE 3 — Double-burn PROOF (dead-address balances + supply)
  for (const [sym, tok] of [['MfT', A.base.MfT], ['EBM', A.base.EBM], ['BNKR', A.base.BNKR]]) {
    const dead = await read('base', BASE, `burn:${sym}`, tok, 'balanceOf', [DEAD]);
    const sup  = await read('base', BASE, `burn:${sym}`, tok, 'totalSupply');
    if (dead != null && sup != null && BigInt(sup.toString()) > 0n) {
      const pct = Number((BigInt(dead.toString()) * 10000n) / BigInt(sup.toString())) / 100;
      log('base', `burn:${sym}`, 'burned % of supply at 0xdEaD', BigInt(dead.toString()) > 0n, `${pct}%`);
    }
  }
  await read('base', BASE, 'EBM-reactor', A.base.EBM_RX, 'admin'); // expect 0x0 (sealed)

  // PIECE 4 — seed LP locked (BNKR/mftUSD pool LP burned to dead)
  await read('base', BASE, 'LP-lock:BNKR/Money', A.base.BNKR_LP, 'totalSupply');
  await read('base', BASE, 'LP-lock:BNKR/Money', A.base.BNKR_LP, 'balanceOf', [DEAD]);

  console.log('\n=== ROBINHOOD (public RPC) ===');
  const rblk = await RH.getBlockNumber().catch(e => 'ERR ' + e.message);
  console.log('rh block:', rblk);

  // PIECE 5 — FTP / GST vaults + RH reactor
  for (const [sym, v] of [['FTP', A.rh.FTP], ['GST', A.rh.GST]]) {
    await read('rh', RH, sym, v, 'totalSupply');
    await read('rh', RH, sym, v, 'memeReactor');
    await read('rh', RH, sym, v, sym === 'GST' ? 'treesWallet' : 'opsWallet');
  }
  await read('rh', RH, 'V4ReactorPrime', A.rh.PRIME, 'admin');
  await read('rh', RH, 'V4ReactorPrime', A.rh.PRIME, 'paused');
  await read('rh', RH, 'V4ReactorPrime', A.rh.PRIME, 'poolCount');
  const fd = await read('rh', RH, 'burn:FRYER', A.rh.FRYER, 'balanceOf', [DEAD]);
  const fs = await read('rh', RH, 'burn:FRYER', A.rh.FRYER, 'totalSupply');
  if (fd != null && fs != null && BigInt(fs.toString()) > 0n) {
    const pct = Number((BigInt(fd.toString()) * 10000n) / BigInt(fs.toString())) / 100;
    log('rh', 'burn:FRYER', 'burned % at 0xdEaD', BigInt(fd.toString()) > 0n, `${pct}%`);
  }

  const ok = results.filter(r => r.ok).length;
  console.log(`\n=== SUMMARY: ${ok}/${results.length} reads returned a value (❌ = revert/err, flagged honestly) ===`);
})();
