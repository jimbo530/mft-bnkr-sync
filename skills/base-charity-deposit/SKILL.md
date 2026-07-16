---
name: base-charity-deposit
description: Deposit into any Meme for Trees charity fund on Base and receive a 1:1 charity deposit receipt. Covers all six live funds — Money (USDC), PRGT (USDC), CHAR-R (USDC), CCC-R (USDC), BTC-T (cbBTC), ETH-T (wETH). Use when the user says "deposit $25 into Money for Trees", "put $50 into CHAR-R", "deposit 0.001 cbBTC into BTC for Trees", or any similar intent for a Meme for Trees Base charity fund. Each fund mints the caller a 1:1 receipt token, fully backed and redeemable 1:1 at any time; only the vault's Aave yield (not principal) is routed to the cause. All six funds are on Base (chainId 8453), executable via Bankr today.
---

# Base Charity Deposit

Deposit a supported asset into a Meme for Trees charity fund on Base and receive
a **1:1 charity deposit receipt** token. The receipt is fully backed and
redeemable 1:1 at any time via `redeem(amount)`. Only the vault's Aave V3 yield
(not your principal) is split to the cause and the Meme for Trees reactor.

> Receipt tokens (Money, PRGT, CHAR-R, CCC-R, BTC-T, ETH-T) are charity
> **deposit receipts** — not stablecoins and not financial instruments. Your
> principal is redeemable 1:1; only yield is routed to the cause.

All addresses below were verified on-chain on 2026-07-14 (see
`references/funds.md`).

## Quick Start

```bash
# $25 USDC -> 25 Money for Trees
./scripts/deposit.sh money 25

# $50 USDC -> 50 CHAR-R (carbon retirement)
./scripts/deposit.sh char-r 50

# 0.001 cbBTC -> 0.001 BTC-T (trees, BTC-denominated)
./scripts/deposit.sh btc-t 0.001
```

## Funds

| Key      | Friendly name          | Receipt token | Deposit asset | Asset address (Base)                         | Asset dec | Fund address (Base)                          |
|----------|------------------------|---------------|---------------|----------------------------------------------|-----------|----------------------------------------------|
| `money`  | Money for Trees        | Money         | USDC          | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6         | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` |
| `prgt`   | Poly Raiders Growth T. | PRGT          | USDC          | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6         | `0xEe6fB5f324B05efF95fD59F4574050a891e6913D` |
| `char-r` | CHAR Retirement Fund   | CHAR-R        | USDC          | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6         | `0xde12963128CBe9aF173a37FFF866cA4D4A194ff4` |
| `ccc-r`  | CCC Retirement Fund    | CCC-R         | USDC          | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6         | `0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B` |
| `btc-t`  | BTC for Trees          | BTC-T         | cbBTC         | `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf` | 8         | `0x839BAa00734f319C11F2869bC155C6B5Fe35a283` |
| `eth-t`  | ETH for Trees          | ETH-T         | wETH          | `0x4200000000000000000000000000000000000006` | 18        | `0x80d1edd0236A06283fd1212FDB12cfA79516933d` |

All funds are on Base (chainId 8453).

Natural-language aliases the agent should accept:

- `money` / `mft` / `mftusd` / "money for trees"
- `prgt` / "poly raiders growth token" / "poly raiders"
- `char-r` / "char retirement" / "CHAR-R" / "carbon retirement"
- `ccc-r` / "ccc retirement" / "CCC-R" / "carbon counting"
- `btc-t` / "btc for trees" / "BTC-T"
- `eth-t` / "eth for trees" / "ETH-T"

## How It Works

Every CharityFund exposes the same public permissionless interface:

```
deposit(uint256 amount)                  // mint receipt to msg.sender, 1:1
depositFor(address to, uint256 amount)   // mint receipt to `to`, 1:1
redeem(uint256 amount)                   // burn receipt, withdraw asset 1:1
```

`deposit(amount)` pulls the deposit asset from the caller via `transferFrom`,
so a deposit is always **two on-chain transactions**:

1. `approve(fund, amount)` on the deposit asset ERC-20 (USDC / cbBTC / wETH)
2. `deposit(amount)` on the fund — mints `amount` receipt tokens 1:1 to you

The script builds both as raw calldata and hands them to Bankr.

## Usage

```bash
# Deposit <amount> of the fund's asset, receive receipt to yourself
./scripts/deposit.sh <key> <amount>

