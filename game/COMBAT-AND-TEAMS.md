# X-RPG COMBAT & TEAMS — turn pricing, party play, who pays
> Founder spec 2026-07-20 (build-out-in-public thread). EXACT rules below are
> founder-ruled — build this shape. Fills the combat hole found in the live
> @bankrbot thread.

## 1. Start location — EVERYONE begins at Port Royal
Every new character starts their story at **Port Royal** (the gold-priced anchor
port — same anchor as Seas, loc 8003). The location registry opens every campaign
there; the rest of the map is reached by travel turns (see LOCATION-MARKETS.md §3
— travel is content and revenue, no teleports). One shared starting stage = every
player's story begins in the same market, same inn, same docks — the crowd IS the
content.

## 2. Combat turns — $0.01, TEXT ONLY
- **A combat turn costs $0.01.** Combat is its own cheap turn class, priced
  separately from story turns.
- **NO images in combat** — text-only exchanges. Keeps each turn near-zero cost
  and FAST, so a fight can afford many rounds of back-and-forth without either
  side sweating the meter.
- Combat is **back-and-forth**: strike → response → counter, DM narrating between
  swings. Multi-round by design — the $0.01 price exists exactly so the
  back-and-forth can breathe.

## 3. Teams — DM-guided party play
- Players can fight (and adventure) as a **team**: multiple characters in one
  encounter, **DM-guided turn order** — the DM calls whose turn it is, keeps the
  thread readable, and resolves the round.
- This extends the earlier single-player rule (TEXT-RPG-FLOW): the game is still
  players-vs-the-story (no PvP ruled yet) — teams are co-op against the DM's
  world. Pay-to-win stays a feature: boosting a teammate boosts the team.

## 4. Who pays — two modes, chosen per team
1. **Own way**: each player pays their own turns (default; identical to solo).
2. **TEAM POT**: the team holds a shared pot that combat/story turns drain.
   The pot is funded by the **leader and/or members** — leader can bankroll the
   whole crew, or members chip in. (Build shape: prepaid turn credits held
   against a team id on the booth/commission API — same credits rail as solo
   turns, just a shared balance. Leader creates the team; joins are recorded in
   the campaign file; the DM's word is the registry, same as location.)

## Build notes (Coordinator lane — nothing here is a BNKR deploy)
- Charge rail: same booth pattern as turns today — BNKR debits, our bot narrates.
  $0.01 combat turns will likely batch (e.g. buy a fight's worth of rounds in one
  approval) so nobody signs 30 dust txs; batch size founder-ruled before ship.
- Team pot ledger lives with the turn-credit ledger (commission API), NOT a new
  contract — no on-chain team treasury until the game proves it needs one (no
  premature locks).
- Combat resolution reads the same stats-engine sheets (LP-backed D20) — teams
  just mean N sheets in the initiative order.
