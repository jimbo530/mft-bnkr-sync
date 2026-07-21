# Vault Front Door — single-USDC vault creation for the BNKR bot (SPEC)

**Status:** BUILT 2026-07-21 — `mftusd-build/contracts/VaultFrontDoor.sol`, compiled clean (solc 0.8.36) + **48/48 Base-fork tests** (`test-vault-frontdoor-fork.cjs`). Entry is now `createVaultWithUSDC(token, usdcTotal>=20e6, maxImpactBps, handle)` emitting `FrontDoorVault(requester, token, vault, handle, created)`; existing-vault calls pull nothing. NOTE the flow below said "USDC→WETH→token" — grounded reality: band tokens live on **Money V3 1% walls**, so v1 routes Money-V3-wall → Money-V2-pair → WETH-V3 → WETH-V2, else reverts `no supported venue`. Open items resolved: (1) vault owner = front door, whose only vault power is setMaxImpact (config, zero fund control — passthrough kept); (2) routing resolved on-chain by the contract, no per-token params; (3) 50/50 split confirmed by the $20-min shape; (4) RH → `RH-FRONTDOOR-NOTES.md`. Deploy + first real vault = money op → founder's go.

## Why
`MfTVaultFactory.createVault(token, usdcAmount, tokenAmount, maxImpactBps)` (Base, `0x1f6fF7370e2E897dB7Cf5d72684Ef76d988Caaf1`, **verified from source**) already does the full seed-and-lock:
mint Money from USDC → seed Money/token V2 LP → **burn seed LP to `0xdEaD` forever** → clone a `CommunityLPVaultV3Init`.
**But it `transferFrom`s BOTH USDC *and* the token from the caller** — so the caller must hold two tokens and set two approvals in one flow. **BNKR's transfer tool sends one token per prompt.** The front door removes the second token.

## The flow (confirmed with founder 2026-07-19)
BNKR sends **one token — $20 USDC** — and makes one call. The front door does the rest in one tx:
1. Pull `$20 USDC` from BNKR (`transferFrom`).
2. **Buy the pairing token:** swap **$10 USDC → WETH → token** (founder-confirmed path — the tokens' LPs are WETH-paired), slippage-guarded.
3. Approve the factory for the remaining **$10 USDC** + the bought token.
4. `factory.createVault(token, 10e6, boughtTokenAmt, maxImpactBps)` → factory mints Money from the $10, seeds the LP, burns it forever, clones the vault.
5. Return the new vault; sweep any dust back to BNKR.

Result: BNKR only ever sends **USDC to one address** and calls one function. No two-token prompt.

## Verified constants (from factory source)
- Factory `USDC` = `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` · `FUND` (Money) = `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072`
- `MIN_USDC` = `10_000_000` ($10) — factory's floor for the Money side.
- Factory burns the seed LP to `0xdEaD` (permanent floor) and clones `CommunityLPVaultV3Init`.
- **Vault owner is set to `msg.sender` of `createVault`** → that becomes the **front door**, not BNKR/founder (see open item 1).

## Safety (non-negotiable, per our rules)
- **Exact approvals** (never MaxUint256) · **no hardcoded prices** — quote live, revert on stale · **slippage guard** on the USDC→WETH→token swap (`minTokenOut`) · **reentrancy guard** · **no silent catches**.
- **Renounce-capable** — any admin/escape hatch ships with one-way `renounceAdminWithdraw()`.
- This is a **money op** — deploy + first real vault seed are gated on the founder's explicit go.

## Open items to confirm before build is final
1. **Vault owner.** The factory hardwires `owner = msg.sender`, so the front door becomes owner. Who *should* own the created vaults — the founder/project wallet, the requester, or renounced? (Front door can transfer ownership post-create if the vault supports it.)
2. **Swap routing per token.** USDC→WETH→token needs the token's actual pool (fee tier / venue). Pass the path+fee as a call param, or resolve per token from `token-lp-registry.json`? The bands' LPs are non-standard (task #14) — the router/path must match each token's real pool.
3. **The split.** $10 to the Money side + $10 to buy the token is the default; the token's $-value at seed sets the vault's initial price. Confirm 50/50, or a different ratio.
4. **Chain.** This wraps the **Base** factory. ALAN/$ALAN is on Robinhood — an RH port wraps `MfTVaultFactoryFOT_RH` + GST/USDG + the RH venue (later, per port-don't-reinvent).
