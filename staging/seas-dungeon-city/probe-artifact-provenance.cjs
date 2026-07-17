// ============================================================
//  probe-artifact-provenance.cjs — READ-ONLY provenance check for the
//  dungeon-coin-pools + weth-court-endowments packages in this folder.
//
//  Proves: mftusd-build/PrizePool.json's creation bytecode is BYTE-IDENTICAL
//  to what the 15 live tier pools were deployed from, by comparing it against
//  the actual GOLD-Mayor deploy transaction input on-chain
//  (tx 0xcb304c44… from mftusd-build/prize-ladders-deployment.json).
//  Also checks the COPPER/SILVER/GOLD coin tokens have code, and whether a
//  ManufacturingPool compile artifact exists.
//
//  NO transactions. Run: node probe-artifact-provenance.cjs
// ============================================================
'use strict';
const fs = require('fs');
function req(name) {
  try { return require(name); } catch (_) {
    return require('C:/Users/bigji/Documents/mftusd-build/node_modules/' + name);
  }
}
const { ethers } = req('ethers');
const P = new ethers.JsonRpcProvider('http://localhost:8545', 8453, { staticNetwork: true });

const PRIZE_ARTIFACT = 'C:/Users/bigji/Documents/mftusd-build/PrizePool.json';
const GOLD_MAYOR_DEPLOY_TX = '0xcb304c444949b053c7416d682aaa66c3fb2c05d11b06ef9732401ea4c3ce31a1';

(async () => {
  // 1. artifact vs live deploy tx
  const art = JSON.parse(fs.readFileSync(PRIZE_ARTIFACT, 'utf8'));
  const bc = (typeof art.bytecode === 'string' ? art.bytecode : art.bytecode.object).replace(/^0x/, '');
  const tx = await P.getTransaction(GOLD_MAYOR_DEPLOY_TX);
  if (!tx) {
    console.log('deploy tx not found on this node — cannot verify provenance here');
  } else {
    const input = tx.data.replace(/^0x/, '');
    console.log('artifact bytecode bytes:', bc.length / 2);
    console.log('live tx input bytes    :', input.length / 2, '(bytecode + 2 ctor words = +64 bytes expected)');
    console.log('tx input STARTS WITH artifact bytecode:', input.startsWith(bc));
    const tail = input.slice(bc.length);
    console.log('ctor tail (' + tail.length / 2 + ' bytes): 0x' + tail);
  }
  // 2. coin tokens have code
  for (const [n, a] of [
    ['COPPER', '0x0197896c617f20d61E73E06eC8b2A95eef176bee'],
    ['SILVER', '0x36cF0ceDEee07b14C496f77C61d010268c31E0e9'],
    ['GOLD', '0x2065d87b3a1FACc9A4fE037D7a58bC069F597004'],
  ]) {
    const code = await P.getCode(a);
    console.log(n.padEnd(7), a, code === '0x' ? 'NO CODE' : 'code OK (' + ((code.length - 2) / 2) + ' bytes)');
  }
  // 3. ManufacturingPool artifact
  const mp = 'C:/Users/bigji/Documents/mftusd-build/ManufacturingPool.json';
  console.log('ManufacturingPool.json:', fs.existsSync(mp) ? 'EXISTS' : 'MISSING (compile-manufacturing-pool.cjs builds it)');
})().catch((e) => { console.error('PROBE FAILED:', e.message); process.exit(1); });
