// ============================================================
//  build-packages.cjs — builds the deploy-ready sub-packages of
//  staging/seas-dungeon-city from the PROVEN mftusd-build artifacts.
//
//  Packages built (all deploy via DeployerFactory 0xCF4357aF… deploy(bytes)):
//    dungeon-coin-pools/     3× PrizePool  (COPPER / SILVER / GOLD dungeon prize pools)
//    weth-court-endowments/  5× CourtEndowment (WETH line — "the same taxing system")
//    manufacturing-pool/     1× ManufacturingPool package (HOLD — founder-go pending;
//                            per-instance ctor args, so recipe only, no fixed calldata)
//
//  Provenance (grounded 2026-07-17, see probe-artifact-provenance.cjs output):
//    * PrizePool.json bytecode == the exact creation bytes of the 15 LIVE tier pools
//      (live GOLD-Mayor deploy tx input starts with it, ctor tail = (GOLD, admin)).
//    * CourtEndowment.json == the artifact deploy-court-endowment.cjs deployed the 5
//      live cbBTC endowments from (all 5 verified with code + correct wiring today).
//    * ManufacturingPool.json == compile-manufacturing-pool.cjs output, fork-verified
//      (fork-test-manufacturing-pool.cjs), NEVER deployed.
//
//  This script only WRITES FILES locally. No chain access, no transactions.
//  Deterministic — safe to re-run. Run: node build-packages.cjs
// ============================================================
'use strict';
const fs = require('fs');
const path = require('path');
function req(name) {
  try { return require(name); } catch (_) {
    return require('C:/Users/bigji/Documents/mftusd-build/node_modules/' + name);
  }
}
const { ethers } = req('ethers');

const SRC = 'C:/Users/bigji/Documents/mftusd-build/';
const HERE = __dirname;
const FACTORY = '0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D'; // DeployerFactory, Base 8453 (deployed/deployer-factory.json)
const FACTORY_ABI = JSON.parse(fs.readFileSync(path.join(HERE, '..', 'bankr-deploy-skill', 'DeployerFactory-abi.json'), 'utf8'));
const factoryIface = new ethers.Interface(FACTORY_ABI);

const ADMIN = '0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10'; // agent/treasury — same admin as the 15 live pools

function loadArtifact(file) {
  const a = JSON.parse(fs.readFileSync(SRC + file, 'utf8'));
  const bytecode = (typeof a.bytecode === 'string' ? a.bytecode : a.bytecode.object).replace(/^0x/, '');
  return { abi: a.abi, bytecode };
}

function writePackageBase(dir, solFile, artifact, contractName) {
  fs.mkdirSync(dir, { recursive: true });
  fs.copyFileSync(SRC + solFile, path.join(dir, solFile));
  fs.writeFileSync(path.join(dir, contractName + '-abi.json'), JSON.stringify(artifact.abi, null, 2));
  fs.writeFileSync(path.join(dir, 'creation-bytecode.txt'), '0x' + artifact.bytecode);
}

function writeDeployFile(dir, name, label, artifact, ctorTypes, ctorValues) {
  const coder = ethers.AbiCoder.defaultAbiCoder();
  const tail = coder.encode(ctorTypes, ctorValues);
  const initCode = '0x' + artifact.bytecode + tail.slice(2);
  const calldata = factoryIface.encodeFunctionData('deploy', [initCode]);
  const body = [
    '# ' + label,
    '# constructor(' + ctorTypes.join(', ') + ')',
    '# values: ' + ctorValues.map(String).join(' | '),
    '',
    '## ABI-encoded constructor tail (' + ((tail.length - 2) / 2) + ' bytes)',
    tail,
    '',
    '## initCode = creation bytecode ++ constructor tail (' + ((initCode.length - 2) / 2) + ' bytes)',
    initCode,
    '## keccak256(initCode)',
    ethers.keccak256(initCode),
    '',
    '## FULL deploy(bytes) calldata — send as the tx `data`, to = ' + FACTORY + ' (DeployerFactory, Base 8453), value = 0',
    calldata,
    '',
  ].join('\n');
  fs.writeFileSync(path.join(dir, name), body);
  console.log('  wrote', name, '(initCode', (initCode.length - 2) / 2, 'bytes, calldata', (calldata.length - 2) / 2, 'bytes)');
}

