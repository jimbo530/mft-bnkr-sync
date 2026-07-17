// ============================================================
//  compile-fee-splitter.cjs — pinned-compiler build of FeeSplitter.sol
//  (queue spec: solc 0.8.35+commit.47b9dedd, viaIR:true, optimizer 200,
//  evmVersion paris — same settings as the DeployerFactory package).
//
//  Writes:  creation-bytecode.txt, FeeSplitter-abi.json,
//           example-2way-50-50.txt, example-3way-50-30-20.txt
//  Prints:  sizes, selectors, event topics, and the full grounded initCode +
//           deploy(bytes) calldata for both worked examples in SKILL.md.
//
//  Run:  node compile-fee-splitter.cjs
// ============================================================
'use strict';
const fs = require('fs');
const path = require('path');
// resilient requires: plain first (if installed here), then the build workspace
function req(name) {
  try { return require(name); } catch (_) {
    return require('C:/Users/bigji/Documents/mftusd-build/node_modules/' + name);
  }
}
const solc = req('solc');
const { ethers } = req('ethers');

const SOL_FILE = path.join(__dirname, 'FeeSplitter.sol');
const OUT_DIR = __dirname;
const PINNED = '0.8.35+commit.47b9dedd';

const source = fs.readFileSync(SOL_FILE, 'utf8');
const input = {
  language: 'Solidity',
  sources: { 'FeeSplitter.sol': { content: source } },
  settings: {
    viaIR: true,
    optimizer: { enabled: true, runs: 200 },
    evmVersion: 'paris',
    outputSelection: {
      'FeeSplitter.sol': { FeeSplitter: ['abi', 'evm.bytecode.object', 'evm.deployedBytecode.object'] },
    },
  },
};

console.log('solc version:', solc.version());
if (!solc.version().startsWith(PINNED)) {
  console.error('WRONG COMPILER: need ' + PINNED + ', got ' + solc.version());
  process.exit(1);
}
const output = JSON.parse(solc.compile(JSON.stringify(input)));
if (output.errors && output.errors.length > 0) {
  const fatal = output.errors.filter((e) => e.severity === 'error');
  if (fatal.length > 0) {
    console.error('COMPILE ERRORS:');
    fatal.forEach((e) => console.error(e.formattedMessage));
    process.exit(1);
  }
  output.errors.filter((e) => e.severity === 'warning').forEach((w) => console.warn(w.formattedMessage));
}

const c = output.contracts['FeeSplitter.sol']['FeeSplitter'];
if (!c || !c.evm.bytecode.object) { console.error('empty bytecode — compile failed'); process.exit(1); }
const creation = c.evm.bytecode.object;
const runtime = c.evm.deployedBytecode.object;
console.log('FeeSplitter creation bytecode:', creation.length / 2, 'bytes');
console.log('FeeSplitter runtime  bytecode:', runtime.length / 2, 'bytes (EIP-170 cap 24576)');

fs.writeFileSync(path.join(OUT_DIR, 'creation-bytecode.txt'), '0x' + creation);
fs.writeFileSync(path.join(OUT_DIR, 'FeeSplitter-abi.json'), JSON.stringify(c.abi, null, 2));

// ── grounded worked examples for SKILL.md ──
// PLACEHOLDER recipients (0x1111…, 0x2222…, 0x3333…) — valid, non-zero, obviously
// not real. Anyone using the examples MUST swap in their own recipient addresses.
const A = '0x1111111111111111111111111111111111111111';
const B = '0x2222222222222222222222222222222222222222';
const C = '0x3333333333333333333333333333333333333333';

const factoryIface = new ethers.Interface(['function deploy(bytes initCode) payable returns (address)']);
const coder = ethers.AbiCoder.defaultAbiCoder();
function example(label, recips, sharesBps, outFile) {
  const ctorTail = coder.encode(['address[]', 'uint256[]'], [recips, sharesBps]);
  const initCode = '0x' + creation + ctorTail.slice(2);
  const calldata = factoryIface.encodeFunctionData('deploy', [initCode]);
  const body = [
    '# ' + label,
    '# recipients : ' + recips.join(', '),
    '# sharesBps  : ' + sharesBps.join(', ') + '   (sum = 10000)',
    '# PLACEHOLDER recipients — replace with YOUR addresses before any real deploy.',
    '',
    '## ABI-encoded constructor tail  =  abi.encode(address[],uint256[])',
    ctorTail,
    '',
    '## initCode  =  creation bytecode ++ constructor tail   (' + ((initCode.length - 2) / 2) + ' bytes)',
    initCode,
    '## keccak256(initCode)  (for CREATE2 computeAddress)',
    ethers.keccak256(initCode),
    '',
    '## full deploy(bytes) calldata — the entire tx `data` field, send to the factory',
    '## to = 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D (DeployerFactory, Base 8453), value = fee() (0 at launch)',
    calldata,
    '',
  ].join('\n');
  fs.writeFileSync(path.join(OUT_DIR, outFile), body);
  console.log('\n── ' + label + ' ──');
  console.log('ctor tail bytes :', (ctorTail.length - 2) / 2);
  console.log('initCode bytes  :', (initCode.length - 2) / 2);
  console.log('calldata bytes  :', (calldata.length - 2) / 2);
  console.log('written         :', outFile);
  return { ctorTail, initCode, calldata };
}

example('2-way 50/50 split', [A, B], [5000, 5000], 'example-2way-50-50.txt');
example('3-way 50/30/20 split', [A, B, C], [5000, 3000, 2000], 'example-3way-50-30-20.txt');

// selectors + topics, grounded from the compiled ABI
const iface = new ethers.Interface(c.abi);
console.log('\n── selectors / topics (grounded from compiled ABI) ──');
for (const f of ['release', 'releaseAll', 'pending', 'shares', 'totalReleased', 'released', 'recipients', 'recipientCount']) {
  console.log(f.padEnd(15), iface.getFunction(f).selector, ' ', iface.getFunction(f).format('sighash'));
}
console.log('PaymentReceived topic0 :', iface.getEvent('PaymentReceived').topicHash);
console.log('PaymentReleased topic0 :', iface.getEvent('PaymentReleased').topicHash);
console.log('\nwritten to', OUT_DIR + ': creation-bytecode.txt, FeeSplitter-abi.json, example files');
