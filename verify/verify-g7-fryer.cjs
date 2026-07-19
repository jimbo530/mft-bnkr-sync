/* close G7 (Polygon bridge escape hatch, working RPC) + verify FRYER burn (now that coreToken gave us the real addr) */
const ethers = require('ethers');
const mk = (u) => ethers.JsonRpcProvider ? new ethers.JsonRpcProvider(u) : new ethers.providers.JsonRpcProvider(u);
const RH   = mk('https://rpc.mainnet.chain.robinhood.com');
const POLYS = ['https://polygon-bor-rpc.publicnode.com','https://polygon.llamarpc.com','https://1rpc.io/matic'];
const DEAD='0x000000000000000000000000000000000000dEaD';
const ABI=['function escapeHatchRenounced() view returns (bool)','function hatchRenounced() view returns (bool)','function renounced() view returns (bool)',
  'function balanceOf(address) view returns (uint256)','function totalSupply() view returns (uint256)'];
async function R(prov,label,addr,fn,args=[]){ try{const v=await new ethers.Contract(addr,ABI,prov)[fn](...args);console.log(`✅ ${label} ${fn} = ${v.toString()}`);return v;}catch(e){console.log(`❌ ${label} ${fn} = ${(e.shortMessage||e.message||'').slice(0,50)}`);return null;} }
(async()=>{
  // FRYER burn (RH) — FRYER = coreToken of the Fryer reactor, read on-chain this session
  const FRYER='0xe15c7F62bA1ee9A79C5312F04EC850F264720145';
  const fd=await R(RH,'FRYER',FRYER,'balanceOf',[DEAD]); const fs=await R(RH,'FRYER',FRYER,'totalSupply');
  if(fd&&fs&&BigInt(fs.toString())>0n){const pct=Number((BigInt(fd.toString())*10000n)/BigInt(fs.toString()))/100;console.log(`   FRYER burned at dead = ${pct}% of supply`);}
  // G7 Polygon bridge — try each RPC until one answers
  const BR='0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f';
  for(const u of POLYS){ try{ const p=mk(u); const bn=await p.getBlockNumber(); console.log(`\n-- polygon via ${u} block ${bn} --`);
    await R(p,'G7',BR,'escapeHatchRenounced'); await R(p,'G7',BR,'hatchRenounced'); await R(p,'G7',BR,'renounced'); break;
  }catch(e){ console.log(`polygon RPC ${u} failed: ${(e.shortMessage||e.message||'').slice(0,40)}`);} }
  console.log('done'); process.exit(0);
})();
