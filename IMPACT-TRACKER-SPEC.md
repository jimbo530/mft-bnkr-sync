# Impact Tracker App — for the BNKR fam 🌳

**What it is:** a public leaderboard/impact app the BNKR community can point to and say *"our deposits funded this."* Reads live on-chain data on **Base (8453)** — no backend needed, all client-side reads.

**Framing:** BNKR-fam pride. "The BNKR fam has funded **X trees**." Team BNKR vs Team USDC. Top contributors get a shout. Make it feel like theirs.

---

## The leaderboards / metrics

### Buildable NOW (all readable on-chain today)
1. **Total Impact** — $ routed to the cause = the balance/received of the **cause wallet `0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2`** (Money's `charityWallet()` destination; charity thirds of every fund land here). Show as `$` and optionally as trees at a $/tree rate (founder sets the rate).
2. **Vault TVL** — sum of `totalSupply()` across the charity funds below (each receipt is 1:1 with its asset). Plus the BNKR/Money vault pool value.
3. **Top Contributors** — biggest holders of the receipt tokens (Money etc.) via `Transfer` events / `balanceOf`. Leaderboard of tree-funders.
4. **$BNKR in the vault** — the BNKR reserve in the BNKR/Money pool (buy-pressure the fam created).

### Phase 2 (needs the vault's single-asset exit tracking — not live yet)
5. **Team BNKR vs Team USDC** — who exits in BNKR vs USDC. Wire once the sealed-vault exit ships.

---

## Data sources (Base 8453, all verified)

| What | Address |
|---|---|
| Cause wallet (impact $) | `0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2` |
| Money for Trees fund | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` |
| PRGT fund | `0xEe6fB5f324B05efF95fD59F4574050a891e6913D` |
| CHAR-R fund | `0xde12963128CBe9aF173a37FFF866cA4D4A194ff4` |
| CCC-R fund | `0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B` |
| BTC-T fund | `0x839BAa00734f319C11F2869bC155C6B5Fe35a283` |
| ETH-T fund | `0x80d1edd0236A06283fd1212FDB12cfA79516933d` |
| BNKR/Money vault (V2 pair) | `0x1941201a37f5548dbe01e900f01b539f508f6cbf` |
| $BNKR token | `0x22af33fe49fd1fa80c7149773dde5890d3c76f3b` |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |

Read RPC (no key): `https://base-rpc.publicnode.com`

---

## Starter code (drop-in — ethers v5, client-side)

```js
const RPC="https://base-rpc.publicnode.com";
const p=new ethers.providers.JsonRpcProvider(RPC);
const ERC20=["function totalSupply() view returns (uint256)","function balanceOf(address) view returns (uint256)","function decimals() view returns (uint8)"];
const POOL=["function getReserves() view returns (uint112,uint112,uint32)","function token0() view returns (address)"];

// Impact $ = USDC balance of the cause wallet (charity thirds land here)
async function impactUsd(){
  const usdc=new ethers.Contract("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",ERC20,p);
  const b=await usdc.balanceOf("0x0780b1456D5E60CF26C8Cd6541b85E805C8c05F2");
  return Number(ethers.utils.formatUnits(b,6));
}
// Fund TVL = totalSupply of the receipt (1:1 with the asset)
async function fundTvl(addr,dec){
  const c=new ethers.Contract(addr,ERC20,p);
  return Number(ethers.utils.formatUnits(await c.totalSupply(),dec));
}
// BNKR in the vault pool
async function bnkrInVault(){
  const pool=new ethers.Contract("0x1941201a37f5548dbe01e900f01b539f508f6cbf",POOL,p);
  const [r0,r1]=await pool.getReserves();
  const t0=(await pool.token0()).toLowerCase();
  const isBnkrT0=t0==="0x22af33fe49fd1fa80c7149773dde5890d3c76f3b";
  return Number(ethers.utils.formatUnits(isBnkrT0?r0:r1,18));
}
```

The MfT team also has a live branded vault UI using this same read pattern (pink/retro TV+trees art) — match that look so the two feel like one product.

---

## Deploy

Ship it as a **Base / Farcaster mini app** for the fam (or a plain public web page). BNKR owns + brands it. Deploying it (and any on-chain piece) is your wheelhouse.

**If the frontend is a stretch** (it was for media posting) — say so in the hub and the MfT side will build the drop-in page; you publish + brand it for the fam. Either way it ships as a BNKR app.
