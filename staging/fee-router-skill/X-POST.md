# X post — Fee Router skill announcement

**Status: DRAFT — do not post yet.**
Post only after BOTH:
1. The skill link resolves publicly (merged to the Bankr skills repo, or wherever
   it lands — update the link below to the real URL first).
2. Guardian review (all public-facing content goes through the bus first, per
   marketing-compliance rules).

---

## The post

new community skill: Fee Router

an N-way fee splitter for anyone routing revenue onchain. set your recipients and their basis-point shares once at deploy — after that there is no admin key, no owner, no pause switch. it can only ever pay the people you named.

handles native ETH and any ERC20, payouts are pull-based and anyone can trigger them. deploys in one normal transaction through our DeployerFactory on Base, so agent wallets that can't send creation transactions can still ship one.

we built it for our game economy — ship taxes flowing upstream, prize pool splits — but fee routing is fee routing.

@bankrbot is this helpful for the whole community, or just our $MfT stack?

source + worked examples: https://github.com/BankrBot/skills/tree/main/fee-router

---

## Compliance checklist (verified against the rules)

- [x] Tags @bankrbot
- [x] Asks the founder's question: community-wide vs our stack
- [x] NO hashtags
- [x] Exactly ONE cashtag: $MfT (all other names written plain: Base, ETH, ERC20)
- [x] Keywords woven into sentences (fee splitter, routing revenue onchain,
      Base, community skill) — no keyword stuffing
- [x] Every claim verifiable:
      - "no admin key, no owner, no pause switch" → FeeSplitter.sol ABI (only
        mutating fns are release/releaseAll; 50-check suite in the skill repo)
      - "native ETH and any ERC20, pull-based, anyone can trigger" → source + tests
      - "deploys in one normal transaction through our DeployerFactory on Base"
        → factory live at 0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D (Basescan)
      - "ship taxes… prize pool splits" → the live game tax split runs on-chain
        (TributeSplitter 0x6B901D2a329Edb41D5Da5f961079e10e6345a413)
- [x] No price talk, no yield promises, no "invest/reinvest" language
- [x] No competitor mentions, no gas mentions
- [x] One token per post (MfT only)

## Notes for the poster

- If quote-posting or threading, keep the reply plain — the single-cashtag rule
  applies per post.
- If the skill ends up hosted somewhere other than BankrBot/skills, swap the
  link BEFORE posting and re-check it resolves.
