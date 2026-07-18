// Create a CommunityLPVault for a token via MfTVaultFactory (a contract deploy = builder points).
//   CREATOR_PRIVATE_KEY=0x..  node create-vault.cjs <tokenAddr> <usdcAmount_6dec> <tokenAmount_raw> <maxImpactBps 1-1500>
// Checks for an existing vault first; if none, seeds + deploys a new one.
const { ethers } = require('ethers');
const RPC = process.env.DEPLOY_RPC || 'https://mainnet.base.org';
const FACTORY = '0x1f6ff7370e2E897dB7Cf5d72684Ef76d988cAAf1'; // MfTVaultFactory (verified)
const USDC = '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913';
const FACTORY_ABI = [
  'function createVault(address token, uint256 usdcAmount, uint256 tokenAmount, uint256 maxImpactBps) external returns (address)',
  'function vaultsForToken(address) view returns (address[])',
  'function MIN_USDC() view returns (uint256)',
];
const ERC20_ABI = [
  'function approve(address,uint256) external returns (bool)',
  'function balanceOf(address) view returns (uint256)',
  'function symbol() view returns (string)',
];
(async () => {
  const [, , token, usdcStr, tokenAmtStr, impactStr] = process.argv;
  if (!token || !usdcStr || !tokenAmtStr || !impactStr) {
    console.log('usage: CREATOR_PRIVATE_KEY=0x.. node create-vault.cjs <token> <usdc_6dec> <tokenAmount_raw> <maxImpactBps 1-1500>');
    return;
  }
  if (!process.env.CREATOR_PRIVATE_KEY) { console.log('set CREATOR_PRIVATE_KEY'); return; }
  const p = new ethers.JsonRpcProvider(RPC, 8453, { staticNetwork: true });
  const w = new ethers.Wallet(process.env.CREATOR_PRIVATE_KEY, p);
  const factory = new ethers.Contract(FACTORY, FACTORY_ABI, w);
  const usdc = new ethers.Contract(USDC, ERC20_ABI, w);
  const tok = new ethers.Contract(token, ERC20_ABI, w);
  const usdcAmt = BigInt(usdcStr), tokenAmt = BigInt(tokenAmtStr), impact = BigInt(impactStr);

  // 1. already have a vault?
  const existing = await factory.vaultsForToken(token);
  if (existing.length) { console.log('✅ vault ALREADY EXISTS for', token, '→', existing[existing.length - 1]); return; }

  // 2. guards
  const minUsdc = await factory.MIN_USDC();
  if (usdcAmt < minUsdc) { console.log('🔴 usdc below MIN_USDC:', ethers.formatUnits(minUsdc, 6)); return; }
  if (impact < 1n || impact > 1500n) { console.log('🔴 maxImpactBps must be 1..1500'); return; }
  if (await usdc.balanceOf(w.address) < usdcAmt) { console.log('🔴 need', ethers.formatUnits(usdcAmt, 6), 'USDC'); return; }
  if (await tok.balanceOf(w.address) < tokenAmt) { console.log('🔴 insufficient token balance for the seed'); return; }

  // 3. exact approvals
  await (await usdc.approve(FACTORY, usdcAmt)).wait();
  await (await tok.approve(FACTORY, tokenAmt)).wait();

  // 4. create
  let sym = '?'; try { sym = await tok.symbol(); } catch {}
  console.log(`creating vault for ${sym} (${token}) — seed ${ethers.formatUnits(usdcAmt, 6)} USDC + ${tokenAmt} token...`);
  const tx = await factory.createVault(token, usdcAmt, tokenAmt, impact, { gasLimit: 3_000_000 });
  console.log('createVault tx:', tx.hash, '— waiting...');
  await tx.wait();

  const after = await factory.vaultsForToken(token);
  const vault = after[after.length - 1];
  console.log('✅ VAULT CREATED:', vault, '| token', sym, token);
  console.log('deposit via skills/vault-deposit/ — any size. basescan: https://basescan.org/address/' + vault);
})().catch(e => console.error('err', e.shortMessage || e.reason || e.message));
