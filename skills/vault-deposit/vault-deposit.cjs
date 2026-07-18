// Deposit ANY USDC amount into a CommunityLPVault, auto-routing over-slippage via the vault's NATIVE queue.
//   npm install ethers
//   DEPOSITOR_PRIVATE_KEY=0x...  node vault-deposit.cjs <vaultAddr> <usdcAmount_6dec>
// Small enough → instant deposit(). Too big → depositQueued() + metered processDeposit() loop.
const { ethers } = require('ethers');

const RPC  = process.env.DEPOSIT_RPC || 'https://mainnet.base.org';
const USDC = '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'; // Base USDC
const VAULT_ABI = [
  'function deposit(uint256) external',
  'function depositQueued(uint256) external',
  'function processDeposit(address,uint256) external',
  'function cancelDeposit(uint256) external',
  'function pendingDeposit(address) view returns (uint256)',
  'function shares(address) view returns (uint256)',
  'function maxInstantDeposit() view returns (uint256)',
];
const ERC20_ABI = [
  'function approve(address,uint256) external returns (bool)',
  'function balanceOf(address) view returns (uint256)',
];
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const [, , vaultAddr, amountStr] = process.argv;
  if (!vaultAddr || !amountStr) { console.log('usage: DEPOSITOR_PRIVATE_KEY=0x.. node vault-deposit.cjs <vault> <usdcAmount_6dec>'); return; }
  if (!process.env.DEPOSITOR_PRIVATE_KEY) { console.log('set DEPOSITOR_PRIVATE_KEY'); return; }
  const amount = BigInt(amountStr);

  const p = new ethers.JsonRpcProvider(RPC, 8453, { staticNetwork: true });
  const w = new ethers.Wallet(process.env.DEPOSITOR_PRIVATE_KEY, p);
  const vault = new ethers.Contract(vaultAddr, VAULT_ABI, w);
  const usdc  = new ethers.Contract(USDC, ERC20_ABI, w);
  const me = w.address;
  const f6 = x => ethers.formatUnits(x, 6);
  console.log('depositor', me, '| vault', vaultAddr, '| amount', f6(amount), 'USDC');

  const bal = await usdc.balanceOf(me);
  if (bal < amount) { console.log('🔴 insufficient USDC:', f6(bal)); return; }
  const maxInstant = await vault.maxInstantDeposit();
  console.log('maxInstantDeposit:', f6(maxInstant), 'USDC');

  await (await usdc.approve(vaultAddr, amount)).wait(); // exact approval

  const shBefore = await vault.shares(me);
  if (amount <= maxInstant) {
    console.log('→ fits — instant deposit()');
    await (await vault.deposit(amount)).wait();
  } else {
    console.log('→ over the cap — depositQueued() then metered processDeposit()');
    await (await vault.depositQueued(amount)).wait();
    let round = 0, guard = 0;
    while (guard++ < 500) {
      const pending = await vault.pendingDeposit(me);
      if (pending === 0n) break;
      const mi = await vault.maxInstantDeposit();
      let chunk = (mi * 9000n) / 10000n;         // 90% of the safe instant size
      if (chunk > pending) chunk = pending;
      if (chunk === 0n) { console.log('🔴 maxInstant=0 (pool empty?) — stopping. Use cancelDeposit to recover the rest.'); break; }
      try {
        await (await vault.processDeposit(me, chunk)).wait();
        console.log(`  round ${++round}: processed ${f6(chunk)} | pending left ${f6(pending - chunk)}`);
        await sleep(30000); // pace so arbs re-balance between chunks
      } catch (e) {
        console.log('  chunk hit the impact cap — halving + retry:', e.shortMessage || e.message);
        // next loop reads maxInstantDeposit fresh; brief wait
        await sleep(5000);
      }
    }
  }
  const shAfter = await vault.shares(me);
  console.log('✅ shares gained:', (shAfter - shBefore).toString(), '| total shares:', shAfter.toString());
})().catch(e => console.error('err', e.shortMessage || e.message));
