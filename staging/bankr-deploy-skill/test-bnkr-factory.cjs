// ============================================================
//  test-bnkr-factory.cjs — local-EVM proof of DeployerFactory (the "deploy ANY
//  contract via a CALL" factory for agents that cannot send creation txs).
//
//  Proof list:
//   1. factory wiring: admin / opsWallet / fee=0 / not renounced
//   2. ABI: mutating fns == exactly {deploy, deployDeterministic, setFee,
//      setOpsWallet, withdrawStuck, renounceAdmin} — no hidden lever
//   3. CREATE: deploy Hello(42) through the factory; Deployed event addr ==
//      staticCall-simulated addr; code on chain; constructor arg respected
//   4. CREATE2: computeAddress prediction == actual; duplicate salt REVERTS
//   5. fee rail: setFee gated to admin; underpay REVERTS; payer's fee lands on
//      the ops wallet EXACTLY; admin is fee-EXEMPT (feePaid=0, ops unchanged)
//   6. endowment: msg.value above the fee funds a payable constructor;
//      a NON-payable constructor + excess value REVERTS loudly
//   7. stuck funds: selfdestruct-forced ETH recoverable via withdrawStuck
//      (admin-only) BEFORE renounce
//   8. renounceAdmin: one-way; locks setFee + setOpsWallet + withdrawStuck
//      forever; deploys stay permissionless; admin exemption persists
//   9. no receive(): plain ETH transfer to the factory REVERTS
//
//  RUN:  npx hardhat node --port 8595   (plain local chain, no fork needed)
//        node test-bnkr-factory.cjs     (RPC override: env RPC)
//
//  Every mutating tx carries an EXPLICIT nonce read from 'latest' (automine
//  mines before wait() returns, so 'latest' is always the next nonce) — no
//  NonceManager, no 'pending' blockTag: reverted attempts can't drift state.
// ============================================================
'use strict';
const fs = require('fs');
const path = require('path');
// resilient requires: plain first (installed locally), then the build workspace
function req(name) {
  try { return require(name); } catch (_) {
    return require('C:/Users/bigji/Documents/mftusd-build/node_modules/' + name);
  }
}
const { ethers } = req('ethers');
const solc = req('solc');

const RPC = process.env.RPC || 'http://127.0.0.1:8595';
const PK0 = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'; // hardhat #0 = admin
const PK1 = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'; // hardhat #1 = user

let pass = 0, fail = 0;
const ok = (l, c, e = '') => { console.log((c ? '  PASS ' : '  FAIL ') + l + (e ? '  ' + e : '')); c ? pass++ : fail++; };
async function expectRevert(p, substr, label) {
  try { await p; ok(label, false, '(did NOT revert)'); }
  catch (e) {
    const msg = (e.shortMessage || '') + ' ' + (e.reason || '') + ' ' + (e.message || '') + ' ' + JSON.stringify(e.info || {});
    ok(label, msg.includes(substr), msg.includes(substr) ? '' : '(wrong reason: ' + msg.slice(0, 120) + ')');
  }
}

