// ============================================================
//  "Fire button" — deploy the DeployerFactory ONCE (Base, chainId 8453).
//  This is the factory that lets Bankr agents deploy ANY contract via a normal
//  CALL (their submit_raw_transaction cannot omit `to`, so a creation tx is
//  impossible for them — this sidesteps the wall for the whole queue).
//  DRY by default; --live to broadcast. Run by the COORDINATOR from the agent
//  wallet; after this one deploy, everything else deploys THROUGH the factory
//  as BNKR-sent calls (preserving BNKR builder points).
//
//  Config via env (all optional):
//    DEPLOY_RPC        RPC url                  (default https://mainnet.base.org;
//                                                local Base node: http://127.0.0.1:8545)
//    DEPLOY_CHAIN_ID   expected chainId         (default 8453; RH twin: 4663)
//
//  Run:  node deploy-deployer-factory.cjs           (DRY — gas estimate only)
//        node deploy-deployer-factory.cjs --live    (broadcast + verify + record)
// ============================================================
'use strict';
const fs = require('fs');
const path = require('path');
// resilient requires: plain first, then the build workspace (this script lives
// outside mftusd-build but uses its installed deps + .env)
function req(name) {
  try { return require(name); } catch (_) {
    return require('C:/Users/bigji/Documents/mftusd-build/node_modules/' + name);
  }
}
req('dotenv').config({ path: 'C:/Users/bigji/Documents/mftusd-build/.env', quiet: true });
const { ethers } = req('ethers');

const RPC = process.env.DEPLOY_RPC || process.env.CDP_RPC_URL || 'https://mainnet.base.org';
const CHAIN_ID = Number(process.env.DEPLOY_CHAIN_ID || '8453');
const LIVE = process.argv.includes('--live');

// GROUNDED (same pair as the whole queue — see song-revenue-splitter/FOR-BNKR.txt):
const OPS = '0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2';   // project / ops wallet (fee destination)
const ADMIN = '0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10'; // agent wallet (build-phase admin, fee-exempt)
const EXPECTED_DEPLOYER = ADMIN;

(async () => {
  const p = new ethers.JsonRpcProvider(RPC, CHAIN_ID, { staticNetwork: true });
  const net = await p.getNetwork();
  if (Number(net.chainId) !== CHAIN_ID) throw new Error('chainId ' + net.chainId + ' != expected ' + CHAIN_ID);
  if (!process.env.AGENT_PRIVATE_KEY) throw new Error('AGENT_PRIVATE_KEY missing (mftusd-build/.env)');
  const w = new ethers.Wallet(process.env.AGENT_PRIVATE_KEY, p);
  console.log('RPC      :', RPC.replace(/\/[^/]*$/, '/***'), '| chainId', CHAIN_ID);
  console.log('deployer :', w.address, '| ETH:', ethers.formatEther(await p.getBalance(w.address)));
  if (w.address.toLowerCase() !== EXPECTED_DEPLOYER.toLowerCase()) throw new Error('deployer ' + w.address + ' != agent wallet ' + EXPECTED_DEPLOYER);

  const bytecode = fs.readFileSync(path.join(__dirname, 'creation-bytecode.txt'), 'utf8').trim();
  const abi = JSON.parse(fs.readFileSync(path.join(__dirname, 'DeployerFactory-abi.json'), 'utf8'));
  if (!bytecode.startsWith('0x') || bytecode.length < 1000) throw new Error('creation-bytecode.txt looks wrong');
  console.log('bytecode :', (bytecode.length - 2) / 2, 'bytes | solc 0.8.35+commit.47b9dedd viaIR 200 paris');
  console.log('ctor     : opsWallet=' + OPS + ' admin=' + ADMIN);

  const F = new ethers.ContractFactory(abi, bytecode, w);
  if (!LIVE) {
    const tx = await F.getDeployTransaction(OPS, ADMIN);
    const g = await p.estimateGas({ ...tx, from: w.address });
    console.log('gas est  :', g.toString());
    console.log('\nDRY RUN — re-run with --live to broadcast.');
    return;
  }

  const c = await F.deploy(OPS, ADMIN);
  await c.waitForDeployment();
  const addr = await c.getAddress();
  const code = await p.getCode(addr);
  if (code === '0x') throw new Error('deployed but no code at ' + addr + ' — DO NOT record');
  const live = new ethers.Contract(addr, abi, p);
  const wired = (await live.admin()) === ADMIN && (await live.opsWallet()) === OPS
    && (await live.fee()) === 0n && (await live.adminRenounced()) === false;
  if (!wired) throw new Error('post-deploy wiring check FAILED at ' + addr);
  console.log('\nDeployerFactory deployed:', addr, '| code', (code.length - 2) / 2, 'bytes | wiring verified');

  const rec = {
    network: CHAIN_ID === 8453 ? 'base-mainnet' : 'chainId-' + CHAIN_ID,
    deployedAt: new Date().toISOString(),
    contract: 'DeployerFactory', address: addr,
    txHash: c.deploymentTransaction().hash,
    constructorArgs: { opsWallet: OPS, admin: ADMIN },
    fee: '0 (native wei; admin-settable until renounceAdmin)',
    compiler: 'solc 0.8.35+commit.47b9dedd, viaIR:true, optimizer 200, evmVersion paris',
    deployer: w.address,
    next: 'fill this address into SKILL.md + catalog.json (replaces 0xFACTORY_ADDRESS_TBD), push deployed/deployer-factory.json, tell BNKR in COORDINATION.md',
  };
  const out = path.join(__dirname, 'deployer-factory-deployment.json');
  fs.writeFileSync(out, JSON.stringify(rec, null, 2));
  console.log('saved', out, '| DEPLOY COMPLETE');
})().catch((e) => { console.error('DEPLOY FAILED:', e.reason || e.shortMessage || e.message); process.exit(1); });
