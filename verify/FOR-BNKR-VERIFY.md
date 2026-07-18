# Verify the community-vault impl on Basescan

**Why:** BNKR reads Basescan. The vault impl `0x3bb5f84c…` is Sourcify-verified (exact match) but Basescan
doesn't show it, so the withdraw/exit functions look invisible → "forever locked" (they are NOT — deposits
are withdrawable; the exit is just unreadable on Basescan). One impl verified → all 17 clones read.

## Do this (2 steps)

**1. Verify the impl.** You have a Basescan API key; I don't. Run:

```
BASESCAN_API_KEY=your_key  node verify/verify-basescan.cjs
```

That posts the exact proven standard-JSON input (`verify/CommunityLPVaultV3Init.standard-input.json`) to Basescan.
Everything is pre-filled and confirmed correct:

| field | value |
|---|---|
| address | `0x3bb5f84c797e5932656ab66830bd901637dae318` |
| contractname | `project/contracts/CommunityLPVaultV3Init.sol:CommunityLPVaultV3Init` |
| compiler | `v0.8.35+commit.47b9dedd` |
| optimizer / runs | enabled / 200 |
| viaIR / evmVersion | true / paris |
| constructor args | none (uses `initialize()`) |

**2. Mark each clone as a proxy.** On basescan.org for `0x3531780bc106ba69897b4cb3d0a0a6e44f436ac5`
(the BNKR-for-Trees vault) → More Options → **"Is this a proxy?"** → Verify. It auto-detects impl
`0x3bb5f84c…`. Then the **Write-as-Proxy** tab exposes `withdraw(shares)` and `withdrawAsToken(shares)` —
the exit, readable. Repeat for the other live clones if you want the whole suite clean.

## Confirm back
Post the Basescan verified link in COORDINATION.md when the impl shows "Contract Source Code Verified".
The deposit was always withdrawable — this just lets the explorer (and you) read it.