# Mint receipt to another address instead
./scripts/deposit.sh <key> <amount> <0xRecipient>

# Examples
./scripts/deposit.sh money 25             # 25 USDC -> 25 Money
./scripts/deposit.sh char-r 100          # 100 USDC -> 100 CHAR-R
./scripts/deposit.sh btc-t 0.001         # 0.001 cbBTC -> 0.001 BTC-T
./scripts/deposit.sh eth-t 0.005         # 0.005 wETH -> 0.005 ETH-T
./scripts/deposit.sh money 25 0xABC...   # deposit $25, mint Money to 0xABC
```

Amounts are in whole units of the deposit asset (e.g. `25` = $25 USDC,
`0.001` = 0.001 cbBTC). The script converts to base units using the fund's
decimal count.

## Technical Details

### Function selectors

| Function                    | Selector     |
|-----------------------------|--------------|
| `approve(address,uint256)`  | `0x095ea7b3` |
| `deposit(uint256)`          | `0xb6b55f25` |
| `depositFor(address,uint256)` | `0x2f4f21e2` |
| `redeem(uint256)`           | `0xdb006a75` |
| `balanceOf(address)`        | `0x70a08231` |

Selectors verified from `CharityFund.sol` (keccak of function signature).

### Decimal handling

| Fund key | Asset | Asset decimals | Receipt decimals |
|----------|-------|----------------|-----------------|
| money    | USDC  | 6              | 6               |
| prgt     | USDC  | 6              | 6               |
| char-r   | USDC  | 6              | 6               |
| ccc-r    | USDC  | 6              | 6               |
| btc-t    | cbBTC | 8              | 8 (CharityFund decimals() returns 6 but cbBTC is 8 dec — see note) |
| eth-t    | wETH  | 18             | 18 (CharityFund decimals() returns 6 but wETH is 18 dec — see note) |

> Note on BTC-T and ETH-T: `CharityFund.sol` hardcodes `decimals() = 6` but
> these funds hold cbBTC (8 dec) and wETH (18 dec) respectively. The fund
> mints 1:1 in raw token units, so always use the **deposit asset's decimal
> count** when encoding calldata — 8 for BTC-T, 18 for ETH-T. The script
> handles this correctly per fund key.

### ABI

See `references/abi.json` for the minimal ABI covering `approve`, `deposit`,
`depositFor`, `redeem`, and `balanceOf`.

## Requirements

- Bankr skill installed with an API key configured.
- For USDC funds (money/prgt/char-r/ccc-r): USDC on Base + ETH for gas.
- For BTC-T: cbBTC on Base + ETH for gas.
- For ETH-T: wETH on Base + ETH for gas. (wETH, not native ETH — you need the wrapped token.)
- Arbitrary contract calls must be enabled (Bankr Security -> "Disable arbitrary contract calls" must be OFF).

## Notes

- **1:1 and redeemable.** `deposit(amount)` mints exactly `amount` receipt
  tokens. `redeem(amount)` burns them and returns the asset 1:1. No deposit or
  redemption fee.
- **Cause is funded by yield only.** Deposited assets earn Aave V3 yield on
  Base. A fixed share of that yield (not principal) is routed to the cause
  wallet and the Meme for Trees reactor. Your principal is always 1:1.
- **Permissionless and immutable.** No owner, no admin, no upgrade path. All
  CharityFund clones are deployed from the same verified factory
  `0x955383723E8A1AD82800406D6f492260918DF882`.
- **All on Base (8453).** All six funds are on Base and executable via Bankr today.
