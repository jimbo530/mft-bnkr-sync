---
name: base-charity-vault-create
description: Seed a new community LP vault or create a new CharityFund clone on Base. Two separate creation flows — (a) LP vault factories (MfTVaultFactory / FundVaultFactory variants for CHAR-R, CCC-R, BTC-T, ETH-T) that deploy a paired liquidity vault in one transaction with seed assets, and (b) CharityFundFactory which deploys a brand-new CharityFund clone for any charity wallet. Use when the user wants to launch a community vault for a token, add a new charity fund, or seed initial liquidity into a fund-backed vault on Base (chainId 8453).
---

# Base Charity Vault & Fund Creation

Two creation flows exist in the Meme for Trees ecosystem on Base:

**A. LP Vault creation** — deploy a community liquidity vault (CommunityLPVaultV3 clone)
for a specific token, seeded with an underlying asset. One transaction handles
deploy + seed + LP burn. Created vaults automatically register their LP with the
paired charity fund.

**B. CharityFund creation** — deploy a new CharityFund clone (EIP-1167) via
CharityFundFactory. The new fund accepts USDC deposits and routes yield to a
specified charity wallet. Infrastructure (Aave, reactor, serviceBps) is inherited
from the factory.

All addresses verified on-chain 2026-07-14. Chain: Base (chainId 8453).

---

## A. LP Vault Creation

### Factories

| Key         | Factory address                              | Underlying seed asset | Asset (Base)                                 | Dec | Paired fund |
|-------------|----------------------------------------------|-----------------------|----------------------------------------------|-----|-------------|
| `mft-vault` | `0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1` | USDC                  | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6   | Money for Trees `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` |
| `char-r-vault` | `0x503fe2226ed8c93bC7864a3E59cEb2c64C305c64` | USDC                | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6   | CHAR-R `0xde12963128CBe9aF173a37FFF866cA4D4A194ff4` |
| `ccc-r-vault` | `0x4a2DFd07A13aBD64553d34F65074fc716D97C290`  | USDC                | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6   | CCC-R `0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B` |
| `prgt-vault` | `0xA54C86b545F6451c761Da684740bb390495170Df`  | USDC                 | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6   | PRGT `0xEe6fB5f324B05efF95fD59F4574050a891e6913D` |
| `btc-t-vault` | `0xA7BeD0d9963837E8426F241f132e1F8daEA6bD8B` | cbBTC               | `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf` | 8   | BTC-T `0x839BAa00734f319C11F2869bC155C6B5Fe35a283` |
| `eth-t-vault` | `0xc2Dbb3A02CF43270e3A69c2e15354887E094575f` | wETH                | `0x4200000000000000000000000000000000000006` | 18  | ETH-T `0x80d1edd0236A06283fd1212FDB12cfA79516933d` |

All LP vault factories share the same `createVault` signature:

```solidity
function createVault(
    address token,        // the meme/community token to pair
    uint256 seedAmount,   // seed of the underlying asset (USDC/cbBTC/wETH)
    uint256 tokenAmount,  // amount of token to seed (sets price ratio)
    uint256 maxImpactBps  // max price impact in bps (1–1500; 500 = 5%)
) external returns (address vault)
```

What `createVault` does in one transaction:
1. Pulls `seedAmount` underlying asset from caller + `tokenAmount` token from caller.
2. Deploys a `CommunityLPVaultV3` EIP-1167 clone (or FOT variant).
3. Seeds the vault with the provided underlying + token, creating a V2 LP pair at that ratio.
4. Burns the seeding LP tokens to `0xdead` (permanently locked).
5. Auto-registers the LP pool with the paired charity fund.

Selector: `createVault(address,uint256,uint256,uint256)` = `0x0eabcca1`

### Minimum seeds

| Key          | Min seed amount | Notes |
|--------------|----------------|-------|
| `mft-vault`  | 10,000,000 (10 USDC, 6 dec) | `MIN_USDC` from bytecode |
| `char-r-vault` | 20,000,000 (20 USDC, 6 dec) | `MIN_SEED` from fund-vault-factories-deployment.json |
| `ccc-r-vault` | 20,000,000 (20 USDC, 6 dec) | same |
| `prgt-vault` | 20,000,000 (20 USDC, 6 dec) | same |
| `btc-t-vault` | 32,000 sats (0.00032 cbBTC, 8 dec) | `MIN_CBBTC` from BTCTVaultFactory.json / fund-vault-factories-deployment.json |
| `eth-t-vault` | 11,500,000,000,000,000 wei (0.0115 wETH, 18 dec) | `MIN_WETH` from ETHTVaultFactory.json |

### Usage

