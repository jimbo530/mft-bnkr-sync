# Canonical Pool Keys (chain 4663)

Source: rh-burgers-route.json + rh-ftp-vault-v2.json (verified 2026-07-13)

## bfKey — BURGERS/FTP (vault position pool)

This is the pool the vault holds a position in.

| Field | Value |
|-------|-------|
| currency0 | `0x873739aeD7b49f005965377b5645914b1D78Ccd3` (FTP vault token) |
| currency1 | `0xf796e42EA375bcD592c892FE64968Ba06188bbA3` (BURGERS) |
| fee | `10000` |
| tickSpacing | `200` |
| hooks | `0x0000000000000000000000000000000000000000` |

Standard tick range for new vaults: `tickLower=416600, tickUpper=424800`

## bwKey — BURGERS/WETH (deep route leg 1, doppler)

| Field | Value |
|-------|-------|
| currency0 | `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` (WETH) |
| currency1 | `0xf796e42EA375bcD592c892FE64968Ba06188bbA3` (BURGERS) |
| fee | `8388608` (V4 DYNAMIC_FEE_FLAG) |
| tickSpacing | `200` |
| hooks | `0x4e3468951D49f2EEa976eD0D6e75fFCb44a9a544` |

## wuKey — WETH/USDG (deep route leg 2, vanilla)

| Field | Value |
|-------|-------|
| currency0 | `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` (WETH) |
| currency1 | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` (USDG) |
| fee | `3000` |
| tickSpacing | `60` |
| hooks | `0x0000000000000000000000000000000000000000` |
