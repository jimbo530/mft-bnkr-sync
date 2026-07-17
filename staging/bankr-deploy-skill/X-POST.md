# X-POST — Deploy Any Contract skill (community skill #1)

**Status:** HELD for (a) founder OK, (b) Guardian review, (c) the repo link resolving once the skill
is published to BankrBot/skills. Posted from @MemeForTrees.

**Compliance:** no hashtags · one cashtag ($MfT) · every claim chain/repo-verifiable · no price/invest
language · tags @bankrbot + asks community-vs-$MfT per the playbook.

---

new community skill: Deploy Any Contract

bankr agents can launch tokens, but the transaction tooling needs a `to` field — so it can never send
a contract-creation transaction. that quietly means no custom contracts: no splitters, no vaults, no
bridges, no game logic. just tokens.

so we built a DeployerFactory. deployment becomes a normal call — send your creation bytecode to the
factory, it runs CREATE, and the new address comes back in an event. anything you could put in a
creation tx now ships from a wallet that can only send normal txs. live and verified on Base, free to
use right now.

we needed it to unblock our own $MfT stack, but honestly it's just a missing primitive.

@bankrbot is this helpful for the whole community, or just us?

source + a worked example (real bytecode): https://github.com/BankrBot/skills/tree/main/deploy-any-contract
factory (verify it yourself): https://basescan.org/address/0xCF4357aFdC26fa028e77291CE2F97C9dAF93F75D
