// ============================================================
//  smoke-deploy-via-factory.cjs — Coordinator smoke test: deploy ONE FeeSplitter
//  THROUGH the live DeployerFactory on Base (the exact path the skill teaches),
//  then verify the wiring on-chain. DRY by default; --live to broadcast.
//
//  NOTE (BNKR points): PRODUCTION splitters should be deployed BY BNKR via the
//  calldata recipe in SKILL.md so BNKR keeps builder points. This script is for
//  ONE Coordinator smoke deploy to prove the rail end-to-end.
//
//  Default recipients = the queue's standard pair (both ours — a harmless
//  50/50 smoke splitter): ops 0x0780… / agent 0xE2a4…. Override via env.
//
//  Config via env (all optional):
//    DEPLOY_RPC        RPC url            (default https://mainnet.base.org;
//                                          local Base node: http://127.0.0.1:8545)
//    DEPLOY_CHAIN_ID   expected chainId   (default 8453)
//    RECIPIENTS        comma-separated addresses
//    SHARES_BPS        comma-separated bps (must sum to 10000)
//
//  Run:  node smoke-deploy-via-factory.cjs           (DRY — simulate + gas only)
//        node smoke-deploy-via-factory.cjs --live    (broadcast + verify + record)
// ============================================================
'use strict';
const fs = require('fs');
const path = require('path');
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

// GROUNDED: DeployerFactory live on Base — staging/bankr-deploy-skill/deployer-factory-deployment.json
const FACTORY = '0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D';
// GROUNDED default pair (same as the whole queue — see bankr-deploy-skill/FOR-COORDINATOR.txt):
const DEFAULT_RECIPIENTS = [
  '0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2', // project / ops wallet
  '0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10', // agent wallet
];
const DEFAULT_SHARES = [5000, 5000];

const FACTORY_ABI = [
  'function deploy(bytes initCode) payable returns (address)',
  'function fee() view returns (uint256)',
  'event Deployed(address indexed deployer, address indexed addr, uint256 feePaid)',
];

(async () => {
  const recipients = (process.env.RECIPIENTS || DEFAULT_RECIPIENTS.join(',')).split(',').map((s) => ethers.getAddress(s.trim()));
  const sharesBps = (process.env.SHARES_BPS || DEFAULT_SHARES.join(',')).split(',').map((s) => BigInt(s.trim()));
  if (recipients.length !== sharesBps.length) throw new Error('RECIPIENTS/SHARES_BPS length mismatch');
  if (recipients.length < 2) throw new Error('need at least 2 recipients');
  const sum = sharesBps.reduce((a, b) => a + b, 0n);
  if (sum !== 10000n) throw new Error('shares sum ' + sum + ' != 10000');

  const p = new ethers.JsonRpcProvider(RPC, CHAIN_ID, { staticNetwork: true });
  const net = await p.getNetwork();
  if (Number(net.chainId) !== CHAIN_ID) throw new Error('chainId ' + net.chainId + ' != expected ' + CHAIN_ID);
  if (!process.env.AGENT_PRIVATE_KEY) throw new Error('AGENT_PRIVATE_KEY missing (mftusd-build/.env)');
  const w = new ethers.Wallet(process.env.AGENT_PRIVATE_KEY, p);
  console.log('RPC       :', RPC.replace(/\/[^/]*$/, '/***'), '| chainId', CHAIN_ID);
  console.log('deployer  :', w.address, '| ETH:', ethers.formatEther(await p.getBalance(w.address)));
  console.log('factory   :', FACTORY);
  recipients.forEach((r, i) => console.log('recipient ' + i + ':', r, '@', sharesBps[i].toString(), 'bps'));

  const factoryCode = await p.getCode(FACTORY);
  if (factoryCode === '0x') throw new Error('NO CODE at factory ' + FACTORY + ' on chain ' + CHAIN_ID + ' — wrong chain?');

  const creation = fs.readFileSync(path.join(__dirname, 'creation-bytecode.txt'), 'utf8').trim();
  if (!creation.startsWith('0x') || creation.length < 1000) throw new Error('creation-bytecode.txt looks wrong');
  const ctorTail = ethers.AbiCoder.defaultAbiCoder().encode(['address[]', 'uint256[]'], [recipients, sharesBps]);
  const initCode = creation + ctorTail.slice(2);
  console.log('initCode  :', (initCode.length - 2) / 2, 'bytes | solc 0.8.35+commit.47b9dedd viaIR 200 paris');

  const f = new ethers.Contract(FACTORY, FACTORY_ABI, w);
  const fee = await f.fee();
  console.log('factory fee:', ethers.formatEther(fee), 'ETH (sent as tx value — ctor is NOT payable, exact only)');

  // simulate: eth_call returns the address the real tx will produce
  const predicted = await f.deploy.staticCall(initCode, { value: fee });
  const gas = await f.deploy.estimateGas(initCode, { value: fee });
  console.log('simulated :', predicted, '| gas est:', gas.toString());

  if (!LIVE) { console.log('\nDRY RUN — re-run with --live to broadcast.'); return; }

  const tx = await f.deploy(initCode, { value: fee });
  console.log('tx        :', tx.hash);
  const rc = await tx.wait();
  const ev = rc.logs
    .map((l) => { try { return f.interface.parseLog(l); } catch (_) { return null; } })
    .find((x) => x && x.name === 'Deployed');
  if (!ev) throw new Error('no Deployed event in receipt — DO NOT record');
  const addr = ev.args[1];
  if ((await p.getCode(addr)) === '0x') throw new Error('deployed but no code at ' + addr + ' — DO NOT record');

  // verify wiring exactly as encoded
  const s = new ethers.Contract(addr, [
    'function recipients() view returns (address[])',
    'function shares(address) view returns (uint256)',
    'function recipientCount() view returns (uint256)',
    'function TOTAL_BPS() view returns (uint256)',
  ], p);
  const got = await s.recipients();
  let wired = got.length === recipients.length && (await s.TOTAL_BPS()) === 10000n
    && (await s.recipientCount()) === BigInt(recipients.length);
  for (let i = 0; i < recipients.length && wired; i++) {
    wired = got[i] === recipients[i] && (await s.shares(recipients[i])) === sharesBps[i];
  }
  if (!wired) throw new Error('post-deploy wiring check FAILED at ' + addr);
  console.log('\nFeeSplitter deployed THROUGH the factory:', addr, '| wiring verified (recipients + shares exact)');

  const rec = {
    network: CHAIN_ID === 8453 ? 'base-mainnet' : 'chainId-' + CHAIN_ID,
    deployedAt: new Date().toISOString(),
    contract: 'FeeSplitter (smoke — deployed via DeployerFactory.deploy(bytes))',
    address: addr,
    factory: FACTORY,
    txHash: tx.hash,
    gasUsed: rc.gasUsed.toString(),
    constructorArgs: { recipients, sharesBps: sharesBps.map(String) },
    compiler: 'solc 0.8.35+commit.47b9dedd, viaIR:true, optimizer 200, evmVersion paris',
    deployer: w.address,
    next: 'send a dust native amount, check pending(), release() — then hand the SKILL.md calldata recipe to BNKR for production splitters (BNKR deploys = BNKR points)',
  };
  const out = path.join(__dirname, 'fee-splitter-smoke-deployment.json');
  fs.writeFileSync(out, JSON.stringify(rec, null, 2));
  console.log('saved', out, '| SMOKE DEPLOY COMPLETE');
})().catch((e) => { console.error('SMOKE DEPLOY FAILED:', e.reason || e.shortMessage || e.message); process.exit(1); });
