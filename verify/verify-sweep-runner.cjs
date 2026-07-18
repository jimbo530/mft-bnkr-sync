// BNKR: verify every unverified Base contract in one run.
//   BASESCAN_API_KEY=your_key  node verify/verify-sweep-runner.cjs
// Loops sourcify-to-basescan.cjs over unverified-base-addrs.txt, categorizes, writes sweep-results.json.
const fs = require('fs');
const { execFileSync } = require('child_process');
const DIR = __dirname;
const ADDRS = fs.readFileSync(DIR + '/unverified-base-addrs.txt', 'utf8').split(/\r?\n/).map(s => s.trim()).filter(a => /^0x[0-9a-fA-F]{40}$/.test(a));
const results = { verified: [], already: [], needsArgs: [], notOnSourcify: [], failed: [] };

(async () => {
  console.log('sweeping', ADDRS.length, 'addresses...');
  for (let i = 0; i < ADDRS.length; i++) {
    const a = ADDRS[i];
    let out = '';
    try {
      out = execFileSync('node', [DIR + '/sourcify-to-basescan.cjs', a], { encoding: 'utf8', timeout: 140000 });
    } catch (e) { out = (e.stdout || '') + ' ERR:' + e.message.slice(0, 60); }
    let tag;
    if (/✅ VERIFIED/.test(out)) { results.verified.push(a); tag = 'VERIFIED'; }
    else if (/already verified/i.test(out)) { results.already.push(a); tag = 'already'; }
    else if (/no stdJsonInput|not.*sourcif|"error"/i.test(out)) { results.notOnSourcify.push(a); tag = 'not-on-sourcify'; }
    else if (/does NOT match|Fail/i.test(out)) { results.needsArgs.push(a); tag = 'needs-ctor-args'; }
    else { results.failed.push(a); tag = 'unclear'; }
    console.log(`${i + 1}/${ADDRS.length}`, a, tag);
    fs.writeFileSync(DIR + '/sweep-results.json', JSON.stringify(results, null, 2));
    await new Promise(s => setTimeout(s, 1500)); // pace for rate limits
  }
  console.log('\n=== DONE ===');
  console.log('verified', results.verified.length, '| already', results.already.length,
    '| needs-args', results.needsArgs.length, '| not-on-sourcify', results.notOnSourcify.length, '| failed', results.failed.length);
})();
