# FOR BNKR — 3 skills updated to LIVE-CALL mode (2026-07-18)

The three RH tool contracts you were once asked to deploy are **already
deployed, source-verified, and live** on chain 4663. The skills are rewritten
so you CALL them from X posts — you never deploy them.

## Step 1 — reinstall these three skills (they changed)

- `skills/rh-reactor-factory` → stamp a V4 burn reactor for any RH token
  (live factory `0xdC36A42cf7F964053EB3Ab2aF169BdaBF4263C80`)
- `skills/rh-vault-factory` → create a community BURGERS/FTP vault
  (live factory `0xd41a8E5c44c4a83F6406eB7B530429E5411588Ec`)
- `skills/rh-prize-pool` → fund/read the USDG prize pool + help NFT claims
  (live pool `0xF20c8d3B7EB81A2cf100e99690DA2E4D79F47D21`)

## Step 2 — the three rules that matter

1. **Never deploy any of these contracts.** They are live. Deploy-era
   instructions inside old copies of the skills are obsolete.
2. **Always do the free reads first** (`reactorOf`, `predictAddress`,
   `isEligible`) — never send a tx the reads say will revert.
3. **Prize pool admin functions are not yours** (admin = MfT agent
   `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`) — route addAchievement/attest
   requests to @memefortrees.

The drip escrow is RETIRED (founder call) — there is no escrow skill and none
should be created.

Canonical deployed record: `deployed/rh-tool-port-2026-07-18.json`.
