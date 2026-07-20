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

## 6. THE NORTH STAR (founder 2026-07-20) — ALL of Seas, played by text on X
The text RPG is the X-interface to the whole Seize the Seas world. Port every Seas
mechanic into play-by-text as it becomes practical:
- **WORK JOBS assigned from X** — "work for the mayor": guard shifts, attest-keeper
  duties, wage-water jobs; jobs pay coin/water exactly like Seas (mayor-job → gold
  prizes is the proven crank; the achievement ladders + prize pools already exist).
- Rations/everyone-eats, hiring halls, boats + crafting lines, location pools,
  caravans/travel bands, town/ship tokens — same systems, text-first surface.
- The crew NFTs are the SHARED cast: they play the RPG on X and crew ships in Seas.
Build order stays: story playtest first, then jobs (mayor work), then the rest.

## THE TAVERN DRINK (founder 2026-07-20)
100 GOLD in-run (coin sink, at a tavern in-story only) or 1 USDC via the game booth
(band 2 "DRINK" on 0xb6733F8E...) — either way the drink MAKES WATER queued for the
buyer's character NFT (water-credits queue on the commission API; the converter rail
delivers it). Drinks are the love-your-character button.

## Hard rules carried over
- No free-income mechanisms: every item/coin source is another player's spend or
  the till's recycle leg.
- Fee/venue params founder-ruled before seeding; pools withdrawable until shipped.
- Never describe any of this as investing/yield to players — it is gear, coin, and
  the road.

## 5. CHARACTER COLLECTION (founder 2026-07-20) - dedicated RPG NFTs, BNKR-mintable from X
Start the game with its OWN character NFT collection:
- **We deploy the collection contract** (deploys stay with the Coordinator); **BNKR mints from X** - minting is a contract call on our deployed ERC721, exactly its proven ground (booth pattern: approve if priced + mint(handle/tokenId)).
- **Art = the Seize the Seas sprite library** (D:\grok-sprites: seas/, gear/, items/ - 700+ sprites, FFT-style). Host on tasern.quest, tokenURI points there. Item tokens can reuse gear/item sprites too.
- **Seas porting welcome**: Seas pawns/characters may port into the RPG later - same art family, same world.
- New-character path becomes: "@bankrbot mint me a tasern adventurer" -> BNKR mints from our collection -> resolver binds it -> stat-vault/loot bag per NFT -> play.
- **NAMES (founder 2026-07-20): players NAME their character at mint, and no two names can ever be the same** — unique-name enforcement exactly like the Acorn collection (contract-level require on a name registry, case-insensitive). The name is the character's identity in story, on the NFT, and in the library of legends.
- **Mint price RULED (founder 2026-07-20): 1 USDC.** And the mint dollar is NOT plain revenue — **WATER IGNITION**: each mint's 1 USDC is converted (backend rail: USDC -> water tokens) and seeded AT the character NFT, so **every crew member is born with MfT flow to the people who play it** (Seas pawn-flow-ignition pattern, ported). **Levels are EARNED in play** — XP from the game, never sold (stat BOOSTS remain a separate purchasable per TEXT-RPG-FLOW 3b; levels themselves are play-only).
- Collection deploys once sprites are approved (blocked on OpenAI billing top-up for candidate generation).
