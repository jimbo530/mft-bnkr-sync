# Known Polygon Originals for deployTwin

Source: tasern-bridge-deployment.json

Always read `name`, `symbol`, `decimals`, and `totalSupply` (cap) directly from
the Polygon original contract before calling `deployTwin`. Do not hardcode.

| Symbol | Polygon Original | Decimal note |
|--------|-----------------|--------------|
| DDD | `0x4bf82cf0d6b2afc87367052b793097153c859d38` | Likely 18 — confirm |
| OGC | `0xccf37622e6b72352e7b410481dd4913563038b7c` | Likely 18 — confirm |
| PKT | `0x8a088dceecbcf457762eb7c66f78fff27dc0c04a` | Likely 18 — confirm |
| BTN | `0xd7c584d40216576f1d8651eab8bef9de69497666` | **Likely 8 decimals — confirm on-chain** |
| IGS | `0xe302672798d12e7f68c783db2c2d5e6b48ccf3ce` | **Likely 8 decimals — confirm on-chain** |
| DHG | `0x75c0a194cd8b4f01d5ed58be5b7c5b61a9c69d0a` | Likely 18 — confirm |
| LGP | `0xddc330761761751e005333208889bfe36c6e6760` | Likely 18 — confirm |
| PR25 | `0x72e4327f592e9cb09d5730a55d1d68de144af53c` | Likely 18 — confirm |
| MfT | Confirm Polygon original address from chain | RH twin may already exist at mftTwin in rh-v4-addresses.json |

## Warning on MfT

`rh-v4-addresses.json` lists an `mftTwin` address on RH. If a twin was already
deployed to that address via a prior deploy, do NOT call `deployTwin` again for
the same Polygon original — it will revert with `"twin exists"`. Verify via
`twinOf(polygonMfTAddress)` on the bridge before calling.
