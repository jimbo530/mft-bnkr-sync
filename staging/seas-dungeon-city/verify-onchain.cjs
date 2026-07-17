// ============================================================
//  verify-onchain.cjs — READ-ONLY grounding for the Seas
//  DUNGEON + CITY-BUILDING inventory (staging/seas-dungeon-city).
//
//  Verifies every LIVE address claimed in INVENTORY.md:
//    - 15 PrizePool tier pools (cbBTC / GOLD / WETH): code, balance,
//      totalFunded, totalClaims, guard-ladder id 1001 + job id 101 exists
//    - StructureFactory: code, kindCount, structureCount, owner, paused
//    - CourtEndowment (Mayor sample): principal, prizePool wiring
//    - LootPoolV2 (water fight-drip): code + WATER balance
//    - DeployerFactory (the BNKR deploy target): code
//
//  NO transactions. NO state changes. Safe to re-run any time.
//  RPC: local Base node first, mainnet.base.org fallback.
//  Run:  node verify-onchain.cjs
// ============================================================
'use strict';
function req(name) {
  try { return require(name); } catch (_) {
    return require('C:/Users/bigji/Documents/mftusd-build/node_modules/' + name);
  }
}
const { ethers } = req('ethers');

const RPCS = ['http://localhost:8545', 'https://mainnet.base.org'];

// ── Addresses (provenance: deploy records read 2026-07-17, never hand-typed) ──
// mftusd-build/prize-ladders-deployment.json + bankr-impact-network.csv rows 179-193
// + _archive/prizepool-deployment.json + structure-factory-deployment.json
// + water-prize-flow-deployment.json + court-endowment-mayor-deployment.json
// + BNKR-ports/deployed/deployer-factory.json
const TOKENS = {
  cbBTC: { addr: '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf', dec: 8 },
  GOLD:  { addr: '0x2065d87b3a1FACc9A4fE037D7a58bC069F597004', dec: 18 },
  WETH:  { addr: '0x4200000000000000000000000000000000000006', dec: 18 },
  WATER: { addr: '0x9789c459f08896148E8D1a8b2B7a4Bb95FAAf8B2', dec: 6 },
};
const POOLS = [
  // line, tier, pool
  ['cbBTC', 'Mayor',     '0xB10fbbCB67d68d1f43E566089FFa0f36Bd057193'],
  ['cbBTC', 'Lord',      '0x4cC809378135F9501e37532dFDF3df6aED2B3342'],
  ['cbBTC', 'PettyKing', '0x1D6dA6b28a62A45588411eEE66C94AC951A461D2'],
  ['cbBTC', 'HighKing',  '0x2983E3d4250d01ba05013F1E9995Cd457D7aBa65'],
  ['cbBTC', 'Emperor',   '0xF3dA6a1D7d1a57F4E4782213D831646C7E45d6B0'],
  ['GOLD',  'Mayor',     '0xC76A9F461Be6253BD8676e0db41A6b2E03e318F8'],
  ['GOLD',  'Lord',      '0x684698ae06Bba12bEf5e7684d8ed466AFD841F5A'],
  ['GOLD',  'PettyKing', '0x6C3208D0a637eB2a993AA60bF9838b39D218F2e7'],
  ['GOLD',  'HighKing',  '0x784D25403f0677A4EB29dD4d8e2887c6Bf9341C3'],
  ['GOLD',  'Emperor',   '0x5DFfBF9B20b7A1d7155d54C8c750BF60d4CdE5B4'],
  ['WETH',  'Mayor',     '0x0590AE358c9DdDBbe36CCf5D9F9FBe69290980f2'],
  ['WETH',  'Lord',      '0x98750a778E8A65C5Deac9BA26ceDCf8bb8c9A66B'],
  ['WETH',  'PettyKing', '0x2C7737eaAa70e031EDd04d3712525368d93C0a9A'],
  ['WETH',  'HighKing',  '0xf17792CACE3FD578a7b2d75e19afeA301f6c8D7f'],
  ['WETH',  'Emperor',   '0x15B5F48d378D1F73fd151a6eD3B97508C818498a'],
];
const STRUCTURE_FACTORY = '0x98D4306095f67035780DafB7D5897B4fE04EA647';
const COURT_ENDOWMENT_MAYOR = '0x0212F678690eFBe3C2F92c7F57FC0db3F9cf5820';
const LOOTPOOL_V2 = '0x8Cee28FB4F6b839138972D3FEab4D3e53fF7f8c7';
const DEPLOYER_FACTORY = '0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D';
const COPPER_WAGE_WATER = '0x0749c5107091F153a9f3950FC63d5B96Df04528B';
const GOLD_WATER = '0x24eb9Cf77d920207CC07584B5CD9BFB0F5a0F7C7';

const ERC20_ABI = ['function balanceOf(address) view returns (uint256)'];
const POOL_ABI = [
  'function totalFunded() view returns (uint256)',
  'function totalClaims() view returns (uint256)',
  'function achievements(uint256) view returns (bool exists, bool active, uint8 rewardType, uint256 amountOrBps, uint8 eligMode, bool oneTimePerNFT, uint8 tierTag, address condition, uint256 threshold)',
];
const SF_ABI = [
  'function kindCount() view returns (uint256)',
  'function structureCount() view returns (uint256)',
  'function owner() view returns (address)',
  'function gameWallet() view returns (address)',
  'function paused() view returns (bool)',
];
const CE_ABI = [
  'function principal() view returns (uint256)',
  'function prizePool() view returns (address)',
  'function totalCbBtcToPool() view returns (uint256)',
];

