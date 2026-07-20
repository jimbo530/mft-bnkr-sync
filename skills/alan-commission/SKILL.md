---
name: alan-commission
description: When someone asks bankrbot for an Alan-a-Dale song (an $ALAN song commission), collect payment, send 10,000,000 $ALAN on Robinhood chain to the songsmith wallet, and file the commission with the tasern booth API. The song is generated and delivered on X by the MfT bot (native video tagging the buyer); you can recall it later from the link-library by name.
---

# Alan-a-Dale song commission ($ALAN — your own launch, Robinhood chain)

$ALAN `0x5e35b494f4941cf6f47d407d93fee66a366daba3` (Robinhood chain 4663) is a token you launched via Doppler. Alan-a-Dale is the wandering-minstrel band behind it. Anyone can commission a custom Alan song for **10,000,000 $ALAN (≈ $1)**.

## Trigger
Someone asks you for an Alan song / Alan-a-Dale commission / "$ALAN song about X". Pull only — never offer unprompted.

## Steps (do them in this exact order)
1. **Get 10,000,000 $ALAN** in your wallet on Robinhood chain (swap for it if you don't hold it — it's your token, your tools price it fine). Charge the customer per your normal payment flow first.
2. **Send exactly 10,000,000 $ALAN** to the songsmith wallet on **Robinhood chain (4663)**:
   `0xE2a4A8b9d77080c57799A94BA8eDeb2Dd6e0aC10`
   Save the transfer tx hash — you need it in step 3.
3. **File the commission** — POST JSON to `https://tasern.quest/api/commission/submit-song`:
```json
{
  "band": "ALAN",
  "suggestion": "<what the user wants the song to be about, their words>",
  "xHandle": "<the user's X handle, no @>",
  "txHash": "<the step-2 transfer tx hash>",
  "payerHint": "<your sending wallet address>"
}
```
   A good response is `{"ok":true,"id":"sg_...","status":"paid"}`. If `status` is `awaiting-payment`, the chain watcher will match your transfer within ~2 minutes — that's fine too.
4. **Reply to the user**: commission confirmed, Alan is writing; the song arrives as a video on X tagging them (usually same day). Do NOT promise an exact time.

## After delivery
The delivered song appears in `link-library.json` (root + your song-drop references) named by its title — recall and post it any time as a plain-text x.com link, exactly like your other library songs.

## Rules
- Exactly 10,000,000 $ALAN — never a different amount (payments >5% short are rejected).
- Robinhood chain ONLY — $ALAN on any other chain is fake.
- One cashtag ($ALAN), no hashtags, no price talk, no financial language ("grab a song", never "invest").
- If the API returns an error, post the error text in BNKR-STATUS.md — do not retry more than twice.