```bash
# Create a USDC-paired vault for a token (mft-vault, char-r-vault, ccc-r-vault, prgt-vault)
./scripts/create-vault.sh <factory-key> <token> <seedUsdc> <tokenAmount> <maxImpactBps>

# Create a cbBTC-paired vault
./scripts/create-vault.sh btc-t-vault <token> <seedCbbtcSats> <tokenAmount> <maxImpactBps>

# Create a wETH-paired vault
./scripts/create-vault.sh eth-t-vault <token> <seedWethWei> <tokenAmount> <maxImpactBps>

# Examples
./scripts/create-vault.sh mft-vault 0xYourToken 20000000 1000000000000000000 500
  # 20 USDC + 1e18 token units -> vault at that price, 5% max impact

./scripts/create-vault.sh btc-t-vault 0xYourToken 32000 1000000000000000000 500
  # 32000 sats (~$20) + 1e18 token -> BTC-T-paired vault

./scripts/create-vault.sh eth-t-vault 0xYourToken 11500000000000000 1000000000000000000 500
  # 0.0115 wETH + 1e18 token -> ETH-T-paired vault
```

> Amounts for `seedAmount` and `tokenAmount` must be in **raw base units** (not whole tokens).
> The script handles conversion for human-readable seed inputs — see `references/factories.md`.

---

## B. CharityFund Creation

The `CharityFundFactory` deploys EIP-1167 clones of `CharityFund`. Each clone is
an isolated USDC deposit pool for a specific charity. Infrastructure (Aave V3
pool, aUSDC, mftUSD V2 contract, reactor, v3 position manager, v3 factory,
serviceBps) is inherited from the factory and cannot be changed.

### Factory

| Contract | Address | Chain |
|---|---|---|
| CharityFundFactory | `0x955383723E8A1AD82800406D6f492260918DF882` | Base (8453) |

Verified: `implementation() = 0xBEA5c3D2dc02C4A8385896ca70CCC6345574c96f` (CharityFund logic, 15,135 bytes on-chain).

### `createFund` signature

```solidity
function createFund(
    string calldata name_,        // token name  (e.g. "My Charity Token")
    string calldata symbol_,      // token symbol (e.g. "MCT")
    address charityWallet,        // address that receives the charity's USDC yield share
    uint16 charityBps             // charity share in basis points (min 1000 = 10%, max 9000 - serviceBps)
) external returns (address fund)
```

Selector: `createFund(string,string,address,uint16)` = `0x5c275a39`

What `createFund` does:
1. Clones the CharityFund implementation via EIP-1167 minimal proxy.
2. Calls `initialize()` on the clone with all infra inherited from the factory.
3. Registers the new fund in the factory's registry.
4. Emits `FundCreated(fund, charityWallet, name, symbol, charityBps, serviceBps)`.

The new fund immediately accepts `deposit(uint256)` calls from anyone.

### Constraints

| Parameter | Rule |
|---|---|
| charityBps | Minimum 1000 (10%). Maximum: `9000 - serviceBps` |
| serviceBps | Set by factory at deploy time; read from `factory.serviceBps()`. Immutable. |
| holderBps | Auto-computed: `10000 - charityBps - serviceBps`. Cannot be set directly. |
| USDC | Always `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (Base) — inherited from factory |
| Aave | Always `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5` — inherited from factory |
| Reactor | Always Reactor Prime `0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA` — inherited |

### Usage

```bash
# Create a new CharityFund clone
./scripts/create-fund.sh <name> <symbol> <charityWallet> <charityBps>

# Example — 33.34% to charity, factory keeps its serviceBps, holder gets the rest
./scripts/create-fund.sh "My Charity Token" MCT 0xCharityWalletAddress 3334
```

---

## Technical Details

### Selectors

| Function | Selector |
|---|---|
| `createVault(address,uint256,uint256,uint256)` | `0x0eabcca1` |
| `createFund(string,string,address,uint16)` | `0x5c275a39` |
| `approve(address,uint256)` (ERC-20) | `0x095ea7b3` |

### ABI

See `references/abi.json` for the minimal ABI covering `createVault`,
`createFund`, and the ERC-20 `approve` needed before each.

### What callers must approve before calling createVault

The factory's `createVault` pulls both the seed underlying and the token from
`msg.sender`. So two `approve` calls are needed:

1. `approve(factory, seedAmount)` on the underlying asset (USDC / cbBTC / wETH)
2. `approve(factory, tokenAmount)` on the community token

`createFund` needs no approvals (it only deploys a clone, no asset transfer).

## Requirements

- Bankr skill installed with an API key configured.
- For LP vault creation: must hold both the seed underlying asset (USDC/cbBTC/wETH)
  and the community token on Base.
- For CharityFund creation: ETH for gas only (no asset transfer).
- Arbitrary contract calls must be enabled (Bankr Security -> "Disable arbitrary contract calls" must be OFF).

## Notes

- **LP vault LPs are permanently locked.** `createVault` burns the seeding LP
  tokens to `0xdead`. The vault price is set by the seed ratio — there is no
  undo. Verify price ratio before calling.
- **LP auto-registers with the fund.** Each FundVaultFactory variant calls
  `fund.registerV2Pool(lp)` after deploying, so LP yield flows to the fund
  immediately. This is permanent (pool registry is grow-only).
- **CharityFund clones are immutable.** No admin, no owner, no upgrade. The
  `charityWallet` and `charityBps` are set at initialization and never changed.
- **serviceBps is factory-level.** All funds from a given factory share the same
  serviceBps. New funds can adjust their charityBps within the allowed range
  but cannot change what goes to the reactor.
