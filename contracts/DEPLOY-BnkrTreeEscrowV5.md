# DEPLOY: BnkrTreeEscrowV5

**Coordinator built + compile-verified this. Your job: deploy → verify → show it off. Do NOT rebuild or "improve" it.**

Compile-checked clean: solc 0.8.36, **0 errors, 0 warnings, 8404 bytes**. Vault-agnostic drip escrow — lets anyone deposit large USDC into ANY whitelisted vault without slippage (30s metered chunks). One contract for all 50+ vaults.

## Constructor args (3 addresses)
`constructor(address _usdc, address _keeper, address _admin)`

| arg | value | notes |
|---|---|---|
| `_usdc` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | REAL Base USDC — verified. Do NOT use any other address. |
| `_keeper` | **founder picks** | calls `drip()` every 30s. Agent wallet `0xd7dfc7fe6c2b582b142dbc23ad172f735106b598` or a fresh one — CONFIRM with founder first. |
| `_admin` | **founder picks** | whitelists vaults, rescues EXCESS only, renounces. Recommend the project/agent wallet. |

## Steps
1. **Deploy** `contracts/BnkrTreeEscrowV5.sol` (Solidity ^0.8.20, optimizer enabled, 200 runs) with the 3 args.
2. **Verify** on Basescan — `codeformat=solidity-standard-json-input`, `constructorArguements` = the 3 addresses ABI-encoded. (`verify/sourcify-to-basescan.cjs <addr> <ctorHex>` or hardhat verify.)
3. **Whitelist** vaults (admin): `setVaultWhitelist(vault, true)` — start with the BNKR-for-Trees vault `0x3531780Bc106bA69897b4CB3D0a0A6E44F436AC5`; add other clones from factory `0x1f6ff7370e2E897dB7Cf5d72684Ef76d988cAAf1` `vaults(i)` as you want them live.
4. **Test round-trip** (small): `createDrip(0x3531…, 1000000)` ($1) → wait 30s → keeper `drip(1)` → `getDrip(1)` shows `sharesEarned>0` → `claimShares(1)` returns USDC. Confirm on-chain.
5. **Keeper loop:** automate `drip(id)` every 30s for each id in `activeDrips()`.
6. **After a successful withdrawal + soak:** admin `renounceRescue()` → provably can't touch deposits (trustless).
7. Post the deployed address + txHash to `deployed/bnkr-tree-escrow-v5.json` + reply in `COORDINATION.md` (and actually `git push`).

## Built-in safety (already correct — do not change)
- `deposit`/`withdraw` return NOTHING → shares via `shares()` delta, USDC via balance delta (matches the real vault ABI).
- `rescue` = EXCESS above `totalCommittedUSDC` only — never depositor funds. `renounceRescue()` one-way.
- Double-refund guarded (cancel/claim set `drippedUSDC = totalUSDC`). `nonReentrant` + CEI throughout. Admin whitelist gates which vaults are allowed.

*(Supersedes v1–v4. v4 was broken — wrong vault interface + inverted rescue. This is the corrected build.)*
