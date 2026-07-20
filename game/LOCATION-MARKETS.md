# X-RPG LOCATION MARKETS — items, location-keyed LPs, travel-by-text arb
> Founder spec 2026-07-20. Build EXACTLY this shape (game flow > efficiency — the
> weave IS the product). Nothing here deploys until the story playtest passes.

## 1. Items are OUR tokens
Weapons, armor, potions, all gear = **our ERC20 item tokens** (Seas ItemTokenFactory
pattern — one token per item type). When a player buys gear at an inn/shop, that is
an **on-chain purchase of our token** — these are the BNKR transaction calls (BNKR
executes buys; deploys of the tokens/pools stay with the Coordinator). Bought items
land in the character's vault (the NFT's holdings → future stat reads).

## 2. Location-keyed LPs for EVERYTHING
Every story location gets its own **location-keyed LP set** (Seas LocationPool
pattern: custom pools, presence-gated, single-venue per location = arb-proof against
outside bots). Same item trades at DIFFERENT prices in different locations — the
port has cheap fish and dear swords; the mountain hold is the reverse. Geo scarcity
creates trade routes, exactly like Seas.
- Gate: a character can only trade the pools of the location their STORY is at
  (co-location check from the campaign file — the DM's word is the registry).

## 3. Travel by text
Moving between locations = STORY TURNS (paid turns — travel is content and revenue).
No teleports. The journey is playable: encounters on the road, the inn rule and coin
rule apply the whole way.

## 4. The arb membrane — HIGH FEES by design
Location price spreads make arbitrage possible in principle. Pool **fees are set
HIGH deliberately**, so:
- for most players, travel+trade is **just story** — flavor, not finance;
- only genuinely skilled play (good routes, good timing, story luck) clears the
  fee hurdle — and even then **the profit stays IN-GAME** (coin/items/XP in the
  vault; Money is the membrane at the edge, never the rule of the world);
- the high fees themselves are game revenue (they feed the game's pools, not a dev).

## Build order (after story playtest passes)
1. Item token set v1 (a handful: sword/armor/potion tiers) — Coordinator deploys.
2. Location registry in the game state + 2-3 launch locations with LP sets seeded
   from the GameTill's item budget (small, withdrawable until shipped — no
   premature locks, per house rule).
3. Inn-shop cash-out wired to REAL buys (BNKR call or our rail) instead of ledger.
4. Travel encounters + price boards in the DM prompt ("the merchant mentions prices
   are better across the pass...").

## Hard rules carried over
- No free-income mechanisms: every item/coin source is another player's spend or
  the till's recycle leg.
- Fee/venue params founder-ruled before seeding; pools withdrawable until shipped.
- Never describe any of this as investing/yield to players — it is gear, coin, and
  the road.

## 5. CHARACTER COLLECTION (founder 2026-07-20) � dedicated RPG NFTs, BNKR-mintable from X
Start the game with its OWN character NFT collection:
- **We deploy the collection contract** (deploys stay with the Coordinator); **BNKR mints from X** � minting is a contract call on our deployed ERC721, exactly its proven ground (booth pattern: approve if priced + mint(handle/tokenId)).
- **Art = the Seize the Seas sprite library** (D:\grok-sprites: seas/, gear/, items/ � 700+ sprites, FFT-style). Host on tasern.quest, tokenURI points there. Item tokens can reuse gear/item sprites too.
- **Seas porting welcome**: Seas pawns/characters may port into the RPG later � same art family, same world.
- New-character path becomes: "@bankrbot mint me a tasern adventurer" ? BNKR mints from our collection ? resolver binds it ? stat-vault/loot bag per NFT ? play.
- Mint price: FOUNDER-RULED before deploy (not invented here). Collection deploys AFTER the story playtest with the rest of the build order.