// ════════════════ 1. dungeon-coin-pools — 3× PrizePool ════════════════
{
  const dir = path.join(HERE, 'dungeon-coin-pools');
  const art = loadArtifact('PrizePool.json');
  writePackageBase(dir, 'PrizePool.sol', art, 'PrizePool');
  console.log('dungeon-coin-pools: PrizePool bytecode', art.bytecode.length / 2, 'bytes');
  // Coin addresses: game/seas/monster-achievements.js COIN_TOKENS (provenance: water-tokens.csv +
  // deploy/coins-deployed.json), all three verified with code on-chain 2026-07-17.
  const COINS = {
    copper: '0x0197896c617f20d61E73E06eC8b2A95eef176bee',
    silver: '0x36cF0ceDEee07b14C496f77C61d010268c31E0e9',
    gold: '0x2065d87b3a1FACc9A4fE037D7a58bC069F597004',
  };
  for (const [coin, addr] of Object.entries(COINS)) {
    writeDeployFile(dir, 'deploy-calldata-' + coin + '.txt',
      'Dungeon prize pool — ' + coin.toUpperCase() + ' (PrizePool instance, prize token = ' + coin.toUpperCase() + ')',
      art, ['address', 'address'], [addr, ADMIN]);
  }
}

// ════════════════ 2. weth-court-endowments — 5× CourtEndowment ════════════════
{
  const dir = path.join(HERE, 'weth-court-endowments');
  const art = loadArtifact('CourtEndowment.json');
  writePackageBase(dir, 'CourtEndowment.sol', art, 'CourtEndowment');
  console.log('weth-court-endowments: CourtEndowment bytecode', art.bytecode.length / 2, 'bytes');
  // Infra: identical to the 5 LIVE cbBTC endowments (court-endowment-*-deployment.json),
  // except the buy token = WETH and the swap pool fee = 500 (USDC/WETH 0.05% V3 pool
  // 0xd0b53D9277642d899DF5C87A3966A349A798F224 — grounded via factory.getPool + liquidity read 2026-07-17).
  const USDC = '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913';
  const AAVE_POOL = '0xA238Dd80C259a72e81d7e4664a9801593F98d1c5';
  const AUSDC = '0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB';
  const WETH = '0x4200000000000000000000000000000000000006';
  const ROUTER = '0x2626664c2603336E57B271c5C0b26F421741e481';
  const POOL_FEE = 500;
  const KEEPERS = [
    '0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10',
    '0x4ce0cd77055bA868f3C6328607D45ce37443d97c',
    '0xb4D045c656a303fa6452C43EefAEB7D8B40917CC',
  ];
  // WETH tier PrizePools (prize-ladders-deployment.json, all 5 verified live today) —
  // wired AT CONSTRUCTION so no setPrizePool follow-up exists.
  const WETH_POOLS = {
    Mayor: '0x0590AE358c9DdDBbe36CCf5D9F9FBe69290980f2',
    Lord: '0x98750a778E8A65C5Deac9BA26ceDCf8bb8c9A66B',
    PettyKing: '0x2C7737eaAa70e031EDd04d3712525368d93C0a9A',
    HighKing: '0xf17792CACE3FD578a7b2d75e19afeA301f6c8D7f',
    Emperor: '0x15B5F48d378D1F73fd151a6eD3B97508C818498a',
  };
  const TYPES = ['string', 'address', 'address', 'address', 'address', 'address', 'uint24', 'address', 'address', 'address', 'address', 'address'];
  for (const [tier, pool] of Object.entries(WETH_POOLS)) {
    writeDeployFile(dir, 'deploy-calldata-' + tier.toLowerCase() + '.txt',
      'WETH CourtEndowment — ' + tier + ' (yield buys WETH, 100% to the ' + tier + ' WETH PrizePool ' + pool + ')',
      art, TYPES, [tier, USDC, AAVE_POOL, AUSDC, WETH, ROUTER, POOL_FEE, pool, ADMIN, KEEPERS[0], KEEPERS[1], KEEPERS[2]]);
  }
}

// ════════════════ 3. manufacturing-pool — HOLD package (recipe only) ════════════════
{
  const dir = path.join(HERE, 'manufacturing-pool');
  const art = loadArtifact('ManufacturingPool.json');
  writePackageBase(dir, 'ManufacturingPool.sol', art, 'ManufacturingPool');
  console.log('manufacturing-pool: ManufacturingPool bytecode', art.bytecode.length / 2, 'bytes (HOLD — no fixed calldata; per-instance ctor)');
}

console.log('\nAll packages written. FOR-BNKR.txt files are authored separately (human-written recipes).');