async function pickProvider() {
  for (const url of RPCS) {
    try {
      const p = new ethers.JsonRpcProvider(url, 8453, { staticNetwork: true });
      const bn = await p.getBlockNumber();
      console.log(`RPC: ${url}  (block ${bn})`);
      return p;
    } catch (e) {
      console.log(`RPC ${url} unavailable: ${e.code || e.message.slice(0, 60)}`);
    }
  }
  throw new Error('no RPC reachable — start the local Base node or check network');
}

(async () => {
  const provider = await pickProvider();

  // ── DeployerFactory (the BNKR deploy target) ──
  // NOTE: deployed 2026-07-17 — a lagging local node can show MISSING. Fall through to the
  // public RPC before concluding anything (grounded 2026-07-17: local lagged 3.1h, factory
  // verified 2475 bytes via mainnet.base.org).
  let dfCode = await provider.getCode(DEPLOYER_FACTORY);
  let dfVia = 'primary RPC';
  if (dfCode === '0x') {
    const fallback = new ethers.JsonRpcProvider(RPCS[1], 8453, { staticNetwork: true });
    dfCode = await fallback.getCode(DEPLOYER_FACTORY);
    dfVia = RPCS[1] + ' (primary showed no code — check node sync lag)';
  }
  console.log(`\nDeployerFactory ${DEPLOYER_FACTORY}: code=${dfCode.length > 2 ? 'YES (' + ((dfCode.length - 2) / 2) + ' bytes)' : 'MISSING'} via ${dfVia}`);

  // ── 15 tier PrizePools ──
  console.log('\n── PrizePool tier ladders (15) ──');
  console.log('line  tier       pool                                        balance          totalFunded      claims  ach101  ach1001');
  for (const [line, tier, pool] of POOLS) {
    const code = await provider.getCode(pool);
    if (code === '0x') { console.log(`${line.padEnd(5)} ${tier.padEnd(10)} ${pool}  NO CODE — NOT A CONTRACT`); continue; }
    const t = TOKENS[line];
    const erc = new ethers.Contract(t.addr, ERC20_ABI, provider);
    const pp = new ethers.Contract(pool, POOL_ABI, provider);
    const [bal, funded, claims, a101, a1001] = await Promise.all([
      erc.balanceOf(pool), pp.totalFunded(), pp.totalClaims(),
      pp.achievements(101), pp.achievements(1001),
    ]);
    console.log(
      `${line.padEnd(5)} ${tier.padEnd(10)} ${pool}  ` +
      `${ethers.formatUnits(bal, t.dec).padEnd(16)} ${ethers.formatUnits(funded, t.dec).padEnd(16)} ` +
      `${String(claims).padEnd(7)} ${String(a101[0]).padEnd(7)} ${String(a1001[0])}`
    );
  }

  // ── StructureFactory ──
  console.log('\n── StructureFactory (city-building keystone) ──');
  const sfCode = await provider.getCode(STRUCTURE_FACTORY);
  if (sfCode === '0x') {
    console.log(`${STRUCTURE_FACTORY}: NO CODE`);
  } else {
    const sf = new ethers.Contract(STRUCTURE_FACTORY, SF_ABI, provider);
    const [kinds, structs, owner, gw, paused] = await Promise.all([
      sf.kindCount(), sf.structureCount(), sf.owner(), sf.gameWallet(), sf.paused(),
    ]);
    console.log(`${STRUCTURE_FACTORY}  code=YES`);
    console.log(`  kindCount=${kinds}  structureCount=${structs}  paused=${paused}`);
    console.log(`  owner=${owner}  gameWallet=${gw}`);
  }

  // ── CourtEndowment (Mayor sample — the cbBTC filler) ──
  console.log('\n── CourtEndowment Mayor (cbBTC filler sample) ──');
  const ceCode = await provider.getCode(COURT_ENDOWMENT_MAYOR);
  if (ceCode === '0x') {
    console.log(`${COURT_ENDOWMENT_MAYOR}: NO CODE`);
  } else {
    const ce = new ethers.Contract(COURT_ENDOWMENT_MAYOR, CE_ABI, provider);
    const [principal, pp, sent] = await Promise.all([ce.principal(), ce.prizePool(), ce.totalCbBtcToPool()]);
    console.log(`${COURT_ENDOWMENT_MAYOR}  code=YES`);
    console.log(`  principal=${ethers.formatUnits(principal, 6)} USDC  prizePool=${pp}  totalCbBtcToPool=${ethers.formatUnits(sent, 8)}`);
  }

  // ── LootPoolV2 (the fight/dungeon WATER drip) ──
  console.log('\n── LootPoolV2 (water fight-drip pool) ──');
  const lpCode = await provider.getCode(LOOTPOOL_V2);
  const water = new ethers.Contract(TOKENS.WATER.addr, ERC20_ABI, provider);
  const lpBal = lpCode === '0x' ? 0n : await water.balanceOf(LOOTPOOL_V2);
  console.log(`${LOOTPOOL_V2}  code=${lpCode === '0x' ? 'MISSING' : 'YES'}  WATER balance=${ethers.formatUnits(lpBal, 6)}`);

  // ── Shared waters the city-building kinds point at ──
  console.log('\n── Shared coin-waters (treasury/wage vaults in structure-kinds.js) ──');
  for (const [label, addr] of [['COPPER wage-water', COPPER_WAGE_WATER], ['GOLD water', GOLD_WATER]]) {
    const c = await provider.getCode(addr);
    console.log(`${label.padEnd(18)} ${addr}  code=${c === '0x' ? 'MISSING' : 'YES'}`);
  }

  console.log('\nDone — read-only, no transactions sent.');
})().catch((e) => { console.error('VERIFY FAILED:', e.message); process.exit(1); });
