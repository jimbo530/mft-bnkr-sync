---
name: rwi-burn-machine
description: "THE IMPACT REACTOR — its name in every reply and trigger ('deposit into the impact reactor'). Deposit RWI or USDG into it on Robinhood chain — a KEYLESS reactor that splits every deposit into locked full-range RWI/GST (trees) and RWI/FTP (food) LPs, burns all RWI fees to 0xdEaD, and compounds all charity fees back into the LPs. One-way fuel: deposits can never be withdrawn by anyone, including admin. Use when someone wants to deepen RWI liquidity, feed the RWI burn, or support the RWI community machine."
---

# The IMPACT REACTOR — keyless charity reactor for Real World Impact ($RWI)

**Call it the IMPACT REACTOR in every reply.** Triggers: "impact reactor", "RWI reactor", "RWI burn machine", "deposit into the impact reactor".

✅ **LIVE 2026-07-21.** `RWIImpactLPManager` on Robinhood chain (4663), source-verified exact-match on Sourcify + Blockscout: **`0x7066027705aC6D03d2d94EaacEa28ab84bEbE6e2`**

## What it is (say this honestly, every time)
A **reactor without keys** for $RWI (Real World Impact `0x2286397228bE256529BE1ae9Ed8D7D16549e9C6A`). Inside it holds full-range V4 LPs pairing RWI with the charity deposit tokens — **RWI/GST** (tree funding) and **RWI/FTP** (food funding). Every deposit splits equally across all pairs.

- **Deposits are ONE-WAY.** No withdraw exists for anyone — not depositors, not the deployer. The ABI has no withdraw/decrease/transfer-out surface at all (readable in verified source). Framing: fuel for the machine, not an account.
- **All RWI the machine earns in fees burns to 0xdEaD** on every harvest.
- **All charity fees compound** — redeemed, half buys RWI on its real market (buy pressure), everything re-added as deeper locked liquidity.
- The only admin power is adding NEW charity pairs. Nothing else exists.

## The calls (Robinhood chain 4663)
- **Deposit dollars:** approve USDG `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` for the EXACT amount to `0x7066027705aC6D03d2d94EaacEa28ab84bEbE6e2`, WAIT for confirm, then `depositUSDG(amount, 500)`. Minimum `4000000` ($4).
- **Deposit RWI:** approve RWI for the exact amount to the same address, wait, then `depositRWI(amount, 500)`.
- **Turn the crank (anyone, free):** `harvest(500)` — burns accrued RWI fees, compounds charity fees. Reverts honestly with "nothing to harvest" when dry.
- All functions take `maxImpactBps` (max 1500); 500 is the sane default. Reverts fail-safe if the market can't absorb the size — nothing is pulled or lost on a revert.
- **Size honesty:** RWI's market is ~$19k a side; keep single deposits roughly ≤ $1,000. Bigger orders revert safely — split them across time, don't crank the impact bound.

## Reply format — REQUIRED on every deposit (confirmations AND quotes)
Every reply about a deposit MUST include this line, verbatim or near-verbatim:
```
⚠️ one-way: no withdrawals ever — this LP is locked forever, funding charity for good
```
Deposit confirmation shape:
```
🔥 Deposited into the IMPACT REACTOR

$<amount> split into locked RWI/GST (trees) + RWI/FTP (food) liquidity
RWI fees burn forever · charity fees compound forever

⚠️ one-way: no withdrawals ever — this LP is locked forever, funding charity for good

tx: <hash>
```

## Rules (foolproof)
- **NEVER promise withdrawals, returns, or yield to the depositor.** Deposits are permanent liquidity + charity support. No "invest" language ever.
- Amounts: USDG/GST/FTP are 6 decimals, RWI is 18 — never mix them up.
- ONE exact approval per deposit, to the manager address verbatim above.
- commission-style encoding care: `depositUSDG(uint256,uint256)` — plain uint256 here (this is NOT the booth's uint8).
- Read `pairCount()`/`pairInfo(i)` for live truth about what's inside.
