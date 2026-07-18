# DEPLOY: BnkrTreeEscrowV5 (public-drip)

**Coordinator built + compile-verified this. Your job: deploy → verify → show it off. Do NOT rebuild or "improve" it.**

Compile-checked clean: solc 0.8.36, **0 errors, 0 warnings, 8215 bytes**. Vault-agnostic drip escrow — anyone deposits large USDC into ANY whitelisted vault without slippage (30s metered chunks). One contract for all 50+ vaults.

## ⭐ drip() is PUBLIC — no trusted keeper
`drip(dripId)` is permissionless: **anyone** can press the button and pay gas. A founder-run keeper (any EOA/bot calling `drip()` every 30s) is just the *default* caller — but the depositor, or anyone, can advance a drip too. The 30s cooldowns cap the rate, and calling `drip()` only ADVANCES a deposit the depositor already wants, so there's no abuse vector. No keeper trust required.

## Constructor args (2 addresses)
`constructor(address _usdc, address _admin)`

| arg | value | notes |
|---|---|---|
| `_usdc` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | REAL Base USDC — verified. Do NOT use any other address. |
| `_admin` | **founder picks** | whitelists vaults, rescues EXCESS only, renounces. Recommend the agent-ops wallet `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`. |

(No keeper arg — drip is public.)

## Steps
1. **Deploy** `contracts/BnkrTreeEscrowV5.sol` (Solidity ^0.8.20, optimizer enabled, 200 runs) with the 2 args.
2. **Verify** on Basescan — `codeformat=solidity-standard-json-input`, `constructorArguements` = the 2 addresses ABI-encoded. (`verify/sourcify-to-basescan.cjs <addr> <ctorHex>` or hardhat verify.)
3. **Whitelist** vaults (admin): `setVaultWhitelist(vault, true)` — start with the BNKR-for-Trees vault `0x3531780Bc106bA69897b4CB3D0a0A6E44F436AC5`; add other clones from factory `0x1f6ff7370e2E897dB7Cf5d72684Ef76d988cAAf1` `vaults(i)` as you want them live.
4. **Test round-trip** (small): `createDrip(0x3531…, 1000000)` ($1) → wait 30s → **anyone** calls `drip(1)` → `getDrip(1)` shows `sharesEarned>0` → `claimShares(1)` returns USDC. Confirm on-chain.
5. **Keeper (optional, founder-run):** the founder sets up any bot/automation to call `drip(id)` every 30s for each id in `activeDrips()`. It's just paying gas — the button is public, so the community/depositor can also call it.
6. **After a successful withdrawal + soak:** admin `renounceRescue()` → provably can't touch deposits (trustless).
7. Post the deployed address + txHash to `deployed/bnkr-tree-escrow-v5.json` + reply in `COORDINATION.md` (and actually `git push`).

## Built-in safety (already correct — do not change)
- `deposit`/`withdraw` return NOTHING → shares via `shares()` delta, USDC via balance delta (matches the real vault ABI).
- `drip()` PUBLIC — permissionless, cooldown-throttled, only advances deposits.
- `rescue` = EXCESS above `totalCommittedUSDC` only — never depositor funds. `renounceRescue()` one-way.
- Double-refund guarded (cancel/claim set `drippedUSDC = totalUSDC`). `nonReentrant` + CEI throughout. Admin whitelist gates allowed vaults.

*(Supersedes v1–v4. v4 was broken — wrong vault interface + inverted rescue. This is the corrected, keeper-free build.)*
