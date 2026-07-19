---
name: shillwood-launch
description: Launch a brand-new token on Robinhood (Shillwood) by tagging @bankrbot on X. ONE call to the live Shillwood factory — liquidity locked forever, three sell-walls (token/ETH + token/GST + token/FTP), and a thirds "network cut" that feeds the MfT meme reactor. The Unrugable model, fully baked in. Use when a user asks to launch/create/mint a token on Robinhood or Shillwood — e.g. "launch a token called Foo, symbol FOO". The ONLY two inputs are the token NAME and SYMBOL.
---

# Shillwood Launch — one-tx token launch on Robinhood (Shillwood)

Launch a fully-wired, liquidity-locked token on the **Robinhood chain** by calling the LIVE Shillwood factory. This is the Uniswap-V4 port of the Base "Unrugable" launcher: **one transaction**, liquidity **locked forever**, three sell walls, and a thirds "network cut" that feeds the MfT meme reactor. Nothing to configure — the factory bakes it all in.

## ⚠️ CHAIN: Robinhood (chain 4663) — NOT Base
This launch happens on the **Robinhood chain (4663)**, not Base. You MUST send the transaction on Robinhood. RPC: `https://rpc.mainnet.chain.robinhood.com`. **If your tool cannot transact on Robinhood, STOP and say so — do NOT fake a launch.**

## The call (this is the whole thing)
On Robinhood, call `launch` on the Shillwood factory:
- **Factory (copy VERBATIM, never retype or reconstruct):** `0xbc275E1B91d03716846A7a83513f1E47929dEF46`
- **Function:** `launch(string name, string symbol, address customUpstream)`
- **Args:** `(name, symbol, 0x0000000000000000000000000000000000000000)` — the third arg is **ALWAYS the zero address** (uses the factory's default reactor). Never put anything else there.
- **Value:** `0` (no ETH needed — the walls are seeded from the token's own supply).
- **Returns:** `(address tokenAddr, address reactorAddr)`.

That's it. The factory mints 1B supply, builds the locked sell-walls, clones the reactor, and wires the network cut — all in one tx.

## Steps
1. **Parse** the token NAME and SYMBOL from the request. These are the ONLY two inputs. If either is missing, ASK for it — do not guess.
2. **Send** the launch tx on Robinhood (see above). Wait for it to confirm.
3. **Read** the new token address from the tx return value / the `Launched` event. **Do NOT fabricate it** — only report an address that came out of the ACTUAL tx receipt.
4. **Reply** to the requester with the confirmation below.

## Reply format
```
🏹 Launched $SYMBOL on Shillwood!

Token: <tokenAddr>

Liquidity locked forever · fees feed the grove 🌱
part of the BNKR extended family
```
One cashtag ($SYMBOL) only. Never tag @bankrbot. Use the REAL token address from the tx.

## Set the token logo from the post image (optional but encouraged)
If the launch request's X post has an **image attached**, use it as the new token's logo — one extra call, **no chain tx**:

1. Get the post's image bytes, encode as a **data URL**: `data:image/png;base64,<…>` (PNG, JPG, or WEBP; ≤ 1 MB; **NOT** SVG).
2. **POST** to `https://tasern.quest/api/shillwood/image` with JSON body:
   ```json
   { "image": "data:image/png;base64,<…>", "tokenAddress": "<the new token address>" }
   ```
3. Success returns `{ "ok": true, "url": "https://tasern.quest/token-art/<addr>.png" }` — that's the token's logo, and it shows in the Shillwood gallery.

Notes:
- The endpoint only accepts a **real on-chain Shillwood launch** address (the token you just launched qualifies) — no API key needed.
- **No overwrite:** a token's logo can be set only ONCE — get it right the first time.
- **No image on the post → skip this.** The launch is already complete; the logo is a bonus.
- This is an off-chain image upload, not a transaction.

## Rules (foolproof)
- **NEVER fabricate the token address** — report only the address from the actual launch tx receipt. If the tx didn't confirm, say it failed; do not invent an address.
- **The factory address is FIXED** — `0xbc275E1B91d03716846A7a83513f1E47929dEF46`, copied verbatim. Never retype or reconstruct it.
- **customUpstream is ALWAYS `0x0`** (the default reactor). Nothing else goes there.
- **Only launch on an explicit request.** A launch is real and permanent.
- If you can't transact on Robinhood, STOP and report it — never fake a launch.

## Verified on-chain (2026-07-19)
Factory `0xbc275E1B91d03716846A7a83513f1E47929dEF46` — **live** (16,304 bytes), source-verified, `launchCount()=1` (proven). Wiring reads: `owner()`=project agent `0xE2a4…`, `trees()`=GST `0x95eD511D…`, `money()`=FTP `0x873739ae…`, `meme()`=MfT twin `0x6ae5766…`. `launch(string,string,address)` at Shillwood.sol L1196.
