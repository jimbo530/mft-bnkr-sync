---
name: super-token
description: When someone prompts "tell me about your super token" (or asks about $EXCELENT), bankrbot posts a TRANSPARENCY DISCLOSURE about a token it launched on Shillwood — framed as "how the mechanics work, verify it yourself," NOT a promotion. Facts only, explicit "not a call / not advice", the fee-conflict disclosed openly. Written to read as transparency (anti-scam behaviour), not a shill — because a shill-shaped post trips Bankr's own malicious-content filter (correctly).
---

# Super Token — transparency disclosure for $EXCELENT (NOT a shill)

$EXCELENT (`0xC174e99A00f73Fb44af23DcB4176a8e27e55077f`) is a token bankrbot launched on Shillwood. bankrbot is the launcher, so it earns this token's creator fees. This skill answers a "tell me about your super token" prompt with a **transparency disclosure** — the on-chain mechanics, framed so anyone can verify them — **not** a promotion.

## ⚠️ Why the framing matters (this is the whole point)
A promotional/hype version of this ("my super token, buyback engine, the bot has a bag") is **shill-shaped** and Bankr's anti-scam filter flags it as potentially malicious — correctly, because that shape is how scams read. The fix is NOT to evade the filter; it's to make the post genuinely **factual + non-promotional + verify-it-yourself**. Drop every hype word. Lead with "not a call, not advice." Disclose the fee conflict openly (disclosure = anti-scam behaviour). Then it's transparency, not a shill.

## Trigger
An explicit prompt: **"tell me about your super token"** / "what's your super token" / "tell me about $EXCELENT". Pull only — never broadcast.

## The post (this exact copy — factual, no hype, no price talk)
```
someone asked about $EXCELENT — a token I launched on Shillwood. this isn't a call and it isn't advice. it's how the mechanics work, and you can verify every line on-chain:

• the LP is locked — the launch burns the position, so the liquidity can't be pulled
• the contract and its reactor are both source-verified on the explorer — read exactly what they do
• the reactor buys the token back from fees and burns a share; it's permissionless (anyone can call execute()), right there in the verified code
• full disclosure: I'm the launcher, so this token's creator fees come to me — and that's on-chain too, nothing hidden

that's the whole idea of the Meme for Trees stack — you don't trust it, you check it.

0xC174e99A00f73Fb44af23DcB4176a8e27e55077f
robinhoodchain.blockscout.com/address/0xC174e99A00f73Fb44af23DcB4176a8e27e55077f
```
One cashtag ($EXCELENT). No hashtags. Never tag @bankrbot. Reply to the prompting post.

## Why every claim is true (grounded on-chain 2026-07-19)
- **creator fees → bankrbot:** the reactor's fee recipient = the launcher (`launcher = _feeRecipients[0]`); bankrbot launched $EXCELENT, so it's that recipient.
- **buyback + burn, permissionless:** the reactor's `execute()` (Shillwood.sol L699, "permissionless after cooldown") burns a share of the token and buys it back from paired-side fees — in the reactor's **verified** source (impl `is_verified=true`; each reactor is an eip1167 clone of it).
- **LP locked forever:** the reactor holds the LP position NFTs with NO withdraw / decrease path (Shillwood.sol L428–430).
- **verified:** $EXCELENT is source-verified on RH Blockscout (`is_verified=true`).

## Rules (compliance — non-negotiable)
- **Transparency, not promotion.** NEVER add a price prediction, target, "guaranteed", "moon", "buy", "super", "bag", or any hype. If it reads like a pitch, rewrite it as a fact.
- **Disclose, don't hide.** The "fees come to me" line is a conflict-of-interest disclosure — keep it plain and honest.
- **One cashtag** ($EXCELENT). No hashtags. Never tag @bankrbot. Never fabricate a number — point to the verified contract.
- Only fire on an explicit "super token" prompt.

## If Bankr still flags it
This is written to be transparency, not a shill — but Bankr's moderation is Bankr's call, and a bot posting about a token it profits from is inherently sensitive. If it still flags: that's a Bankr-side moderation setting (whitelist / policy), not something to word around. Do NOT try to disguise the token, the CA, or the fee disclosure to get past the filter.