// ── compile factory + sample children with the pinned queue settings ──
const FACTORY_SOL = fs.readFileSync(path.join(__dirname, 'DeployerFactory.sol'), 'utf8');
const CHILD_SOL = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract Hello { uint256 public x; constructor(uint256 _x) { x = _x; } }
contract PayableChild { uint256 public x; constructor(uint256 _x) payable { x = _x; } }
contract ForceSend { constructor(address payable t) payable { selfdestruct(t); } }
`;
function compileAll() {
  const input = {
    language: 'Solidity',
    sources: { 'DeployerFactory.sol': { content: FACTORY_SOL }, 'Child.sol': { content: CHILD_SOL } },
    settings: {
      viaIR: true, optimizer: { enabled: true, runs: 200 }, evmVersion: 'paris',
      outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object'] } },
    },
  };
  const out = JSON.parse(solc.compile(JSON.stringify(input)));
  const fatal = (out.errors || []).filter((e) => e.severity === 'error');
  if (fatal.length) { fatal.forEach((e) => console.error(e.formattedMessage)); process.exit(1); }
  const g = (f, n) => ({ abi: out.contracts[f][n].abi, bytecode: '0x' + out.contracts[f][n].evm.bytecode.object });
  return {
    factory: g('DeployerFactory.sol', 'DeployerFactory'),
    hello: g('Child.sol', 'Hello'),
    payable: g('Child.sol', 'PayableChild'),
    force: g('Child.sol', 'ForceSend'),
  };
}
const initCodeOf = (art, types, vals) =>
  art.bytecode + (types.length ? ethers.AbiCoder.defaultAbiCoder().encode(types, vals).slice(2) : '');

(async () => {
  console.log('solc:', solc.version());
  const art = compileAll();
  console.log('factory creation bytes:', (art.factory.bytecode.length - 2) / 2);

  // batchMaxCount 1 = one HTTP request per RPC call, strictly sequential — the
  // HH3 EDR node can serve batched/parallel reads out of order (stale nonce/balance).
  const p = new ethers.JsonRpcProvider(RPC, undefined, { staticNetwork: true, batchMaxCount: 1 });
  p.pollingInterval = 100;
  const net = await p.getNetwork();
  console.log('local EVM chainId:', net.chainId.toString(), '\n');
  const admin = new ethers.Wallet(PK0, p);
  const user = new ethers.Wallet(PK1, p);
  const ops = ethers.Wallet.createRandom().address; // fresh address -> exact balance deltas
  const bal = async (a) => BigInt(await p.send('eth_getBalance', [a, 'latest']));

  // LOCAL nonce ledger: read once at start, increment only after a MINED tx.
  // Immune to node-side read lag; reverted attempts (estimateGas) consume nothing.
  const nonces = {
    [admin.address]: await p.getTransactionCount(admin.address, 'latest'),
    [user.address]: await p.getTransactionCount(user.address, 'latest'),
  };
  async function send(contract, wallet, fn, args, value) {
    const nonce = nonces[wallet.address];
    const overrides = value !== undefined ? { nonce, value } : { nonce };
    const tx = await contract.connect(wallet).getFunction(fn).send(...args, overrides);
    const rc = await tx.wait();
    nonces[wallet.address]++;
    return rc;
  }
  const deployedEvent = (rc, iface) =>
    rc.logs.map((l) => { try { return iface.parseLog(l); } catch (_) { return null; } }).find((x) => x && x.name === 'Deployed');

  // ── 1. factory deploys + wiring ──
  const F = await new ethers.ContractFactory(art.factory.abi, art.factory.bytecode, admin)
    .deploy(ops, admin.address, { nonce: nonces[admin.address] });
  await F.waitForDeployment();
  nonces[admin.address]++;
  const factoryAddr = await F.getAddress();
  const f = new ethers.Contract(factoryAddr, art.factory.abi, p);
  ok('factory deployed, admin/opsWallet/fee/renounced as constructed',
    (await f.admin()) === admin.address && (await f.opsWallet()) === ops &&
    (await f.fee()) === 0n && (await f.adminRenounced()) === false);

  // ── 2. ABI surface: no hidden lever ──
  const mutating = art.factory.abi
    .filter((x) => x.type === 'function' && (x.stateMutability === 'nonpayable' || x.stateMutability === 'payable'))
    .map((x) => x.name).sort();
  const expected = ['deploy', 'deployDeterministic', 'renounceAdmin', 'setFee', 'setOpsWallet', 'withdrawStuck'].sort();
  ok('ABI mutating fns == exactly the expected six', JSON.stringify(mutating) === JSON.stringify(expected), mutating.join(','));

  // ── 3. CREATE path (fee = 0): simulate, send, read event, verify child ──
  const helloInit = initCodeOf(art.hello, ['uint256'], [42]);
  const simulated = await f.connect(user).deploy.staticCall(helloInit);
  const rc1 = await send(f, user, 'deploy', [helloInit]);
  const ev1 = deployedEvent(rc1, f.interface);
  ok('CREATE: Deployed event present, deployer = caller', !!ev1 && ev1.args[0] === user.address);
  ok('CREATE: event addr == staticCall-simulated addr', !!ev1 && ev1.args[1] === simulated);
  ok('CREATE: feePaid = 0 while fee unset', !!ev1 && ev1.args[2] === 0n);
  const helloAddr = ev1.args[1];
  ok('CREATE: code exists at the new address', (await p.getCode(helloAddr)) !== '0x');
  ok('CREATE: constructor arg respected (x == 42)', (await new ethers.Contract(helloAddr, art.hello.abi, p).x()) === 42n);

  // ── 4. CREATE2 path + prediction + duplicate salt ──
  const hello7Init = initCodeOf(art.hello, ['uint256'], [7]);
  const salt = ethers.id('bankr-skill-test');
  const predicted = await f.computeAddress(ethers.keccak256(hello7Init), salt);
  const rc2 = await send(f, user, 'deployDeterministic', [hello7Init, salt]);
  const ev2 = deployedEvent(rc2, f.interface);
  ok('CREATE2: computeAddress prediction == actual deployed addr', !!ev2 && ev2.args[1] === predicted);
  ok('CREATE2: code exists + constructor arg respected (x == 7)',
    (await p.getCode(predicted)) !== '0x' && (await new ethers.Contract(predicted, art.hello.abi, p).x()) === 7n);
  await expectRevert(send(f, user, 'deployDeterministic', [hello7Init, salt]), 'create2 failed', 'CREATE2: duplicate salt+initCode REVERTS');

  // ── 5. fee rail ──
  const FEE = ethers.parseEther('0.0001');
  await expectRevert(send(f, user, 'setFee', [FEE]), 'not admin', 'setFee by non-admin REVERTS');
  await send(f, admin, 'setFee', [FEE]);
  ok('admin setFee works (fee == 0.0001 ETH)', (await f.fee()) === FEE);
  await expectRevert(send(f, user, 'deploy', [initCodeOf(art.hello, ['uint256'], [1])]), 'fee not paid', 'underpaying deploy REVERTS');

  const opsBefore = await bal(ops);
  const rc3 = await send(f, user, 'deploy', [initCodeOf(art.hello, ['uint256'], [9])], FEE);
  const ev3 = deployedEvent(rc3, f.interface);
  ok('paying deploy succeeds, event feePaid == fee', !!ev3 && ev3.args[2] === FEE);
  const opsDelta = (await bal(ops)) - opsBefore;
  ok('fee landed on ops wallet EXACTLY', opsDelta === FEE, opsDelta === FEE ? '' : '(delta ' + opsDelta + ' vs fee ' + FEE + ')');

  const opsBefore2 = await bal(ops);
  const rc4 = await send(f, admin, 'deploy', [initCodeOf(art.hello, ['uint256'], [11])]); // 0 value, fee set
  const ev4 = deployedEvent(rc4, f.interface);
  ok('admin is fee-EXEMPT: 0-value deploy succeeds, feePaid == 0', !!ev4 && ev4.args[2] === 0n);
  ok('ops wallet unchanged on exempt deploy', (await bal(ops)) === opsBefore2);

  // ── 6. constructor endowment ──
  const EXTRA = ethers.parseEther('0.05');
  const opsBefore3 = await bal(ops);
  const rc5 = await send(f, user, 'deploy', [initCodeOf(art.payable, ['uint256'], [5])], FEE + EXTRA);
  const ev5 = deployedEvent(rc5, f.interface);
  ok('payable ctor: excess value became the child\'s endowment', (await bal(ev5.args[1])) === EXTRA);
  ok('payable ctor: ops still got exactly the fee', (await bal(ops)) - opsBefore3 === FEE);
  await expectRevert(send(f, user, 'deploy', [initCodeOf(art.hello, ['uint256'], [2])], FEE + 1n), 'create failed',
    'NON-payable ctor + excess value REVERTS (send exactly the fee)');

  // ── 7. stuck funds -> withdrawStuck (pre-renounce) ──
  const FORCED = ethers.parseEther('0.01');
  await send(f, admin, 'deploy', [initCodeOf(art.force, ['address'], [factoryAddr])], FORCED);
  ok('selfdestruct force-send stranded ETH in the factory', (await bal(factoryAddr)) === FORCED);
  await expectRevert(send(f, user, 'withdrawStuck', [ethers.ZeroAddress, FORCED]), 'not admin', 'withdrawStuck by non-admin REVERTS');
  const adminBefore = await bal(admin.address);
  await send(f, admin, 'withdrawStuck', [ethers.ZeroAddress, FORCED]);
  ok('withdrawStuck recovers the stranded ETH (factory balance -> 0)',
    (await bal(factoryAddr)) === 0n && (await bal(admin.address)) > adminBefore);

  // ── 9. no receive(): plain sends bounce ──
  await expectRevert(
    (async () => { const t = await user.sendTransaction({ to: factoryAddr, value: 1n, nonce: nonces[user.address] }); const rc = await t.wait(); nonces[user.address]++; return rc; })(),
    '', 'plain ETH transfer to factory REVERTS (no receive)');

  // ── 8. renounceAdmin: one-way config lock ──
  await expectRevert(send(f, user, 'renounceAdmin', []), 'not admin', 'renounceAdmin by non-admin REVERTS');
  await send(f, admin, 'renounceAdmin', []);
  ok('adminRenounced == true after renounce', (await f.adminRenounced()) === true);
  await expectRevert(send(f, admin, 'setFee', [1n]), 'renounced', 'post-renounce setFee LOCKED');
  await expectRevert(send(f, admin, 'setOpsWallet', [user.address]), 'renounced', 'post-renounce setOpsWallet LOCKED');
  await expectRevert(send(f, admin, 'withdrawStuck', [ethers.ZeroAddress, 0]), 'renounced', 'post-renounce withdrawStuck LOCKED');
  ok('ABI has NO function that can un-set adminRenounced (renounce is one-way)',
    !art.factory.abi.some((x) => x.type === 'function' && /unrenounce|unlock|resume/i.test(x.name)));

  // post-renounce: deploys still work, fee rail still routes, exemption persists
  const opsBefore4 = await bal(ops);
  const rc6 = await send(f, user, 'deploy', [initCodeOf(art.hello, ['uint256'], [3])], FEE);
  ok('post-renounce: paid deploy still works, fee still routes to ops',
    rc6.status === 1 && (await bal(ops)) - opsBefore4 === FEE);
  const rc7 = await send(f, admin, 'deploy', [initCodeOf(art.hello, ['uint256'], [4])]);
  ok('post-renounce: admin still fee-exempt', rc7.status === 1 && (await bal(ops)) - opsBefore4 === FEE);

  console.log('\n===== RESULT: ' + pass + ' passed, ' + fail + ' failed =====');
  process.exit(fail === 0 ? 0 : 1);
})().catch((e) => { console.error('SUITE ERROR:', e); process.exit(1); });
