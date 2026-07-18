# Impact Network — Contract List

For the impact leaderboards + the verification sweep. 361 contracts across 14 categories. Source: `bankr-impact-network.csv`.

## Impact Vault (25)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| Money / mftUSD | MONEY | `0xe3dd3881477c20C17Df080cEec0C1bD0C065A072` | ERC20 | CharityFund clone; USDC deposit receipt; 1 MONEY = 0.01 USDC; current live vault |
| PRGT (CharityFund receipt) | PRGT | `0xEe6fB5f324B05efF95fD59F4574050a891e6913D` | ERC20 | CharityFund receipt; $1 peg; 6 dec |
| CHAR Retirement Fund | CHAR-R | `0xde12963128CBe9aF173a37FFF866cA4D4A194ff4` | ERC20 | yield 1/3 buys CHAR then retires + 1/3 ReactorPrime + 1/3 holders; CHAR = 1 t CO2e; 6 dec  |
| CCC Retirement Fund | CCC-R | `0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B` | ERC20 | yield 1/3 buys CCC then retires + 1/3 ReactorPrime + 1/3 holders; CCC = 1 lb CO2e; 6 dec ( |
| CHAR-R RetirementVault (no-circ) | CHAR-RV | `0xD4110DA32E769cebc0Fe43B98BF8081cbae5AF2e` | vault | Non-circulation vault (no decimals() on-chain; USDC custody = 6 dec); deposit(amount displ |
| CCC-R RetirementVault (no-circ) | CCC-RV | `0xdD7E7596BD1F89D0d7f529A03EA5307342824b6A` | vault | Non-circulation vault (no decimals() on-chain; USDC custody = 6 dec) |
| BTC for Trees | BTC-T | `0x839BAa00734f319C11F2869bC155C6B5Fe35a283` | ERC20 | AssetTreeFund; cbBTC in 1:1; 8 dec; yield 1/3 raw cbBTC + 1/3 ReactorPrime + 1/3 holders |
| ETH for Trees | ETH-T | `0x80d1edd0236A06283fd1212FDB12cfA79516933d` | ERC20 | AssetTreeFund; wETH in 1:1; same split as BTC-T |
| CHAR-W (CHAR water) | CHAR-W | `0x6b477f11e437b3513dfcbf5085e6e0266fe1c5f1` | ERC20 | CHAR water WaterV2 |
| PRGT Vault (USDC/PRGT LP) | PRGT-V | `0x130fDBa1F16bC8b2d88FCc3A34583807eeA6656B` | ERC20 | USDC/PRGT LP vault |
| CALM Vault v2 (cbBTC exit) | CALM-V2 | `0x9323802796852daac898193394f86000bbd0b07d` | ERC20 | cbBTC-only exits; live (v1 drained+dropped) |
| Holm Kids Vault | HOLM-KV | `0xdA87106869b755Bf3D4292B83EaEA023eB92a74F` | ERC20 | Partner-owned kids vault |
| MayorVault / Water-Flow Vault | MAYOR-V | `0x44c504Ce08635536635f153B6Ae5d9D6d8b3131F` | ERC20 | Guard-the-Port civic job vault |
| Water-Level Vault (diffuse) | WATER-LV | `0x9789c459f08896148E8D1a8b2B7a4Bb95FAAf8B2` | ERC20 | Generic tavern/level water engine |
| EBM Community Vault | EBM-V | `0xdd47bdDD35866735ac79f9F3F8d4f0513555Ed95` | ERC20 | Community LP vault backing EBM band walls |
| RISH Community Vault | RISH-V | `0x131bd427935980bbE43c30c3d0aF49e33c0E98E1` | ERC20 | Community LP vault backing RISH band walls |
| BONGO Community Vault | BONGO-V | `0x3aF2d7CCc05FdF3bC6Be14d1F159826b0f31198f` | ERC20 | Community LP vault backing BONGO band walls |
| DGT Community Vault | DGT-V | `0x43ebB722e17dBe698AA70A55Cb428b171A5da367` | ERC20 | Community LP vault backing DGT band walls |
| Holm Kids Vault Impl (CommunityLPVaultV3) | CLPV3-IMPL | `0x3bB5f84c797e5932656AB66830bD901637DaE318` | ERC20 | Vault implementation contract |
| HOLM (partner token) | HOLM | `0x4D526ec9c885469aEe508585D99E77daeF09Da35` | ERC20 | External partner token (Holm Kids) |
| Feed The People | FTP | `0x873739aeD7b49f005965377b5645914b1D78Ccd3` | ERC20 | RH charity deposit token; 1:1 USDG peg; Morpho vault; ops+meme-reactor IMMUTABLE |
| Grow Some Trees | GST | `0x95eD511Dbdd7b52795e1F515314bE8d888Ea4F3F` | ERC20 | RH charity deposit token; 1:1 USDG peg; Morpho vault; yield to trees |
| FTP Peg Community Vault v2 | FTP-PEG-V2 | `0x7562593D18e47aA40EfCd04468b3D5222A40bbf3` | ERC20 | LIVE (v1 superseded+dropped) |
| BURGERS Community Vault v2 | FTP-BURG-V2 | `0x261F76D20983f299962b1481d7968d2F27b79BB1` | ERC20 | LIVE (v1 superseded+dropped) |
| FTP Holding Vault | FTP-HOLD | `0xA194450EE2Bb6663B5DFd1A2277BEed8527d6D64` | ERC20 | Hold FTP directly |

## Band Token (14)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| Elves of Ballinmoore | EBM | `0xF113fe2A0E1181A21fA97B1F52ff232140B7692d` | ERC20 | 1B fixed; 1% V3 walls EGP + Money; sealed reactor |
| Digerie Dude (band) | DD | `0xa77D43A33AD5C50E27fCf27101c9E6aEfE066CE3` | ERC20 | 1B fixed; walls Money + DDD; DISTINCT from Unrugable DD 0x3EeCC1c0 |
| Myco (band) | MYCO | `0x36A01B05cf86a170490E3Ba4981eFd12B559a5a3` | ERC20 | 1B fixed; walls Money + DHG; DISTINCT from Unrugable Myco 0xD377fc |
| Moon Rasta (band) | MR | `0x8d669b539C7801c1271BC484Bdd8a6084b7788e7` | ERC20 | 1B fixed; walls Money + IGS; DISTINCT from money-arb MR 0x9265Bf |
| Jony Sings | JS | `0x16Ba11AeDA2Da0eb2C64Ff7d0e74884033Ef2C65` | ERC20 | 1B fixed; walls Money + EGP |
| Natilie Nightclub | NN | `0x2beBaBdF57597F3ce75BDC75FAD3C40C4A9Fc8cc` | ERC20 | 1B fixed; walls Money + EGP |
| The Damned Good Time Orchestra | DGT | `0x52414B7cD2FA723E1c8f9295EB29F16d15aA7BB9` | ERC20 | 1B fixed; walls Money + IGS; sealed reactor |
| Bongo | BONGO | `0x85Dd5183D203CcE70b88234D31f075774AcCC453` | ERC20 | 1B fixed; walls Money + BTN (8 dec); sealed reactor |
| Ricky Bobbie | RICKY | `0x95286F2cce3C2de48EB75bB4E2Ec004429F18E53` | ERC20 | 1B fixed; wall Money; 2nd wall RICKY/PKT |
| Hammer Tone | HT | `0x7B105F45ddaA689AfDa5606628761a9Fb2dCd826` | ERC20 | 1B fixed; walls Money + LGP |
| War Machine | WM | `0x6f45F5cE7027745b1Ab11D5493F187960D00FCfc` | ERC20 | 1B fixed; walls Money + OGC |
| Biggins Mcjammin | BIGGINS | `0x7C596a0d594D670ffB256bBfbB5379fC8Cf7d62B` | ERC20 | 1B fixed; wall Money; 2nd wall BIGGINS/BTN |
| Jasmine the Tiger | JASMINE | `0x3a952eFa41501c0463Cf8Af9f821f8F549f47Edf` | ERC20 | 1B fixed; wall Money; 2nd wall JASMINE/PKT |
| Rish | RISH | `0x31c600871603bab5d855463E03c6d0a9eB661D26` | ERC20 | 1B fixed; walls Money + PKT; sealed reactor |

## Nation Coin (17)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| Egyptian Pound | EGP | `0xc1ba76771bbf0dd841347630e57c793f9d5accee` | ERC20 | DEX stat anchor; quote for JS/NN/EBM walls; ChainPort-bridged (no twin-vault Polygon row) |
| Old Gold Coin | OGC | `0xa294df3bb33197a579756fc530c0504b2a75af32` | ERC20 | paired with WM band wall |
| Lost Gold Piece | LGP | `0x72b92244e8ee724f12bcc02b3ce158121e0e3666` | ERC20 | paired with HT band wall |
| Pirate King Token | PKT | `0x9157359c9a1cdbad85414069ddc29a63c55cfec4` | ERC20 | paired with RISH/RICKY/JASMINE walls |
| Dungeon Dollar | DDD | `0x87cd3a19a30b7f714dd0d6020dab8e9ebe4fe8c4` | ERC20 | paired with DD band wall |
| Iron Gold Standard | IGS | `0xea320718a64854f0547a1213a3043678ea5755bb` | ERC20 | 8 decimals; paired with DGT/MR walls |
| Button | BTN | `0xe11c804cd5ef617302c18c946370fe245dc43c5c` | ERC20 | 8 decimals; paired with BONGO/BIGGINS walls |
| Dragoon Honor Gold | DHG | `0x25cfe0a4dc89c6d1ad3984d30b6f8365bcb4a75c` | ERC20 | 8 decimals; paired with MYCO band wall |
| Port Royal 25 (Base twin) | PR25 | `0xE6B95cc9307BEB5d37fe2e0891d680cb9C9aac6b` | ERC20 | Base twin; Polygon twin 0x72e4327f592e9cb09d5730a55d1d68de144af53c |
| Dungeon Dollar (Polygon twin) | DDD | `0x4bf82cf0d6b2afc87367052b793097153c859d38` | ERC20 | Polygon twin; Base twin 0x87CD3a19a30b7f714dd0D6020dAb8e9EBE4fe8C4 |
| Old Gold Coin (Polygon twin) | OGC | `0xccf37622e6b72352e7b410481dd4913563038b7c` | ERC20 | Polygon twin; Base twin 0xa294dF3BB33197a579756Fc530c0504b2a75aF32 |
| Pirate King Token (Polygon twin) | PKT | `0x8a088dceecbcf457762eb7c66f78fff27dc0c04a` | ERC20 | Polygon twin; Base twin 0x9157359C9a1CDbAD85414069DDc29a63C55cfEc4 |
| Button (Polygon twin) | BTN | `0xd7c584d40216576f1d8651eab8bef9de69497666` | ERC20 | Polygon twin; 8 dec; Base twin 0xe11C804CD5eF617302c18c946370fE245DC43c5C |
| Iron Gold Standard (Polygon twin) | IGS | `0xe302672798d12e7f68c783db2c2d5e6b48ccf3ce` | ERC20 | Polygon twin; 8 dec; Base twin 0xea320718a64854f0547A1213A3043678ea5755bB |
| Dragoon Honor Gold (Polygon twin) | DHG | `0x75c0a194cd8b4f01d5ed58be5b7c5b61a9c69d0a` | ERC20 | Polygon twin; 8 dec; Base twin 0x25cFE0a4dC89c6D1Ad3984D30B6F8365bCb4a75C |
| Lost Gold Piece (Polygon twin) | LGP | `0xddc330761761751e005333208889bfe36c6e6760` | ERC20 | Polygon twin; Base twin 0x72b92244E8eE724F12bcC02B3CE158121e0E3666 |
| Port Royal 25 (Polygon twin) | PR25 | `0x72e4327f592e9cb09d5730a55d1d68de144af53c` | ERC20 | Polygon twin; Base twin 0xE6B95cc9307BEB5d37fe2e0891d680cb9C9aac6b |

## Ecosystem Token (27)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| POOP (Baseling yield) | POOP | `0x126555aecBAC290b25644e4b7f29c016aE95f4dc` | ERC20 | Baseling gameplay yield token |
| BURGERS (Base) | BURGERS | `0x06A05043eb2C1691b19c2C13219dB9212269dDc5` | ERC20 | Baseling food token / CON stat |
| TGN (Base) | TGN | `0xD75dfa972C6136f1c594Fec1945302f885E1ab29` | ERC20 | Base ecosystem token / CHA stat |
| BRETT | BRETT | `0x532f27101965dd16442E59d40670FaF5eBB142E4` | ERC20 | Baseling partner/3rd-party pool token |
| AZUSD | AZUSD | `0x3595ca37596D5895B70EFAB592ac315D5B9809B2` | ERC20 | Baseling food token |
| BUSTER | BUSTER | `0xBFC5cD421bBC91A2Ca976C4AB1754748634b7D41` | ERC20 | Baseling food-family token |
| FUN | FUN | `0x16EE7ecAc70d1028E7712751E2Ee6BA808a7dd92` | ERC20 | Baseling pool token |
| PIZZA | PIZZA | `0x84BF55C117bc97323d332f08782ADBCAf3B15468` | ERC20 | Baseling food token |
| WALL | WALL | `0x89B689462Cd57f14d5d1a714d102B3EE5F0dCEF2` | ERC20 | Meme token with MV4 LP |
| BB (Base) | BB | `0xf967bf3dccF8b6826F82de1781C98e61Bda3b106` | ERC20 | BB ecosystem token |
| EB (Base) | EB | `0x17a176Ab2379b86F1E65D79b03bD8c75981244D8` | ERC20 | EB ecosystem token |
| ILM (partner ref) | ILM | `0x885f90b0fcc10AD6d3257Df851eda4c78f38c5A4` | ERC20 | I Like Money partner token in reactor-map; DISTINCT from Unrugable ILM 0x324980EE |
| RT (partner ref) | RT | `0x3FE916c7CB6354eAF8ee49427380740bEe2b061a` | ERC20 | Partner token in reactor-map; DISTINCT from Unrugable Rodeo Toad 0x5d565fE4 |
| SC (partner) | SC | `0xB7C5b050E0545b5b2b3015111E4f197641F0D3Fa` | ERC20 | Partner token in reactor-map |
| Flowers (Unrugable) | Flwr | `0x5bF510BFc635598D77b6Ac5fDE45CDa888A0C4c1` | ERC20 | Unrugable launch #8; has reactor + char-reactor |
| Need For Seed (Unrugable) | NFS | `0xb9630280DC93c503aEE06d1Eca8E125fc19AB3c5` | ERC20 | Unrugable launch #10; Baselings NFS token; has reactor + char-reactor |
| Need More BASE (Unrugable) | NMB | `0x64908eF36C85feEA39625d2F653f3bCDDAea5e9b` | ERC20 | Unrugable launch #12 |
| Blue Pill (Unrugable) | BP | `0x33c5e3362A9ddfD453FF655D7DdbC8C2Eff4A062` | ERC20 | Unrugable launch #14 |
| Rodeo Toad (Unrugable) | RT | `0x5d565fE46D285ab3e1e8d7fB6d0B2ecF4ba3B90B` | ERC20 | Unrugable launch #15; DISTINCT from partner RT 0x3FE916c7 |
| Turtle (Unrugable) | Turtle | `0x2999f1Bfa1Bd65Aa908bef41A8BF4d8CB7C370FB` | ERC20 | Unrugable launch #16 |
| Myco (Unrugable) | Myco | `0xD377fcADE46CDA9C7B6Bc5ea6450CA53994b6577` | ERC20 | Unrugable launch #18; DISTINCT from band Myco 0x36A01B05 |
| David Atten BRUH (Unrugable) | BRUH | `0x6743D2E9c06afeC5d2a0bcdec2A53e2af328a10E` | ERC20 | Unrugable launch #21; correct addr (reactor-map 0xE9679341 was stale/dropped) |
| Never Zero (Unrugable) | NZ | `0xCd79F05197F79E0f08D1f4599aA7BBf02EA36098` | ERC20 | Unrugable launch #22 |
| I Like Money (Unrugable) | ILM | `0x324980EE4219d350c0506beff151cd4327bF770B` | ERC20 | Unrugable launch #26; DISTINCT from partner ILM 0x885f90b0 |
| Moon Rosta (Unrugable) | Moon | `0xc42e63F7b0cBd12E7C50941646D6eb539D2DE430` | ERC20 | Unrugable launch #27 |
| Batthew (Unrugable) | Bat | `0xc720FFf033E70E11AE6b80A0Bb88C77911EEBc7D` | ERC20 | Unrugable launch #28 |
| Digerie Dude (Unrugable) | DD | `0x3EeCC1c07d0a8BdEAF495a1300486a376cc959FF` | ERC20 | Unrugable launch #20; DISTINCT from band DD 0xa77D43A3 |

## Carbon Credit (8)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| CHAR (carbon retire) | CHAR | `0x20b048fa035d5763685d695e66adf62c5d9f5055` | ERC20 | WIS stat / carbon retire token (from lp-pairs CHAR/MfT refs) |
| CHAR-W relay | CHARW-RELAY | `0x0f040e4357f375f50a718ad92e948e4c27baa5d7` | reactor | CHAR-W relay contract |
| CCC (Polygon carbon) | CCC | `0x11f98A36aCBD04cA3Aa3a149d402AFFbD5966fe7` | ERC20 | Carbon Countin Club retire token; 16 dec |
| NCT (Nature Carbon Tonne) | NCT | `0xD838290e877E0188a4A44700463419eD96C16107` | ERC20 | Toucan nature carbon tonne |
| BCT (Base Carbon Tonne) | BCT | `0x2F800Db0fdb5223b3C3F354886d907A671414A7f` | ERC20 | Toucan base carbon tonne |
| REGEN | REGEN | `0xDFFFE0c33B4011C4218ACD61e68A62A32EaF9a8B` | ERC20 | Regen Network token (bridged) |
| CRISP-M | CRISP-M | `0xeF6AB48Ef8DFe984FAb0D5C4cD6aFF2e54DFda14` | ERC20 | CRISP carbon partner token |
| LANTERN (partner) | LANTERN | `0x8e87497eC9FD80FC102B33837035f76cf17C3020` | ERC20 | Partner token (Polygon) |

## Game Currency (14)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| GOLD | GOLD | `0x2065d87b3a1facc9a4fe037d7a58bc069f597004` | ERC20 | Seas coin denomination |
| SILVER | SILVER | `0x36cf0cedeee07b14c496f77c61d010268c31e0e9` | ERC20 | Seas coin denomination |
| COPPER | COPPER | `0x0197896c617f20d61e73e06ec8b2a95eef176bee` | ERC20 | Seas coin denomination |
| CHRONO ORB | ORB | `0xdf2Fa41A34744AfF37634500aDF64981a626d657` | ERC20 | Time-skip premium item |
| FISH | FISH | `0x907D043d33A243cd9818d6e2ccd5b3C9ef9905B5` | ERC20 | Seas resource token (live; ground SHELVED) |
| CRAB | CRAB | `0xCc85d908a26bf34E5FdE5957378Fa90C92CD8217` | ERC20 | Seas resource token (live; ground SHELVED) |
| AMETHYST | AMETHYST | `0xc5a9bc41936ef545de210727fedcf8a43aefa95f` | ERC20 | Seas gemstone token |
| PLATINUM | PLATINUM | `0x6722ef27d1854e73269b0abe42290c000d3efdda` | ERC20 | Seas gemstone token |
| EMERALD | EMERALD | `0x3220d7b78f0b3839248e624ed3c7c2c215389063` | ERC20 | Seas gemstone token |
| RUBY | RUBY | `0xe78023fafb55e61dc4d28d13f623e32fe9a3fe6a` | ERC20 | Seas gemstone token |
| DIAMOND | DIAMOND | `0x567c3ea4e2eb7fb0c55523162a248a5a25fd5bb0` | ERC20 | Seas gemstone token |
| GOLD water | GOLDW | `0x18a880f2ede190b1dad8d11f8a22f1b273c16a08` | ERC20 | Gem-water token |
| SILVER water | SILVERW | `0x49f384e64d8fb67ea7cb74067245f6f9fe7c8a52` | ERC20 | Gem-water token |
| COPPER water | COPPERW | `0x7d842e5059e354e27a791f658becceee59febaf5` | ERC20 | Gem-water token |

## Ship Token (4)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| The Black Tide (Orc) | SHIP-BT | `0x8823E5c30a7EC507379e01aeD8F81e0A9Ef787a7` | ERC20 | Seas ship ERC20; crew NFT 0x2E2AB7ae (= distributor) |
| Redrum Raiders (Goblin) | SHIP-RR | `0x17C68b9647846bE4693fB723dDE5cb4fE44DAb2b` | ERC20 | Seas ship ERC20; crew NFT 0x4ECe4919 (= distributor) |
| Harbor Guard (Human) | SHIP-HG | `0xF5307BBa536E3feD11C78F2a7E0b1CDECD4E49F3` | ERC20 | Seas ship ERC20; crew NFT 0x8C1f935F (= distributor) |
| The Verdant Warden (Elf) | SHIP-VW | `0xd5FD3A5B3b90fFa6e06530934eC9343dca0dd2f4` | ERC20 | Seas ship ERC20; crew NFT 0x4FB1502c (= distributor) |

## Reactor (59)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| EBM Band Reactor (sealed) | EBM-R | `0xA01B92024ee8cb18C3527C1453EF904A1e405095` | reactor | Sealed; admin=0x0; EBM LP fees |
| RISH Band Reactor (sealed) | RISH-R | `0x98D55914FB91a740D91cDdfFb9287594442A542a` | reactor | Sealed; admin=0x0; RISH LP fees |
| BONGO Band Reactor (sealed) | BONGO-R | `0xA607F5Ea59D61D7650644E5582e06565d4fea76E` | reactor | Sealed; admin=0x0; BONGO LP fees |
| DGT Band Reactor (sealed) | DGT-R | `0x6ab04d2d9017eEa03E43fED0f4dE5Bf6BFf7200c` | reactor | Sealed; admin=0x0; DGT LP fees |
| ReactorPrimeV3 (MfT terminal) | PRIME | `0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA` | reactor | Upstream MfT terminal; cbBTC/wETH yield endpoint |
| MycoPad Hub (main upstream) | HUB | `0xF5B9Fc40080aAcC262f078eCE374A2268dcdb045` | reactor | Spore/hub; upstream for launched-token reactors |
| BB v5 reactor | BBV5-R | `0x3b31B8c9338ebFE2e737e5dd6361cEf0Bdc431e3` | reactor | spore (current BB) |
| EB v5 reactor | EBV5-R | `0x2e06EB264dB2C7bcD8B9a216827b7D0eF3beACA2` | reactor | spore (current EB) |
| EB relay | EB-RELAY | `0xC28e64551816535d9ef06CE95844F2b5317353bA` | reactor | spore relay |
| BTCband v2 reactor | BTCB2-R | `0x038B87f2Abc1dcE269FF7DE4d3e721b5b57eD8cf` | reactor | spore (current BTCband) |
| ETHband v2 reactor | ETHB2-R | `0xeB02d1137342cD08C1c4bf61C188d86C5253b631` | reactor | spore (current ETHband) |
| BBT reactor | BBT-R | `0x6853679E3240E207031dDddDeaA8d131dEc0EC92` | reactor | spore |
| EBT reactor | EBT-R | `0xFA6823332D2Bc882a62Ceb4029Dde2573709698B` | reactor | spore |
| WALL reactor | WALL-R | `0xBEe606A4Dd8c7027613FA300C517782A14A56490` | reactor | spore |
| MfT-stable reactor | MFTSTB-R | `0x1358e3BeE04Da2b7663802EE8A2A7608c69b7e47` | reactor | spore |
| TGN reactor | TGN-R | `0xc3f09dAEF814177E52B4C04ec2872B564a36989D` | reactor | spore |
| TGN reactor (alt) | TGN-R2 | `0x89Dc8A1fc77E066640C8C035c64FD673EA3F4B3e` | reactor | alt from generate-reactor-data |
| AZUSD reactor | AZUSD-R | `0xD8AFb7caD1f8A3Ddc4E16c1516a94949eb119281` | reactor | chain reactor |
| AZUSD V3 reactor | AZUSDV3-R | `0x6888ef2F92E3073a378f7153548e9C7691c90d23` | reactor | chain reactor (V3) |
| BURGERS reactor (Baselings) | BURG-R2 | `0x2867F1107d3A4767018740e10f0067702a8eC682` | reactor | Baselings-side BURGERS reactor |
| CHAR reactor | CHAR-R2 | `0xc2eBe90fB9bC7897f06DC00666951Fa9a49A397A` | reactor | chain reactor |
| EGP reactor | EGP-R | `0x10A710fced92eB096F796F43BCCFb60884c13819` | reactor | chain reactor |
| NFS reactor | NFS-R | `0x286416cE59B355dEFf1a02d52013d4CBDC11F3bF` | reactor | Baselings NFS reactor |
| NFS reactor (launched-token map) | NFS-R2 | `0x71C28E76E3CD6D457e7639314B114760246cdeAD` | reactor | NFS reactor from reactor-map (token #3 / launch #10) |
| PR25 retirement reactor | PR25-RET | `0x515f63B570674FA5a6722CD01a15dDbb7F2091F5` | reactor | charity-retirement reactor (nfs-burner) |
| PR24 retirement reactor | PR24-RET | `0x2502Bc4a3E64938E26F418Aa04399A31eF2C0c6e` | reactor | charity-retirement reactor; token 0xd84415C9 |
| fJLT-F24 retirement reactor | FJLT-RET | `0xfcf9c71E575DD41b1d750012454cC00836004dEF` | reactor | charity-retirement reactor; token 0xcdb4574a |
| TB01 retirement reactor | TB01-RET | `0xfC276AcD76acBC6a43307678B3Abb1d75E9894a5` | reactor | charity-retirement reactor; token 0xCB2A9777 |
| MEME_BALANCER | MEMEBAL | `0x910985A5a717ED9C7a0c28d6Ac4fE2d45D8cCDa6` | reactor | meme-balancer burgers-refiller |
| Reactor Impl (v5.5 ctor) | R-IMPL55 | `0x82eC86F4536167A95eF302056162b1c8b9c7F4FA` | reactor | ReactorPrimeV3 impl (v5.5) |
| Reactor Impl (SDK config) | R-IMPLSDK | `0x891587AD62bcBc6aceE9061D9C4306b9aB16cE45` | reactor | impl from chains.js SDK config |
| Flowers reactor | LR | `0x752831229E92957902B328b63df545aB50d98Af5` | reactor | Unrugable launched-token reactor |
| Flowers char-reactor | LCR | `0xfb3B709882a48b185F266Fc6f37156A92771a558` | reactor | Unrugable launched-token CHAR reactor |
| Need For Seed char-reactor | LCR | `0x2eE4029E8d83d80B01B9CD7C0a4EE81e584b87e9` | reactor | Unrugable launched-token CHAR reactor |
| Need More BASE reactor | LR | `0x745BAbD96010A1459edAdc0760c936501fCC95dB` | reactor | Unrugable launched-token reactor |
| Need More BASE char-reactor | LCR | `0x3C69C3d620616b6840c65145eCbCf7e45CAdf241` | reactor | Unrugable launched-token CHAR reactor |
| Blue Pill reactor | LR | `0xfDb309F2a7055e2dd8221f9eb27655F11d2d43be` | reactor | Unrugable launched-token reactor |
| Blue Pill char-reactor | LCR | `0x22988bCB84e635c79F570711ea5477C548140a0d` | reactor | Unrugable launched-token CHAR reactor |
| Rodeo Toad reactor | LR | `0x513d2EB33F1A7eC3798cC221Ab4b4Ce2A3FAfb98` | reactor | Unrugable launched-token reactor |
| Rodeo Toad char-reactor | LCR | `0x230a642e12b5Fabb4F4A99789a152548b39a1BE9` | reactor | Unrugable launched-token CHAR reactor |
| Turtle reactor | LR | `0xf1f8c64102Ee62361eACb694F09d24f42Aaa23da` | reactor | Unrugable launched-token reactor |
| Turtle char-reactor | LCR | `0x707d226a67CE96aaD18f3594e08d868bc43D388c` | reactor | Unrugable launched-token CHAR reactor |
| Myco (Unrugable) reactor | LR | `0x87bbF797152Ca3136a92DAc1333Fc7b1f8966e2A` | reactor | Unrugable launched-token reactor |
| Myco (Unrugable) char-reactor | LCR | `0x4618fB5b9914BEEF00C22A1082dCdC4064dcA8c3` | reactor | Unrugable launched-token CHAR reactor |
| Digerie Dude (Unrugable) reactor | LR | `0x1a6Eb1F6Bd44A35ca83d8E5E130D1eb95692b5E0` | reactor | Unrugable launched-token reactor |
| Digerie Dude (Unrugable) char-reactor | LCR | `0x11bcA0021E9957d7d0c3c358E9ED7a023E9C71a2` | reactor | Unrugable launched-token CHAR reactor |
| David Atten BRUH reactor | LR | `0x14972F189310c0B510C20f239E283D1cBd8Bfc7A` | reactor | Unrugable launched-token reactor |
| David Atten BRUH char-reactor | LCR | `0xEFCfb826a5dc63e0854535DCfA567DE94AAB5493` | reactor | Unrugable launched-token CHAR reactor |
| Never Zero reactor | LR | `0x93AB8aB8Df2fa299bF1874A638239d5ef6C95330` | reactor | Unrugable launched-token reactor |
| Never Zero char-reactor | LCR | `0x685Aa02a4FF0D6c396Ebb15F6F4957D9839E5852` | reactor | Unrugable launched-token CHAR reactor |
| I Like Money reactor | LR | `0x13Fba3fe255b8e3e462816c45725211d06Be82fB` | reactor | Unrugable launched-token reactor |
| I Like Money char-reactor | LCR | `0x3598319EFd15FeC7Bf3eb59c69184CC39b730BDd` | reactor | Unrugable launched-token CHAR reactor |
| Moon Rosta reactor | LR | `0x3534706f4B1642841c008f7368A0A16411c5Abf2` | reactor | Unrugable launched-token reactor |
| Moon Rosta char-reactor | LCR | `0x71A56cB21FC772181c3CC11b3E245d35c956Ee71` | reactor | Unrugable launched-token CHAR reactor |
| Batthew reactor | LR | `0xdb4ED222C19082C8ea9c9A044ce81e2d22DF61AB` | reactor | Unrugable launched-token reactor |
| Batthew char-reactor | LCR | `0x9aea9181e97bf613a1D4Ee9E3e6f477a2B54F061` | reactor | Unrugable launched-token CHAR reactor |
| RH Meme Reactor Prime (REAL) | RH-PRIME | `0xd51125e200689bf07A9b36A6c12fE440bb92dd4D` | reactor | RH V4 real prime; feeds FTP + GST |
| Fryer Tuck Reactor (RH) | RH-FRYER | `0x90125c8C3103556c3cdc2cbC9B508A84F52497fA` | reactor | RH Fryer Tuck reactor (correct core) |
| Burgers Reactor (RH) | RH-BURG | `0x3dB6BF508060b51FFC2622b81B888442e7B60458` | reactor | RH burgers reactor |

## Prize Pool (15)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| GOLD Mayor pool | PP-GOLD-M | `0xC76A9F461Be6253BD8676e0db41A6b2E03e318F8` | reactor | GOLD prize ladder — Mayor |
| GOLD Lord pool | PP-GOLD-L | `0x684698ae06Bba12bEf5e7684d8ed466AFD841F5A` | reactor | GOLD prize ladder — Lord |
| GOLD PettyKing pool | PP-GOLD-P | `0x6C3208D0a637eB2a993AA60bF9838b39D218F2e7` | reactor | GOLD prize ladder — PettyKing |
| GOLD HighKing pool | PP-GOLD-H | `0x784D25403f0677A4EB29dD4d8e2887c6Bf9341C3` | reactor | GOLD prize ladder — HighKing |
| GOLD Emperor pool | PP-GOLD-E | `0x5DFfBF9B20b7A1d7155d54C8c750BF60d4CdE5B4` | reactor | GOLD prize ladder — Emperor |
| ETH Mayor pool | PP-ETH-M | `0x0590AE358c9DdDBbe36CCf5D9F9FBe69290980f2` | reactor | WETH prize ladder — Mayor |
| ETH Lord pool | PP-ETH-L | `0x98750a778E8A65C5Deac9BA26ceDCf8bb8c9A66B` | reactor | WETH prize ladder — Lord |
| ETH PettyKing pool | PP-ETH-P | `0x2C7737eaAa70e031EDd04d3712525368d93C0a9A` | reactor | WETH prize ladder — PettyKing |
| ETH HighKing pool | PP-ETH-H | `0xf17792CACE3FD578a7b2d75e19afeA301f6c8D7f` | reactor | WETH prize ladder — HighKing |
| ETH Emperor pool | PP-ETH-E | `0x15B5F48d378D1F73fd151a6eD3B97508C818498a` | reactor | WETH prize ladder — Emperor |
| cbBTC Mayor pool | PP-BTC-M | `0xB10fbbCB67d68d1f43E566089FFa0f36Bd057193` | reactor | cbBTC (Rogue) prize ladder — Mayor |
| cbBTC Lord pool | PP-BTC-L | `0x4cC809378135F9501e37532dFDF3df6aED2B3342` | reactor | cbBTC (Rogue) prize ladder — Lord |
| cbBTC PettyKing pool | PP-BTC-P | `0x1D6dA6b28a62A45588411eEE66C94AC951A461D2` | reactor | cbBTC (Rogue) prize ladder — PettyKing |
| cbBTC HighKing pool | PP-BTC-H | `0x2983E3d4250d01ba05013F1E9995Cd457D7aBa65` | reactor | cbBTC (Rogue) prize ladder — HighKing |
| cbBTC Emperor pool | PP-BTC-E | `0xF3dA6a1D7d1a57F4E4782213D831646C7E45d6B0` | reactor | cbBTC (Rogue) prize ladder — Emperor |

## Bridge (8)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| Tasern Bridge (Base vault) | TB-BASE | `0x492Ae01aad197D77ebB817597d8Fa096122040F8` | reactor | POL<->Base twin bridge Base vault |
| Tasern Bridge Relayer | TB-RELAY | `0x849639C5D2ec97be27b90B2aC12c9d29e18f6CbC` | reactor | Bridge relayer (both chains) |
| MfT-RH Bridge (Base vault) | MRB-BASE | `0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb` | reactor | MfT<->RH bridge Base vault |
| Morpho aUSDC (Base) | MORPHO-AUSDC | `0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB` | reactor | Morpho aUSDC (charity harvest) |
| Tasern Bridge (Polygon vault) | TB-POL | `0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f` | reactor | POL<->Base twin bridge Polygon vault |
| MfT-RH Bridge (RH vault) | MRB-RH | `0xa819b6D99135222f604047A3304ba53424D4779d` | reactor | MfT<->RH bridge RH vault (also Baseling Flower NFT) |
| MfT twin on RH | MFT-RH | `0x6ae576608725677Bf8D05EA7796849E6F8F57608` | ERC20 | MfT bridged twin on Robinhood chain |
| Morpho Vault (FTP) | MORPHO-FTP | `0xBeEff033F34C046626B8D0A041844C5d1A5409dd` | reactor | Morpho vault backing FTP/GST |

## Factory (5)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| LocationLP Factory | LOC-FACT | `0x54868729015F0050B364729454a018f1FF7a2d01` | reactor | On-chain location pool factory |
| LocationLP Factory Impl | LOC-IMPL | `0x6700ded62e5f773729dcb1Eb8C93F2Da7fDD7A9F` | reactor | Location pool implementation |
| Unrugable Reactor Factory (current) | UNRUG-FACT | `0x9FCE6fF019570dC09678C6Fcd513bDF5cf766fC9` | reactor | V5.x current factory (older 5 dropped as superseded) |
| Unrugable Factory (v7 SDK) | UNRUG-V7 | `0x90297A8a1F9A7E35bbC9DF8C35Aa7F3FFBe9BDb2` | reactor | v7 SDK free-launch factory (chains.js) |
| Vault Factory (Money/CharityFund = KidsVaultFactory) | VAULT-FACT | `0x1f6ff7370e2e897db7cf5d72684ef76d988caaf1` | reactor | CommunityLPVaultV3 factory |

## Game System (20)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| WorkClock V2 | WORKCLK | `0xE5DE012B9123C8594abb032471b6E7511f0bC601` | reactor | Seas job timer (V1 dropped) |
| Pawn Distributor (first ship) | PAWNDIST | `0x2E2AB7ae48876f1b4497A04d864C025f7DF58e1f` | reactor | PAWNS distributor; = Black Tide crew NFT + distributor |
| BaselingRouter V5 | BASE-RTR | `0x01c4FbD69AF4c6B44606fef3e35939F0dB9dFAA2` | reactor | Baseling launcher router (dynamic families) |
| Pantry | PANTRY | `0x900b9a705370a10071F09C79360656C06Bfc7680` | reactor | Baseling food storage |
| PowerPlant V3 | PP-V3 | `0x5B5153b282F0a4244C6CCbFc65bCC27400c460Ff` | reactor | Baseling 3-way split power |
| TraitRegistry | TRAITS | `0xfCb1aA4537844d6730d4068407ed4B161BAD7d04` | reactor | Baseling traits |
| BaselingState V3 | BSTATE | `0x4b123766152397BAa035a52808DDDCD794c8a32d` | reactor | Baseling ERC1155 yield farm state |
| BaselingState (keeper-v4 alt) | BSTATE4 | `0x3a05499D52Bdd76442DA42C179B2F1883bB8A780` | reactor | Baseling state keeper-v4 variant |
| BaselingAssignments | BASSIGN | `0xabC2e93CF79F89E0874741366E9C33D73D7E9C6c` | reactor | Baseling assignments |
| GroceryStore v2 | GROCERY | `0x8e346E31faD18709cf71A1f374cE1729A9Bd318A` | reactor | Baseling food store (live; older 0xB8D02581 dropped) |
| KeeperBatch V5 | KEEPER5 | `0xFD8F518D92024Eb8242cdA06aC9AD12450378a1f` | reactor | Baseling batch keeper (V5 live) |
| KeeperBatch (v4 alt) | KEEPER4 | `0xE693dD02BB1Ba0850A1a153a03b99531004096B1` | reactor | Baseling keeper-v4 default |
| Poop Router | POOP-RTR | `0xB56bC9377b678C1acA8C1d15844396d2B3EBe684` | reactor | POOP swap router |
| Yield Vault (Baseling) | YIELD-V | `0x36af0dCeC1F8067e5547bEe3bd9aB2b9c10a41aE` | reactor | Baseling yield farm |
| Garden Multi | GARDEN | `0xD2b6230922A0E6E200Bbf3a67670E0e6B66DA80d` | reactor | Baseling multi-garden |
| Name Registry | NAMEREG | `0xBf621490464CB5dbb426235387BdBa26e4f9C738` | reactor | MemeTree naming registry |
| FISH/Guard skill vault (WIS) | FISH-SKV | `0x8C121fC0171944C3EA40d14FE549dFf7107BDf39` | reactor | WIS harbor-guard skill vault (shared collection; ground SHELVED) |
| Shipyard Relayer | SHIPYARD | `0xC4040cD3C6f899065d9d6e27A72B4dDF2B4dE023` | reactor | On-chain shipyard relayer |
| Shark Arb | SHARK | `0xf8958f0be77de89Bf2aBc129A26b129FaaEAA83b` | reactor | Arb bot contract |
| Algebra Helper | ALGHELP | `0x5983B0109dd6DA2CE69DC69A1377EEDCdff164BD` | reactor | Algebra pool helper |

## NFT (11)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| Baseling NFT | BASE-NFT | `0xFCb825491490284189C75fD330Fd08Df5E9217b9` | ERC20 | Main Baseling ERC721 |
| House NFT | HOUSE-NFT | `0x70Ff566A417ece44784196106afdbecDAaA3b511` | ERC20 | Baseling house ERC721 |
| MemeTreesV4 NFT | MT4-NFT | `0x07EA54157404FB31268403F0421e26b8FD6D8f76` | ERC20 | Current MemeTrees NFT (V3 dropped) |
| Tales of Tasern Character | TOT-NFT | `0x9DE88fAa0DbcFc75534d1B4Fd277DadFFcC4FD30` | ERC20 | ERC721 character NFT |
| Carbon Countin Club (Base) | CCC-NFT-B | `0xe608b78d14e98d0b34e142acb89561e9918346b5` | ERC20 | CCC NFT (Base) |
| MycoVault NFT | MYCO-NFT | `0xCb8C8A116AC3E12d861c1b4bD0D859aCeda25d3F` | ERC20 | MycoVault NFT |
| Seas Crew - Sol del Mar (Elf) | CREW-SDM | `0x9500880DEC9B310b4a728C75A271a25615A2443E` | ERC20 | Seas crew NFT (Sol del Mar; ship token pending) |
| Seas Crew - Redrum Raiders (Goblin) | CREW-RR | `0x4ECe491951B759363bCBAF75389a202Fe0584080` | ERC20 | Seas crew NFT (= Redrum ship distributor) |
| Seas Crew - Harbor Guard (Human) | CREW-HG | `0x8C1f935F6DbB17d593BF3EC8114A2f045e350545` | ERC20 | Seas crew NFT (= Harbor Guard ship distributor) |
| Seas Crew - The Verdant Warden (Elf) | CREW-VW | `0x4FB1502c3835cf4A9646f2C7c0dDf3584B45b9f1` | ERC20 | Seas crew NFT (= Verdant Warden ship distributor) |
| Carbon Countin Club (Polygon) | CCC-NFT-P | `0x9ab182d1a7b19ac6581e0f15a61b72e10beeb27d` | ERC20 | CCC NFT (Polygon) |

## Game LP (134)

| Name | Ticker | Address | Type | What it is |
|---|---|---|---|---|
| EBM/EGP Wall | EBM-EGP-LP | `0xA05eC6d7CAA92F39bB09727BC4983c02b3814280` | LP pool | V3 fee 10000; one-sided EBM wall; in EBM reactor |
| EBM/Money Wall | EBM-MONEY-LP | `0x53bF2AAC5f0146951C627040e6467D90f37116ad` | LP pool | V3 fee 10000; one-sided EBM wall; in EBM reactor |
| RISH/Money Wall | RISH-MONEY-LP | `0x983F5054B43bb95d99Df0c7A698d920008c7EFAe` | LP pool | V3 fee 10000; one-sided RISH wall; in RISH reactor |
| RISH/PKT Wall | RISH-PKT-LP | `0x4f0Da48E1A7F553eaD446c147Ab0eB7A71aFA6F1` | LP pool | V3 fee 10000; one-sided RISH wall; in RISH reactor |
| BONGO/Money Wall | BONGO-MONEY-LP | `0x76AE74cc8D61074dF48E9A851cB2a0228A7D1dda` | LP pool | V3 fee 10000; one-sided BONGO wall; Money 6 dec |
| BONGO/BTN Wall | BONGO-BTN-LP | `0x09f4426CE464257F2a00c13Ea8Fa943de0d528A1` | LP pool | V3 fee 10000; one-sided BONGO wall; BTN 8 dec |
| DGT/Money Wall | DGT-MONEY-LP | `0x4dABc580feA6abb51B7FD7FfACC4380ffE56eD9C` | LP pool | V3 fee 10000; one-sided DGT wall; in DGT reactor |
| DGT/IGS Wall | DGT-IGS-LP | `0xEFbcb137922892484db71daD67E08f795667A007` | LP pool | V3 fee 10000; one-sided DGT wall; IGS 8 dec |
| DD/Money Wall | DD-MONEY-LP | `0xcfea953A2bC6Fe2c3A4781bD2a0fD5b021A6F3cD` | LP pool | V3 fee 10000; one-sided DD wall |
| DD/DDD Wall | DD-DDD-LP | `0xb971E145dDb28a459a191816c261778Dad8bd450` | LP pool | V3 fee 10000; one-sided DD wall |
| MYCO/Money Wall | MYCO-MONEY-LP | `0xF4292683d43d835f020F80e4e506c2583dea165F` | LP pool | V3 fee 10000; one-sided MYCO wall |
| MYCO/DHG Wall | MYCO-DHG-LP | `0xa15206a6672D4402c1Cd4DcED38873e2298bD9ac` | LP pool | V3 fee 10000; one-sided MYCO wall; DHG 8 dec |
| MR/Money Wall | MR-MONEY-LP | `0x64148549B57e1c7537B20060f0d8AdbD6EA5C13f` | LP pool | V3 fee 10000; one-sided MR wall |
| MR/IGS Wall | MR-IGS-LP | `0x26a827f45B2Dda6D811c13445271F801a97De422` | LP pool | V3 fee 10000; one-sided MR wall; IGS 8 dec |
| WM/Money Wall | WM-MONEY-LP | `0x5c4033d951Be97B74BDcb48c3e553b8279caf7bb` | LP pool | V3 fee 10000; one-sided WM wall |
| WM/OGC Wall | WM-OGC-LP | `0x32c507D192EA277733b8BdfdD76Db801F4bdE93a` | LP pool | V3 fee 10000; one-sided WM wall |
| JS/Money Wall | JS-MONEY-LP | `0x4A4312F52A1c2D1E36f9aD3Ec5AC386284a1563a` | LP pool | V3 fee 10000; one-sided JS wall |
| JS/EGP Wall | JS-EGP-LP | `0x49E8Bce47D0329B46F971A40112B650Da00C342A` | LP pool | V3 fee 10000; one-sided JS wall |
| NN/Money Wall | NN-MONEY-LP | `0x0d26a8Ef0395668dEa3D38013a717737BAB65c7f` | LP pool | V3 fee 10000; one-sided NN wall |
| NN/EGP Wall | NN-EGP-LP | `0xdd4c1f8ec865670CD6BCf0eC2B48aEBcCf49eeA6` | LP pool | V3 fee 10000; one-sided NN wall |
| HT/Money Wall | HT-MONEY-LP | `0xe7A698B07A35bD9c0732b732513223a93101bE52` | LP pool | V3 fee 10000; one-sided HT wall |
| HT/LGP Wall | HT-LGP-LP | `0x36DeB77f66e94d885b908a2cc2ceD49f15ccC086` | LP pool | V3 fee 10000; one-sided HT wall |
| RICKY/Money Wall | RICKY-MONEY-LP | `0x7E9Fd72B43514dC0dD67462b674f84C1aAcF08C4` | LP pool | V3 fee 10000; one-sided RICKY wall |
| RICKY/PKT Wall | RICKY-PKT-LP | `0xa7B89d456E0619af15aD8e6534bB736E86d52011` | LP pool | V3 fee 10000; one-sided RICKY wall |
| BIGGINS/Money Wall | BIGGINS-MONEY-LP | `0x01FA47f241E994e35e416C3BA3C2EC5BCDc9AD81` | LP pool | V3 fee 10000; one-sided BIGGINS wall |
| BIGGINS/BTN Wall | BIGGINS-BTN-LP | `0x08A3C41AeD1125FFE3044e185d0cFF38d5ecf8f4` | LP pool | V3 fee 10000; one-sided BIGGINS wall; BTN 8 dec |
| JASMINE/Money Wall | JASMINE-MONEY-LP | `0x29c3497c0072b8e7126290Ff62F65b414A5BD262` | LP pool | V3 fee 10000; one-sided JASMINE wall |
| JASMINE/PKT Wall | JASMINE-PKT-LP | `0x7ebEf93e98f0167070cD971c8bF314Fc6c65fb1B` | LP pool | V3 fee 10000; one-sided JASMINE wall |
| PKT/Money (V2) | PKT-MONEY-V2 | `0x4FE25D8a3930e5788dB64f4a813473120ab7236e` | LP pool | V2 nation market |
| PKT/MfT (V2) | PKT-MFT-V2 | `0xF80bE683B0F74f2dDdBCDc6Edb63B1b283B50306` | LP pool | V2 nation market |
| IGS/MfT (V2) | IGS-MFT-V2 | `0x9876F94e3528d4D9b6C4dba622eB292EF7c3ce64` | LP pool | V2 nation market; IGS 8 dec |
| DDD/MfT (V2) | DDD-MFT-V2 | `0x2cF15966B0A0Bd2f98908312731C513fdef725D8` | LP pool | V2 nation market |
| OGC/MfT (V2) | OGC-MFT-V2 | `0xE0535207660F2d51CeE82Ad1f9d881C3c2ef94A9` | LP pool | V2 nation market |
| BTN/MfT (V2) | BTN-MFT-V2 | `0x43BCd688e2cb0d98b275DB2fb152B2fA8C5Cc4E7` | LP pool | V2 nation market; BTN 8 dec |
| DHG/MfT (V2) | DHG-MFT-V2 | `0x9A709Ffa0B92b085Cb1f0328Ed8c6a376A531D5b` | LP pool | V2 nation market; DHG 8 dec |
| LGP/MfT (V2) | LGP-MFT-V2 | `0xB5e73609e767eD0061b9efE5c96ED072610fc066` | LP pool | V2 nation market |
| EGP/Money (Base) | EGP-MONEY-LP | `0x53552e7287c84c689328a86b16ecdf90353d8085` | LP pool | nation market (VPS) |
| EGP/MfT (Base) | EGP-MFT-LP | `0x36d0c273faca6e90f827bc2e7d232246f9f89fe4` | LP pool | nation market (VPS) |
| DDD/Money (Base) | DDD-MONEY-LP | `0x6817a2504caf2ddac137757fc4f01f586d28fe0d` | LP pool | nation market (VPS) |
| OGC/Money (Base) | OGC-MONEY-LP | `0x683d18067658a5aa00bdb40b1d912723e3b3b867` | LP pool | nation market (VPS) |
| BTN/Money (Base) | BTN-MONEY-LP | `0x891164ea1c4dbf1ef8e38fcea41a028a941a1262` | LP pool | nation market (VPS); BTN 8 dec |
| DHG/Money (Base) | DHG-MONEY-LP | `0xddeeaf5c7cba69fe6fce38c10e6657300ff44fe0` | LP pool | nation market (VPS); DHG 8 dec |
| LGP/Money (Base) | LGP-MONEY-LP | `0x49762eea43b87526dfc71e1d67d5e13896aa87ac` | LP pool | nation market (VPS) |
| IGS/Money (V2) | IGS-MONEY-V2 | `0x1136ef4aa2a79b587b0863d427dd7d67197bf42a` | LP pool | nation market (VPS); IGS 8 dec |
| MfT/WETH (V2) | MFT-WETH-V2 | `0x23ac5919b710b6a62bd2acf8be5cd29560bf1a78` | LP pool | MfT food/base pair |
| MfT/cbBTC (V2) | MFT-CBBTC-V2 | `0x5ea3608d81f39b39c769b3f168991f743b03cc14` | LP pool | MfT food/base pair |
| MfT/BURGERS (V2) | MFT-BURG-V2 | `0xa2A61fD7816951A0bCf8C67eA8f153C1AB5De288` | LP pool | MfT food pair |
| MfT/TGN (V2) | MFT-TGN-V2 | `0xbd0cc3b0aaf91b80c862dbcaf39faa4705ee2d7a` | LP pool | MfT food pair |
| MfT/AZUSD (V2) | MFT-AZUSD-V2 | `0xecc664757da0c71ba32dfed527580a26783b6697` | LP pool | MfT food pair |
| MfT/BRETT (V2) | MFT-BRETT-V2 | `0x869f6671dfefcfeabe9e248c3e12d34edc7164e4` | LP pool | MfT partner pair |
| BUSTER/MfT (V2) | BUSTER-MFT-V2 | `0xC6ce74A02a63FdBA97c39aC1fa6Ac2AF5CD02223` | LP pool | Baselings food pair |
| PIZZA/MfT (V2) | PIZZA-MFT-V2 | `0x56b33f34c1f7efc69c2ae0c6a28236b16a7f0384` | LP pool | Baselings food pair |
| Hydrex MfT/USDC | MFT-USDC-HDX | `0x312dc77ebe85c59de1adf2edb518aa5199e97def` | LP pool | Hydrex MfT/USDC pool |
| Money/BTC-T ripple (V2) | MONEY-BTCT-V2 | `0xbfcedd0d2f087d56182b6fb3bab9094007bc5411` | LP pool | Money/BTC-T |
| PRGT/USDC (V3 0.01%) | PRGT-USDC-V3 | `0x437b6482480b34791d7aec11b9ca48f9068ae7cd` | LP pool | PRGT peg pool |
| BTC-T/cbBTC peg (V3) | BTCT-CBBTC-V3 | `0x7a635f8c66b93eb7f3e9ec45abdcc6a8fc6f6eca` | LP pool | BTC-T peg pool |
| HOLM/PRGT (V2) | HOLM-PRGT-V2 | `0x322ae1cEaB6Be7fc2275c98173DEBb64D3756599` | LP pool | Holm Kids LP |
| GOLD/MONEY (1% vault pool) | GOLD-MONEY-LP | `0xe1318fEea976FbEa1d295De8A628DcdB7965905a` | LP pool | coin vault pool |
| GOLD/SILVER | GOLD-SILVER-LP | `0x0a180f3926d481a7242191cbe142cbed75c7bcae` | LP pool | coin pool |
| GOLD/COPPER | GOLD-COPPER-LP | `0xca6e79a7c7714a97c5bf6f086ddc9a2a264a69c6` | LP pool | coin pool |
| SILVER/COPPER | SILVER-COPPER-LP | `0x89f3ca1cb642bf55a3118cf8d9406c97003dbbf6` | LP pool | coin pool |
| GOLD/AMETHYST | GOLD-AMETH-LP | `0xcb8f1b95d2988ca7429eac9571c0eb3824099226` | LP pool | gem pool |
| GOLD/PLATINUM | GOLD-PLAT-LP | `0xdee5f0bd8006f15fbd4f3c1543a615c45e48b313` | LP pool | gem pool |
| AMETHYST/EMERALD | AMETH-EMER-LP | `0x1906a3666120c879ff0ecd47352cf1b91d755a7a` | LP pool | gem pool |
| AMETHYST/RUBY | AMETH-RUBY-LP | `0xece2b217ac80832a2b86eab3eaadb0f501676d3f` | LP pool | gem pool |
| AMETHYST/DIAMOND | AMETH-DIAM-LP | `0xdc4523658ac9d63b2488ce2674e3ad34b626fb60` | LP pool | gem pool |
| AMETHYST/PLATINUM | AMETH-PLAT-LP | `0x984290a07c8afc644f1676a42c55a8df9b743c7e` | LP pool | gem pool |
| EMERALD/RUBY | EMER-RUBY-LP | `0xb1b4fac536dcdd2edb985d90b4f28d08c34b2522` | LP pool | gem pool |
| EMERALD/DIAMOND | EMER-DIAM-LP | `0xb8b6eb50286e52c381ef946226606829881d275c` | LP pool | gem pool |
| RUBY/DIAMOND | RUBY-DIAM-LP | `0xd856c17c53eaf2ec4df2664545489fcfcfb6a3fc` | LP pool | gem pool |
| Job Vault - Haul cargo (STR) | JV-STR | `0xd6d793628dc6eed71eb37dd6c51678e8a9c25f22` | LP pool | Seas job water vault (CRATEw) |
| Job Vault - Mend nets (DEX) | JV-DEX | `0xb303c91724485462e3450a0bd4513a521df997cb` | LP pool | Seas job water vault (EGPw) |
| Job Vault - Stock rations (CON) | JV-CON | `0x893531a85f249cc38da772be9056762e188302f6` | LP pool | Seas job water vault (BURGERSw) |
| Job Vault - Tend beacon (INT) | JV-INT | `0x90b54da4ac020fb163c51237e169feceac2369be` | LP pool | Seas job water vault (BEACONw) |
| Job Vault - Barter (CHA) | JV-CHA | `0xc0813524820df5c6bb9a63a521fe218ff974b1b4` | LP pool | Seas job water vault (TGNw) |
| PR25 / EGP | PR25/EGP | `0x4ff6295614884b0f7c3269d5ae486b66c5d8615f` | LP pool | counterparty EGP |
| PR25 / LGP | PR25/LGP | `0x485cbb3fe4cae0eb4efbfb859092be506afc6d18` | LP pool | counterparty LGP |
| PR25 / WETH | PR25/WETH | `0x00501f69afa9613ab155e80b9d433bcb972d6f05` | LP pool | counterparty WETH |
| CCC / DDD | CCC/DDD | `0x73e6a1630486d0874ec56339327993a3e4684691` | LP pool | counterparty DDD |
| CCC / EGP | CCC/EGP | `0xbcd50f1c7f28bc5712ac03c5a18ff0d46ce6bff5` | LP pool | counterparty EGP |
| CCC / OGC | CCC/OGC | `0x3dd8cb68cbe0eb3e57707a3d1f136ff245d829fd` | LP pool | counterparty OGC |
| CCC / PKT | CCC/PKT | `0xad199d493327f5655b4e2f4a7c4e930a73ad226f` | LP pool | counterparty PKT |
| CCC / BTN | CCC/BTN | `0x2e49bb80e4255cdc32551a718444444d42994032` | LP pool | counterparty BTN |
| CCC / DHG | CCC/DHG | `0xef7a39205c45e4aa8a3d784c96088ea9a6d35596` | LP pool | counterparty DHG |
| CCC / LGP | CCC/LGP | `0xdb916d0e476b6263c9f910e17373574747d4c471` | LP pool | counterparty LGP |
| CCC / NCT | CCC/NCT | `0x7407c7fdcdf3f34ef317ad478c9bae252dc91859` | LP pool | carbon counterparty NCT |
| CCC / BCT | CCC/BCT | `0x149eb42c8bb6644ef28411bede171ad051434412` | LP pool | carbon counterparty BCT |
| CCC / USDGLO | CCC/USDGLO | `0xa4817dc7bdfdde18e54e4f0bcfa84d632eefb377` | LP pool | stable counterparty USDGLO |
| NCT / USDC | NCT/USDC | `0xDb995F975F1Bfc3B2157495c47E4efB31196B2CA` | LP pool | stable counterparty USDC |
| axlREGEN / NCT | axlREGEN/NCT | `0x9e1E2f7569ff9e9597fdaBcbbb6ADD42f0534bdB` | LP pool | carbon counterparty NCT |
| DDD / NCT | DDD/NCT | `0xfc983c854683b562c6e0f858a15b32698b32ba45` | LP pool | carbon counterparty NCT |
| NCT / IGS | NCT/IGS | `0xb70f13acb3f220b01d891b81a417c4dee79b5235` | LP pool | counterparty IGS |
| BTN / NCT | BTN/NCT | `0x35b02ed94ce217a4aba3546099ee9db1b85bfe3d` | LP pool | carbon counterparty NCT |
| PKT / NCT | PKT/NCT | `0x2da5766f3b789204f0151e401b58a0421249426c` | LP pool | carbon counterparty NCT |
| BCT / USDC | BCT/USDC | `0x1E67124681b402064CD0ABE8ed1B5c79D2e02f64` | LP pool | stable counterparty USDC |
| BCT / WPOL | BCT/WPOL | `0x32e228A6086c684F1391C0935cB34C296e0DD9Cb` | LP pool | counterparty WPOL |
| LGP / UNI | LGP/UNI | `0x19F3DF2F5900705E8a6DfeBEC0f02ccd10437C0f` | LP pool | counterparty UNI |
| LGP / WPOL | LGP/WPOL | `0xDFBd6bFd5875463C33e0c18c1FC43aA22f7B84b5` | LP pool | counterparty WPOL |
| USDGLO / LGP | USDGLO/LGP | `0x395106988f425dC4c85b1997b7063cFe38C64278` | LP pool | counterparty LGP |
| DHG / CRISP-M | DHG/CRISP-M | `0x17Be99a282559a24E57ED4f7FA436665200F890b` | LP pool | carbon counterparty CRISP-M |
| IGS / USDGLO | IGS/USDGLO | `0x61646724babcdeb4f70683a5b7c46d2bde506ee8` | LP pool | stable counterparty USDGLO |
| IGS / WBTC | IGS/WBTC | `0xc9ec8a430e194295c82d75e5900d22f3ed254268` | LP pool | counterparty WBTC |
| BTN / WBTC | BTN/WBTC | `0x1395E5CBcA1F9cce3271EAd9cA3F727EA6E78cBa` | LP pool | counterparty WBTC |
| BTN / WPOL | BTN/WPOL | `0x553b5414C109963C636EfE142C8eB6bA2908f55C` | LP pool | counterparty WPOL |
| USDGLO / BTN | USDGLO/BTN | `0xc174118B4e8009F525a0464744d4BFEA30F67D9d` | LP pool | counterparty BTN |
| OGC / WBTC | OGC/WBTC | `0xDB217EE8aeee2f344fEE7a9b53E73cc68f7321f3` | LP pool | counterparty WBTC |
| PKT / USDT0 | PKT/USDT0 | `0x0fdEF11A0B332B3E723D181c0cB5Cb10eA52d135` | LP pool | stable counterparty USDT0 |
| EGP / PKT | EGP/PKT | `0xCd0bAd3Af02b36725A82128469b03535e0d48F2A` | LP pool | counterparty PKT |
| EGP / WETH | EGP/WETH | `0xd815d289604bD1109e2F3A9B919d7f3D1f2B99fb` | LP pool | counterparty WETH |
| EGP / WPOL | EGP/WPOL | `0x19e01FC41c8cC561D47e615F3509cd2e128e259B` | LP pool | counterparty WPOL |
| USDGLO / EGP | USDGLO/EGP | `0xEb5b6e6AC30fB8949269a88814925B2639eede4b` | LP pool | counterparty EGP |
| DDD / REGEN | DDD/REGEN | `0x520a3b3faca7ddc8dc8cd3380c8475b67f3c7b8d` | LP pool | carbon counterparty REGEN |
| DDD / LGP | DDD/LGP | `0x0d0ac298f5f1970c0f48c3084dd2d48a1fd24242` | LP pool | counterparty LGP |
| EGP / WBTC | EGP/WBTC | `0xa628e29a8f0dfcb974bc387ddb933c5fd019a0b7` | LP pool | counterparty WBTC |
| OGC / USDGLO | OGC/USDGLO | `0xcb8ecb17365ad243f64839aea81f40679e0c8c9a` | LP pool | stable counterparty USDGLO |
| PKT / WBTC | PKT/WBTC | `0xdc12e9f5e9daf92df08e5d781c57bb92d5f110ef` | LP pool | counterparty WBTC |
| PKT / BTN | PKT/BTN | `0x0f8f67f4143485bf3afd76389da9a8c745320da6` | LP pool | counterparty BTN |
| PKT / USDGLO | PKT/USDGLO | `0x2be03aca43921852d389c65ae82bb9c2f3069f11` | LP pool | stable counterparty USDGLO |
| DHG / WPOL | DHG/WPOL | `0x3782611c293e4519a386ff848a0d04827111b225` | LP pool | counterparty WPOL |
| CCC / WBTC | CCC/WBTC | `0x93064cb5fc83919cf608a699a847b64360180e6e` | LP pool | counterparty WBTC |
| CCC / WETH | CCC/WETH | `0x4316dc9f32110f9bef901347cf7b4cdb463e9cb3` | LP pool | counterparty WETH |
| CCC / WPOL | CCC/WPOL | `0xc9131f6408e31c8fced33f12a031a1b3e2bea080` | LP pool | counterparty WPOL |
| DDD / WBTC | DDD/WBTC | `0xcAe2c5BbC8d6f768cA73CF9Bd84A0C90CC492f43` | LP pool | counterparty WBTC |
| DDD / WPOL | DDD/WPOL | `0x9C4e724a226a4103DC0a303C902357Bcbc7413AF` | LP pool | counterparty WPOL |
| USDGLO / DDD | USDGLO/DDD | `0x7eE2dd0022e3460177B90b8F8fa3b3a76D970FF6` | LP pool | counterparty DDD |
| EGP / DDD | EGP/DDD | `0xbA262Af3E1c559246e407C94C91F77Ff334F6a90` | LP pool | counterparty DDD |
| PR25 / DDD | PR25/DDD | `0x43c9b0DFdaFF40c38a24850636662394EF42D03F` | LP pool | counterparty DDD |
| PR25 / IGS | PR25/IGS | `0xaB9DC44b75F87f40421120e8E1228076123f2735` | LP pool | counterparty IGS |
| PR25 / BTN | PR25/BTN | `0x54a326013c971f5aabf28240ffd6c1ef9d77e6f9` | LP pool | counterparty BTN |
| PR25 / PKT | PR25/PKT | `0x3434a0b68d36d8ae4ffb9e2c236a680a25e9237d` | LP pool | counterparty PKT |
| PR25 / OGC | PR25/OGC | `0x46b7b31cac35586673f1791025032e6ee0e2e72b` | LP pool | counterparty OGC |
| PR25 / DHG | PR25/DHG | `0xd548854d8e850011bd12d0f14b326a931d8fd4c7` | LP pool | counterparty DHG |
| OGC / PKT | OGC/PKT | `0x62317508308b68bd36d6e5f17e1c4055fbf99351` | LP pool | counterparty PKT |
| DDD / USDC | DDD/USDC | `0x0aa47ed14bd86c114bb4e88553251414d22e3955` | LP pool | stable counterparty USDC |

