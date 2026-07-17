// ============================================================
//  test-fee-splitter.cjs — local-EVM proof of FeeSplitter (the immutable N-way
//  fee router behind the "Fee Router" Bankr skill).
//
//  Proof list:
//   1. constructor guards: mismatched lengths / <2 recipients / zero recipient /
//      zero share / duplicate recipient / sum != 10000 ALL revert
//   2. ABI surface: mutating fns == exactly {release, releaseAll} — NO admin,
//      no owner, no pause, nothing to renounce (trustless by construction)
//   3. skill path: deploy a 2-way 50/50 splitter THROUGH DeployerFactory
//      (initCode wrapped in deploy(bytes)); event addr == simulated addr;
//      recipients()/shares() wired exactly as encoded
//   4. native flow: PaymentReceived on inflow; pending() exact; release() pays
//      the exact share; repeat release reverts "nothing due"; later inflows
//      accrue only NEW pending; releaseAll drains to zero
//   5. ERC20 flow: same accounting on a standard token AND a USDT-style token
//      (no return value from transfer)
//   6. 3-way 5000/3000/2000 (court-split shape): interleaved partial releases
//      stay exact; conservation (sum released == sum received)
//   7. rounding: floor-division dust stays bounded (<N wei) and is reabsorbed
//      by later inflows
//   8. bad recipients: a no-receive() contract cannot take its NATIVE share
//      (release reverts loudly; releaseAll all-or-nothing reverts; the OTHER
//      recipient still releases fine; ERC20 still delivers to it)
//   9. reentrancy: a recipient reentering release() from receive() gets caught
//      by the guard and cannot double-claim
//
//  RUN:  npx hardhat node --port 8596   (plain local chain, from mftusd-build)
//        node test-fee-splitter.cjs     (RPC override: env RPC)
//
//  Local nonce ledger (same as test-bnkr-factory.cjs): read once, increment
//  only after a MINED tx — immune to HH3 EDR 'latest' read lag.
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
const solc = req('solc');

const RPC = process.env.RPC || 'http://127.0.0.1:8596';
const PK0 = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'; // hardhat #0
const PK1 = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'; // hardhat #1

let pass = 0, fail = 0;
const ok = (l, c, e = '') => { console.log((c ? '  PASS ' : '  FAIL ') + l + (e ? '  ' + e : '')); c ? pass++ : fail++; };
async function expectRevert(p, substr, label) {
  try { await p; ok(label, false, '(did NOT revert)'); }
  catch (e) {
    const msg = (e.shortMessage || '') + ' ' + (e.reason || '') + ' ' + (e.message || '') + ' ' + JSON.stringify(e.info || {});
    ok(label, msg.includes(substr), msg.includes(substr) ? '' : '(wrong reason: ' + msg.slice(0, 140) + ')');
  }
}

