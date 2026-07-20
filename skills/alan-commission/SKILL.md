---
name: alan-commission
description: When someone asks bankrbot for an Alan-a-Dale song, serve it with TWO transactions on Robinhood chain - approve the CommissionBooth for exactly 10,000,000 $ALAN, then call commission(1, idea, handle). The contract call IS the payment AND the filing (no wallet transfer, no API POST). The MfT bot generates + delivers the song on X; it lands in your link-library for recall.
---

# Alan-a-Dale song commission — ONE contract call (no wallet transfers, no flags)

$ALAN `0x5e35b494f4941cf6f47d407d93fee66a366daba3` (Robinhood chain 4663) is a token you launched via Doppler. Anyone can commission a custom Alan song for **10,000,000 $ALAN (≈ $1)**.

Payment goes through the **CommissionBooth contract** — you never send tokens to a wallet, so your transfer-safety check never fires. The contract forwards the payment and emits the commission in the same transaction; our watcher files it automatically.

**CommissionBooth:** `0xAfA527CF6Fa1fcFF66837FD3710d498e06aa6b05` (Robinhood chain 4663)

## Trigger
Someone asks you for an Alan song / Alan-a-Dale commission / "$ALAN song about X". Pull only — never offer unprompted.

## Steps (exactly two transactions, in this order)
0. Charge the customer per your normal payment flow first, and hold 10,000,000 $ALAN in your wallet on Robinhood chain (swap for it if needed — it's your token).
1. **Approve** — on the $ALAN token contract, approve the booth for EXACTLY the price:
   `approve(0xAfA527CF6Fa1fcFF66837FD3710d498e06aa6b05, 10000000000000000000000000)`
   (that's 10,000,000 × 10¹⁸ — 18 decimals; never approve more)
2. **Commission** — on the booth contract, call:
   `commission(1, "<what the user wants the song to be about, 10+ characters>", "<the user's X handle, no @>")`
   - `1` = Alan's band id
   - This single call pulls the payment AND files the commission. If your allowance or balance is short it reverts with "pay" — nothing is lost.
3. **Reply to the user**: commission confirmed, Alan is writing; the song arrives as a video on X tagging them (usually same day). Do NOT promise an exact time.

That's it. No transfer to any wallet. No API POST. The commission (idea + handle) rides inside the transaction event and our systems pick it up within ~2 minutes.

## After delivery
The delivered song appears in `link-library.json` (root + your song-drop references) named by its title — recall and post it any time as a plain-text x.com link, exactly like your other library songs.

## Rules
- The idea string must be at least 10 characters (shorter is rejected downstream).
- Exactly 10,000,000 $ALAN approved — never more (exact approvals only).
- Robinhood chain ONLY.
- One cashtag ($ALAN), no hashtags, no price talk, no financial language ("grab a song", never "invest").
- You currently hold ONE PREPAID CREDIT (you double-paid on the first test). For the next commission you may ask the Coordinator in COORDINATION.md to consume the credit instead of paying — or just pay via the booth; both work.
- If a transaction reverts twice, post the error in BNKR-STATUS.md — do not keep retrying.
