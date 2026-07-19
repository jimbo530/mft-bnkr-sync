/*
  verify-all-gaps.cjs — closes FEE-FLOW-MAP.md §9 gaps G1..G15 with live reads (Base + RH + Polygon).
  Reads only. RUN: NODE_PATH="C:/Users/bigji/Documents/mftusd-build/node_modules" node verify/verify-all-gaps.cjs
*/
const ethers = require('ethers');
const mk = (u) => ethers.JsonRpcProvider ? new ethers.JsonRpcProvider(u) : new ethers.providers.JsonRpcProvider(u);
const BASE = mk('http://localhost:8545');
const RH   = mk('https://rpc.mainnet.chain.robinhood.com');
const POLY = mk('https://polygon-rpc.com');

const ABI = [
  'function charityBps() view returns (uint256)','function serviceBps() view returns (uint256)','function holderBps() view returns (uint256)',
  'function charityWallet() view returns (address)','function reactor() view returns (address)','function admin() view returns (address)',
  'function LP() view returns (address)','function TOKEN() view returns (address)','function FUND() view returns (address)',
  'function balanceOf(address) view returns (uint256)','function totalSupply() view returns (uint256)',
  'function recipients(uint256) view returns (address)','function recipientCount() view returns (uint256)',
  'function opsWallet() view returns (address)','function treesWallet() view returns (address)','function memeReactor() view returns (address)',
  'function totalHarvested() view returns (uint256)',
  'function coreToken() view returns (address)','function core() view returns (address)','function burnToken() view returns (address)',
  'function outboundNonce() view returns (uint256)','function nonce() view returns (uint256)','function sentNonce() view returns (uint256)',
  'function escapeHatchRenounced() view returns (bool)','function hatchRenounced() view returns (bool)','function renounced() view returns (bool)',
];
async function R(prov, gap, addr, fn, args=[]) {
  try { const c = new ethers.Contract(addr, ABI, prov); const v = await c[fn](...args);
    console.log(`✅ [${gap}] ${fn}(${args.join(',')}) @${addr.slice(0,10)} = ${v.toString()}`); return v;
  } catch (e) { console.log(`❌ [${gap}] ${fn}(${args.join(',')}) @${addr.slice(0,10)} = ${(e.shortMessage||e.message||'').slice(0,55)}`); return null; }
}
const WETH='0x4200000000000000000000000000000000000006';
(async () => {
  console.log('### BASE (local)', await BASE.getBlockNumber().catch(()=>'ERR'));
  // G1 PRGT split
  const PRGT='0xEe6fB5f324B05efF95fD59F4574050a891e6913D';
  await R(BASE,'G1',PRGT,'charityBps'); await R(BASE,'G1',PRGT,'serviceBps'); await R(BASE,'G1',PRGT,'charityWallet'); await R(BASE,'G1',PRGT,'reactor');
  // G11 CCC-R serviceBps
  const CCCR='0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B';
  await R(BASE,'G11',CCCR,'charityBps'); await R(BASE,'G11',CCCR,'serviceBps'); await R(BASE,'G11',CCCR,'charityWallet');
  // G6 BONGO/DGT sealed admin
  await R(BASE,'G6',' 0xA607F5Ea59D61D7650644E5582e06565d4fea76E'.trim(),'admin');
  await R(BASE,'G6','0x6ab04d2d9017eEa03E43fED0f4dE5Bf6BFf7200c','admin');
  // G15 community vault LP() addresses
  for (const [s,v] of [['EBM-V','0xdd47bdDD35866735ac79f9F3F8d4f0513555Ed95'],['RISH-V','0x131bd427935980bbE43c30c3d0aF49e33c0E98E1'],['BONGO-V','0x3aF2d7CCc05FdF3bC6Be14d1F159826b0f31198f'],['DGT-V','0x43ebB722e17dBe698AA70A55Cb428b171A5da367']]) {
    await R(BASE,'G15 '+s,v,'LP'); await R(BASE,'G15 '+s,v,'TOKEN');
  }
  // G9 WETH prize pools fill state (balanceOf WETH held by each pool)
  for (const [s,p] of [['Mayor','0x0590AE358c9DdDBbe36CCf5D9F9FBe69290980f2'],['Lord','0x98750a778E8A65C5Deac9BA26ceDCf8bb8c9A66B'],['PettyKing','0x2C7737eaAa70e031EDd04d3712525368d93C0a9A'],['HighKing','0xf17792CACE3FD578a7b2d75e19afeA301f6c8D7f'],['Emperor','0x15B5F48d378D1F73fd151a6eD3B97508C818498a']]) {
    await R(BASE,'G9 '+s,WETH,'balanceOf',[p]);
  }
  // G5 Base prime coreToken (best-effort) ; G13 MRB-BASE nonce (best-effort)
  await R(BASE,'G5','0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA','coreToken');
  await R(BASE,'G5','0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA','burnToken');
  for (const fn of ['outboundNonce','nonce','sentNonce']) await R(BASE,'G13','0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb',fn);

  console.log('\n### ROBINHOOD (public)', await RH.getBlockNumber().catch(()=>'ERR'));
  const FTP='0x873739aeD7b49f005965377b5645914b1D78Ccd3', GST='0x95eD511Dbdd7b52795e1F515314bE8d888Ea4F3F';
  // G2 FTP recipients + feeding-flow characterization (charity direct)
  await R(RH,'G2/feed',FTP,'recipientCount'); await R(RH,'G2/feed',FTP,'opsWallet'); await R(RH,'G2/feed',FTP,'memeReactor'); await R(RH,'G2/feed',FTP,'totalHarvested');
  for (let i=0;i<4;i++) await R(RH,'G2',FTP,'recipients',[i]);
  // G3 GST recipients
  for (let i=0;i<4;i++) await R(RH,'G3',GST,'recipients',[i]);
  // G4 RH PRIME coreToken (best-effort)
  for (const fn of ['coreToken','core','burnToken']) await R(RH,'G4','0xd51125e200689bf07A9b36A6c12fE440bb92dd4D',fn);
  // G14 RH FRYER reactor coreToken (best-effort)
  for (const fn of ['coreToken','core','burnToken']) await R(RH,'G14','0x90125c8C3103556c3cdc2cbC9B508A84F52497fA',fn);

  console.log('\n### POLYGON (public)', await POLY.getBlockNumber().catch(()=>'ERR'));
  // G7 TasernBridge Polygon escape-hatch renounced
  for (const fn of ['escapeHatchRenounced','hatchRenounced','renounced']) await R(POLY,'G7','0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f',fn);
  console.log('\n=== done ===');
})();