// ── compile FeeSplitter + DeployerFactory + mocks with the pinned queue settings ──
const SPLITTER_SOL = fs.readFileSync(path.join(__dirname, 'FeeSplitter.sol'), 'utf8');
const FACTORY_SOL = fs.readFileSync(path.join(__dirname, '..', 'bankr-deploy-skill', 'DeployerFactory.sol'), 'utf8');
const MOCKS_SOL = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract MockERC20 {
    string public symbol = "MOCK";
    mapping(address => uint256) public balanceOf;
    function mint(address to, uint256 amt) external { balanceOf[to] += amt; }
    function transfer(address to, uint256 amt) external returns (bool) {
        require(balanceOf[msg.sender] >= amt, "bal");
        balanceOf[msg.sender] -= amt; balanceOf[to] += amt; return true;
    }
}
contract MockUSDT { // USDT-style: transfer returns NOTHING
    mapping(address => uint256) public balanceOf;
    function mint(address to, uint256 amt) external { balanceOf[to] += amt; }
    function transfer(address to, uint256 amt) external {
        require(balanceOf[msg.sender] >= amt, "bal");
        balanceOf[msg.sender] -= amt; balanceOf[to] += amt;
    }
}
contract Rejector { uint256 public poke; function ping() external { poke++; } } // no receive()
interface ISplit { function release(address, address) external returns (uint256); }
contract Reentrant { // TEST ATTACKER: tries to reenter release() from its receive hook
    ISplit public target; bool public reentered; uint256 public attempts;
    function setTarget(address t) external { target = ISplit(t); }
    receive() external payable {
        if (address(target) != address(0)) {
            attempts++;
            try target.release(address(0), address(this)) returns (uint256) { reentered = true; } catch {}
        }
    }
}
`;
function compileAll() {
  const input = {
    language: 'Solidity',
    sources: {
      'FeeSplitter.sol': { content: SPLITTER_SOL },
      'DeployerFactory.sol': { content: FACTORY_SOL },
      'Mocks.sol': { content: MOCKS_SOL },
    },
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
    splitter: g('FeeSplitter.sol', 'FeeSplitter'),
    factory: g('DeployerFactory.sol', 'DeployerFactory'),
    erc20: g('Mocks.sol', 'MockERC20'),
    usdt: g('Mocks.sol', 'MockUSDT'),
    rejector: g('Mocks.sol', 'Rejector'),
    reentrant: g('Mocks.sol', 'Reentrant'),
  };
}
const coder = ethers.AbiCoder.defaultAbiCoder();
const splitterInit = (art, recips, sharesBps) =>
  art.splitter.bytecode + coder.encode(['address[]', 'uint256[]'], [recips, sharesBps]).slice(2);

(async () => {
  console.log('solc:', solc.version());
  const art = compileAll();
  console.log('splitter creation bytes:', (art.splitter.bytecode.length - 2) / 2);

  const p = new ethers.JsonRpcProvider(RPC, undefined, { staticNetwork: true, batchMaxCount: 1 });
  p.pollingInterval = 100;
  const net = await p.getNetwork();
  console.log('local EVM chainId:', net.chainId.toString(), '\n');
  const admin = new ethers.Wallet(PK0, p);
  const user = new ethers.Wallet(PK1, p);
  const bal = async (a) => BigInt(await p.send('eth_getBalance', [a, 'latest']));

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
  async function sendEth(wallet, to, value) {
    const tx = await wallet.sendTransaction({ to, value, nonce: nonces[wallet.address] });
    const rc = await tx.wait();
    nonces[wallet.address]++;
    return rc;
  }
  async function deployDirect(artifact, args, wallet) {
    const F = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
    const c = await F.deploy(...args, { nonce: nonces[wallet.address] });
    await c.waitForDeployment();
    nonces[wallet.address]++;
    return c;
  }
  const parsedEvents = (rc, iface) =>
    rc.logs.map((l) => { try { return iface.parseLog(l); } catch (_) { return null; } }).filter(Boolean);

  const E = ethers.parseEther;
  const NATIVE = ethers.ZeroAddress;
  const splitIface = new ethers.Interface(art.splitter.abi);

  // ══ 1. constructor guards ══
  console.log('── constructor guards ──');
  const rA = ethers.Wallet.createRandom().address, rB = ethers.Wallet.createRandom().address;
  const guard = (recips, shares, substr, label) =>
    expectRevert(deployDirect(art.splitter, [recips, shares], admin), substr, label);
  await guard([rA, rB], [5000], 'length mismatch', 'mismatched lengths REVERT');
  await guard([rA], [10000], 'need at least 2 recipients', 'single recipient REVERTS');
  await guard([rA, ethers.ZeroAddress], [5000, 5000], 'zero recipient', 'zero-address recipient REVERTS');
  await guard([rA, rB], [10000, 0], 'zero share', 'zero share REVERTS');
  await guard([rA, rA], [5000, 5000], 'duplicate recipient', 'duplicate recipient REVERTS');
  await guard([rA, rB], [4000, 4000], 'shares must sum to 10000', 'sum < 10000 REVERTS');
  await guard([rA, rB], [6000, 6000], 'shares must sum to 10000', 'sum > 10000 REVERTS');

  // ══ 2. ABI surface: trustless by construction ══
  console.log('── ABI surface ──');
  const mutating = art.splitter.abi
    .filter((x) => x.type === 'function' && (x.stateMutability === 'nonpayable' || x.stateMutability === 'payable'))
    .map((x) => x.name).sort();
  ok('ABI mutating fns == exactly {release, releaseAll} — no admin lever anywhere',
    JSON.stringify(mutating) === JSON.stringify(['release', 'releaseAll']), mutating.join(','));
  ok('ABI has no owner/admin/pause/renounce/set/withdraw function at all',
    !art.splitter.abi.some((x) => x.type === 'function' && /owner|admin|pause|renounce|set[A-Z]|withdraw|upgrade|transfer[A-Z]/.test(x.name)));

  // ══ 3. skill path: deploy 2-way 50/50 THROUGH DeployerFactory ══
  console.log('── deploy through DeployerFactory (the skill path) ──');
  const F = await deployDirect(art.factory, [ethers.Wallet.createRandom().address, admin.address], admin);
  const f = new ethers.Contract(await F.getAddress(), art.factory.abi, p);
  const init2 = splitterInit(art, [rA, rB], [5000, 5000]);
  const sim2 = await f.connect(user).deploy.staticCall(init2);
  const rcF = await send(f, user, 'deploy', [init2]);
  const evF = parsedEvents(rcF, f.interface).find((x) => x.name === 'Deployed');
  ok('factory Deployed event addr == staticCall-simulated addr', !!evF && evF.args[1] === sim2);
  ok('deploy-through-factory gas well under any cap', rcF.gasUsed < 1_500_000n, 'gasUsed=' + rcF.gasUsed);
  const s2addr = evF.args[1];
  ok('code exists at the splitter address', (await p.getCode(s2addr)) !== '0x');
  const s2 = new ethers.Contract(s2addr, art.splitter.abi, p);
  const recList = await s2.recipients();
  ok('recipients() == exactly the encoded pair', recList.length === 2 && recList[0] === rA && recList[1] === rB);
  ok('shares(): 5000 / 5000, non-recipient 0, count 2, TOTAL_BPS 10000',
    (await s2.shares(rA)) === 5000n && (await s2.shares(rB)) === 5000n &&
    (await s2.shares(user.address)) === 0n && (await s2.recipientCount()) === 2n &&
    (await s2.TOTAL_BPS()) === 10000n);

  // ══ 4. native flow ══
  console.log('── native flow (2-way 50/50) ──');
  const rcIn = await sendEth(user, s2addr, E('1'));
  const evIn = parsedEvents(rcIn, splitIface).find((x) => x.name === 'PaymentReceived');
  ok('PaymentReceived(from=sender, amount=1 ETH) emitted on inflow',
    !!evIn && evIn.args[0] === user.address && evIn.args[1] === E('1'));
  ok('pending: 0.5 / 0.5 after 1 ETH in', (await s2.pending(NATIVE, rA)) === E('0.5') && (await s2.pending(NATIVE, rB)) === E('0.5'));
  ok('pending for a non-recipient == 0 (no revert)', (await s2.pending(NATIVE, user.address)) === 0n);

  const rc1 = await send(s2, user, 'release', [NATIVE, rA]); // third party triggers; funds go to rA
  const ev1 = parsedEvents(rc1, splitIface).find((x) => x.name === 'PaymentReleased');
  ok('release(native, A) by a THIRD PARTY pays A exactly 0.5 ETH', (await bal(rA)) === E('0.5'));
  ok('PaymentReleased(token=0x0, to=A, 0.5 ETH) emitted',
    !!ev1 && ev1.args[0] === NATIVE && ev1.args[1] === rA && ev1.args[2] === E('0.5'));
  ok('released(native, A) == 0.5, totalReleased(native) == 0.5',
    (await s2.released(NATIVE, rA)) === E('0.5') && (await s2.totalReleased(NATIVE)) === E('0.5'));
  ok('pending(native, A) == 0 after release', (await s2.pending(NATIVE, rA)) === 0n);
  await expectRevert(send(s2, user, 'release', [NATIVE, rA]), 'nothing due', 'repeat release REVERTS "nothing due"');
  await expectRevert(send(s2, user, 'release', [NATIVE, user.address]), 'not a recipient', 'release for non-recipient REVERTS');

  await sendEth(user, s2addr, E('0.4'));
  ok('after +0.4 ETH: pending A == 0.2 (only NEW inflow), pending B == 0.7 (0.5 old + 0.2 new)',
    (await s2.pending(NATIVE, rA)) === E('0.2') && (await s2.pending(NATIVE, rB)) === E('0.7'));
  await send(s2, user, 'releaseAll', [NATIVE]);
  ok('releaseAll(native): A == 0.7 total, B == 0.7 total, splitter balance == 0',
    (await bal(rA)) === E('0.7') && (await bal(rB)) === E('0.7') && (await bal(s2addr)) === 0n);
  ok('totalReleased(native) == 1.4 (conservation)', (await s2.totalReleased(NATIVE)) === E('1.4'));
  await expectRevert(send(s2, user, 'releaseAll', [NATIVE]), 'nothing due', 'releaseAll with nothing due REVERTS (visible no-op)');

  // ══ 5. ERC20 flow ══
  console.log('── ERC20 flow (standard + USDT-style) ──');
  const tok = await deployDirect(art.erc20, [], admin);
  const tokAddr = await tok.getAddress();
  await send(tok, admin, 'mint', [s2addr, E('1000')]);
  ok('pending(token, A) == 500 after 1000 minted in', (await s2.pending(tokAddr, rA)) === E('500'));
  await send(s2, user, 'release', [tokAddr, rA]);
  ok('release(token, A) pays exactly 500', (await tok.balanceOf(rA)) === E('500'));
  await send(tok, admin, 'mint', [s2addr, E('250')]);
  ok('after +250: pending A == 125, pending B == 625',
    (await s2.pending(tokAddr, rA)) === E('125') && (await s2.pending(tokAddr, rB)) === E('625'));
  await send(s2, user, 'releaseAll', [tokAddr]);
  ok('releaseAll(token): A == 625, B == 625, splitter token balance == 0',
    (await tok.balanceOf(rA)) === E('625') && (await tok.balanceOf(rB)) === E('625') && (await tok.balanceOf(s2addr)) === 0n);
  ok('totalReleased(token) == 1250', (await s2.totalReleased(tokAddr)) === E('1250'));

  const usdt = await deployDirect(art.usdt, [], admin);
  const usdtAddr = await usdt.getAddress();
  await send(usdt, admin, 'mint', [s2addr, 100_000_000n]); // 100 "USDT" (6dp)
  await send(s2, user, 'releaseAll', [usdtAddr]);
  ok('USDT-style token (no transfer return value): releaseAll splits 50/50 exactly',
    (await usdt.balanceOf(rA)) === 50_000_000n && (await usdt.balanceOf(rB)) === 50_000_000n);
  ok('USDT-style: splitter drained to 0', (await usdt.balanceOf(s2addr)) === 0n);

  // ══ 6. 3-way court-split shape (5000/3000/2000) through the factory ══
  console.log('── 3-way 5000/3000/2000 (through the factory) ──');
  const r3 = [ethers.Wallet.createRandom().address, ethers.Wallet.createRandom().address, ethers.Wallet.createRandom().address];
  const init3 = splitterInit(art, r3, [5000, 3000, 2000]);
  const sim3 = await f.connect(user).deploy.staticCall(init3);
  const rc3f = await send(f, user, 'deploy', [init3]);
  const ev3f = parsedEvents(rc3f, f.interface).find((x) => x.name === 'Deployed');
  ok('3-way deploy through factory: event addr == simulated', !!ev3f && ev3f.args[1] === sim3);
  const s3 = new ethers.Contract(ev3f.args[1], art.splitter.abi, p);
  const s3addr = ev3f.args[1];
  await sendEth(user, s3addr, E('1'));
  ok('pending == 0.5 / 0.3 / 0.2 after 1 ETH',
    (await s3.pending(NATIVE, r3[0])) === E('0.5') && (await s3.pending(NATIVE, r3[1])) === E('0.3') && (await s3.pending(NATIVE, r3[2])) === E('0.2'));
  await send(s3, user, 'release', [NATIVE, r3[1]]); // only the 30% payee pulls
  ok('partial: only B released (B == 0.3, A/C untouched)',
    (await bal(r3[1])) === E('0.3') && (await bal(r3[0])) === 0n && (await bal(r3[2])) === 0n);
  await sendEth(user, s3addr, E('1'));
  ok('after +1 ETH: pending A == 1.0, B == 0.3, C == 0.4 (interleave stays exact)',
    (await s3.pending(NATIVE, r3[0])) === E('1') && (await s3.pending(NATIVE, r3[1])) === E('0.3') && (await s3.pending(NATIVE, r3[2])) === E('0.4'));
  await send(s3, user, 'releaseAll', [NATIVE]);
  ok('releaseAll: A == 1.0, B == 0.6, C == 0.4, splitter == 0',
    (await bal(r3[0])) === E('1') && (await bal(r3[1])) === E('0.6') && (await bal(r3[2])) === E('0.4') && (await bal(s3addr)) === 0n);
  const relSum = (await s3.released(NATIVE, r3[0])) + (await s3.released(NATIVE, r3[1])) + (await s3.released(NATIVE, r3[2]));
  ok('conservation: sum(released) == 2 ETH == totalReleased', relSum === E('2') && (await s3.totalReleased(NATIVE)) === E('2'));

  // ══ 7. rounding dust ══
  console.log('── rounding dust ──');
  const r4 = [ethers.Wallet.createRandom().address, ethers.Wallet.createRandom().address, ethers.Wallet.createRandom().address];
  const s4 = await deployDirect(art.splitter, [r4, [5000, 3000, 2000]], admin);
  const s4addr = await s4.getAddress();
  await sendEth(user, s4addr, 10001n);
  ok('10001 wei in: pending floors to 5000 / 3000 / 2000',
    (await s4.pending(NATIVE, r4[0])) === 5000n && (await s4.pending(NATIVE, r4[1])) === 3000n && (await s4.pending(NATIVE, r4[2])) === 2000n);
  await send(s4, user, 'releaseAll', [NATIVE]);
  ok('dust: exactly 1 wei stays (bounded < N wei), all pending == 0',
    (await bal(s4addr)) === 1n && (await s4.pending(NATIVE, r4[0])) === 0n && (await s4.pending(NATIVE, r4[1])) === 0n && (await s4.pending(NATIVE, r4[2])) === 0n);
  await sendEth(user, s4addr, 9999n); // total received now 20000 — divisible
  await send(s4, user, 'releaseAll', [NATIVE]);
  ok('dust reabsorbed by later inflow: splitter == 0, payouts == 10000/6000/4000 of 20000',
    (await bal(s4addr)) === 0n && (await bal(r4[0])) === 10000n && (await bal(r4[1])) === 6000n && (await bal(r4[2])) === 4000n);

  // ══ 8. bad recipient: contract with no receive() ══
  console.log('── native-rejecting recipient ──');
  const rej = await deployDirect(art.rejector, [], admin);
  const rejAddr = await rej.getAddress();
  const rGood = ethers.Wallet.createRandom().address;
  const s5 = await deployDirect(art.splitter, [[rejAddr, rGood], [5000, 5000]], admin);
  const s5addr = await s5.getAddress();
  await sendEth(user, s5addr, E('1'));
  await expectRevert(send(s5, user, 'release', [NATIVE, rejAddr]), 'native send failed',
    'release(native) to a no-receive contract REVERTS loudly');
  await expectRevert(send(s5, user, 'releaseAll', [NATIVE]), 'native send failed',
    'releaseAll is all-or-nothing: one bad payee reverts the batch');
  await send(s5, user, 'release', [NATIVE, rGood]);
  ok('per-account isolation: the GOOD recipient still gets its exact 0.5 ETH', (await bal(rGood)) === E('0.5'));
  await send(tok, admin, 'mint', [s5addr, E('10')]);
  await send(s5, user, 'releaseAll', [tokAddr]);
  ok('ERC20 still delivers to the no-receive contract (5 / 5 split)',
    (await tok.balanceOf(rejAddr)) === E('5') && (await tok.balanceOf(rGood)) === E('5'));

  // ══ 9. reentrancy ══
  console.log('── reentrancy guard ──');
  const attacker = await deployDirect(art.reentrant, [], admin);
  const atkAddr = await attacker.getAddress();
  const rSafe = ethers.Wallet.createRandom().address;
  const s6 = await deployDirect(art.splitter, [[atkAddr, rSafe], [5000, 5000]], admin);
  const s6addr = await s6.getAddress();
  await send(attacker, admin, 'setTarget', [s6addr]);
  await sendEth(user, s6addr, E('1'));
  await send(s6, user, 'release', [NATIVE, atkAddr]);
  ok('attacker attempted reentry from receive() (attempts == 1)', (await attacker.attempts()) === 1n);
  ok('inner reentrant release() FAILED (reentered == false)', (await attacker.reentered()) === false);
  ok('attacker got EXACTLY its 0.5 share, not a wei more; accounting intact',
    (await bal(atkAddr)) === E('0.5') && (await s6.released(NATIVE, atkAddr)) === E('0.5') &&
    (await s6.pending(NATIVE, atkAddr)) === 0n && (await s6.pending(NATIVE, rSafe)) === E('0.5'));

  console.log('\n===== RESULT: ' + pass + ' passed, ' + fail + ' failed =====');
  process.exit(fail === 0 ? 0 : 1);
})().catch((e) => { console.error('SUITE ERROR:', e); process.exit(1); });
