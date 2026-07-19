/* follow-up reads to close the 3 flags: node-staleness, Money backing, EBM burn destination */
const ethers = require('ethers');
const mk = (u) => ethers.JsonRpcProvider ? new ethers.JsonRpcProvider(u) : new ethers.providers.JsonRpcProvider(u);
const LOCAL = mk('http://localhost:8545');
const PUB   = mk('https://mainnet.base.org');
const MONEY='0xe3dd3881477c20C17Df080cEec0C1bD0C065A072', aUSDC='0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB';
const EBM='0xF113fe2A0E1181A21fA97B1F52ff232140B7692d';
const Z='0x0000000000000000000000000000000000000000';
const ABI=['function totalSupply() view returns (uint256)','function balanceOf(address) view returns (uint256)',
  'function totalBacking() view returns (uint256)','function totalAssets() view returns (uint256)'];
const c=(a,p)=>new ethers.Contract(a,ABI,p);
async function t(label,fn){ try{ const v=await fn(); console.log(`✅ ${label} = ${v.toString()}`);}catch(e){ console.log(`❌ ${label} = ${(e.shortMessage||e.message||'').slice(0,70)}`);} }
(async()=>{
  console.log('local block', await LOCAL.getBlockNumber().catch(()=> 'ERR'));
  console.log('pub   block', await PUB.getBlockNumber().catch(()=> 'ERR'));
  await t('Money.totalSupply LOCAL', ()=>c(MONEY,LOCAL).totalSupply());
  await t('Money.totalSupply PUBLIC',()=>c(MONEY,PUB).totalSupply());
  await t('aUSDC.balanceOf(Money) PUBLIC',()=>c(aUSDC,PUB).balanceOf(MONEY));
  await t('Money.totalBacking()',()=>c(MONEY,PUB).totalBacking());
  await t('Money.totalAssets()',()=>c(MONEY,PUB).totalAssets());
  await t('EBM.balanceOf(0x0) LOCAL',()=>c(EBM,LOCAL).balanceOf(Z));
  await t('EBM.balanceOf(EBM self) LOCAL',()=>c(EBM,LOCAL).balanceOf(EBM));
})();
