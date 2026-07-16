#!/usr/bin/env bash
# Deposit into a Meme for Trees charity fund on Base via Bankr.
# Builds approve(fund, amount) + deposit(amount) as raw calldata and submits
# both through Bankr's arbitrary-transaction feature. Receipt is minted 1:1.
#
# All six funds are on Base (chainId 8453), executable via Bankr.
#
# Usage:
#   ./deposit.sh <vault-key> <amount> [recipient]
#     vault-key : money | prgt | char-r | ccc-r | btc-t | eth-t
#     amount    : whole units of the deposit asset
#                 (e.g. 25 = $25 USDC, 0.001 = 0.001 cbBTC)
#     recipient : (optional) 0x address to mint the receipt to (uses depositFor)
#
# Examples:
#   ./deposit.sh money 25               # 25 USDC -> 25 Money for Trees
#   ./deposit.sh char-r 50              # 50 USDC -> 50 CHAR-R
#   ./deposit.sh btc-t 0.001            # 0.001 cbBTC -> 0.001 BTC-T
#   ./deposit.sh eth-t 0.005            # 0.005 wETH -> 0.005 ETH-T
#   ./deposit.sh money 25 0xABC...123   # deposit $25, mint Money to 0xABC...123
set -euo pipefail

# ---- Require Bankr CLI -------------------------------------------------------
if ! command -v bankr >/dev/null 2>&1; then
  echo "Bankr CLI not found. Install with: npm install -g @bankr/cli" >&2
  exit 1
fi

VAULT_KEY="${1:-}"
AMOUNT="${2:-}"
RECIPIENT="${3:-}"

usage() {
  cat >&2 <<'EOF'
Usage: ./deposit.sh <vault-key> <amount> [recipient]
  vault-key : money | prgt | char-r | ccc-r | btc-t | eth-t
  amount    : whole units of the deposit asset
              (e.g. 25 = $25 USDC, 0.001 = 0.001 cbBTC, 0.005 = 0.005 wETH)
  recipient : optional 0x address to receive the receipt (uses depositFor)

Examples:
  ./deposit.sh money 25
  ./deposit.sh char-r 50
  ./deposit.sh btc-t 0.001
  ./deposit.sh eth-t 0.005
  ./deposit.sh money 25 0xABC...123
EOF
}

if [[ -z "$VAULT_KEY" || -z "$AMOUNT" ]]; then
  usage
  exit 1
fi

# ---- Fund registry (VERIFIED on-chain 2026-07-14; see references/funds.md) --
# Fields: FUND | ASSET | CHAIN_ID | DECIMALS | FRIENDLY
# DECIMALS = deposit asset decimals (used for calldata encoding)
# CharityFund.sol: deposit(uint256) selector 0xb6b55f25, mints 1:1
case "$(echo "$VAULT_KEY" | tr '[:upper:]' '[:lower:]')" in
  money|mft|mftusd)
    FUND="0xe3dd3881477c20C17Df080cEec0C1bD0C065A072"
    ASSET="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC (Base)
    CHAIN_ID=8453
    DECIMALS=6
    FRIENDLY="Money for Trees"
    ;;
  prgt|"poly raiders"|"poly raiders growth token")
    FUND="0xEe6fB5f324B05efF95fD59F4574050a891e6913D"
    ASSET="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC (Base)
    CHAIN_ID=8453
    DECIMALS=6
    FRIENDLY="PRGT (Poly Raiders Growth Token)"
    ;;
  char-r|"char retirement"|"carbon retirement")
    FUND="0xde12963128CBe9aF173a37FFF866cA4D4A194ff4"
    ASSET="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC (Base)
    CHAIN_ID=8453
    DECIMALS=6
    FRIENDLY="CHAR Retirement Fund"
    ;;
  ccc-r|"ccc retirement"|"carbon counting")
    FUND="0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B"
    ASSET="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC (Base)
    CHAIN_ID=8453
    DECIMALS=6
    FRIENDLY="CCC Retirement Fund"
    ;;
  btc-t|"btc for trees")
    FUND="0x839BAa00734f319C11F2869bC155C6B5Fe35a283"
    ASSET="0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"   # cbBTC (Base, 8 dec)
    CHAIN_ID=8453
    DECIMALS=8
    FRIENDLY="BTC for Trees"
    ;;
  eth-t|"eth for trees")
    FUND="0x80d1edd0236A06283fd1212FDB12cfA79516933d"
    ASSET="0x4200000000000000000000000000000000000006"   # wETH (Base, 18 dec)
    CHAIN_ID=8453
    DECIMALS=18
    FRIENDLY="ETH for Trees"
    ;;
  *)
    echo "Unknown vault key: '$VAULT_KEY'" >&2
    echo "Expected: money | prgt | char-r | ccc-r | btc-t | eth-t" >&2
    usage
    exit 1
    ;;
esac

# ---- Validate amount ---------------------------------------------------------
if ! [[ "$AMOUNT" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Amount must be a positive number (e.g. 25 or 0.001). Got: '$AMOUNT'" >&2
  exit 1
fi

# ---- Convert to base units ---------------------------------------------------
# amount * 10^decimals, integer — works for 6, 8, 18 dec via awk
AMOUNT_BASE=$(awk -v a="$AMOUNT" -v d="$DECIMALS" 'BEGIN { printf "%.0f", a * (10 ^ d) }')
if [[ -z "$AMOUNT_BASE" || "$AMOUNT_BASE" == "0" ]]; then
  echo "Amount too small — resolves to 0 base units at $DECIMALS decimals." >&2
  exit 1
fi

# 64-hex-char (32-byte) left-padded amount
AMOUNT_HEX=$(printf '%064x' "$AMOUNT_BASE")

# ---- Selectors (verified from CharityFund.sol) ------------------------------
SEL_APPROVE="095ea7b3"        # approve(address,uint256)
SEL_DEPOSIT="b6b55f25"        # deposit(uint256)
SEL_DEPOSITFOR="2f4f21e2"     # depositFor(address,uint256)

# ---- Build approve calldata: approve(fund, amount) ---------------------------
FUND_PADDED=$(printf '%064s' "${FUND#0x}" | tr ' ' '0')
APPROVE_DATA="0x${SEL_APPROVE}${FUND_PADDED}${AMOUNT_HEX}"

# ---- Build deposit / depositFor calldata -------------------------------------
if [[ -n "$RECIPIENT" ]]; then
  if ! [[ "$RECIPIENT" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo "Recipient must be a 0x address (40 hex chars). Got: '$RECIPIENT'" >&2
    exit 1
  fi
  TO_PADDED=$(printf '%064s' "${RECIPIENT#0x}" | tr ' ' '0')
  DEPOSIT_DATA="0x${SEL_DEPOSITFOR}${TO_PADDED}${AMOUNT_HEX}"
  MINT_TO="$RECIPIENT"
else
  DEPOSIT_DATA="0x${SEL_DEPOSIT}${AMOUNT_HEX}"
  MINT_TO="you"
fi

echo ""
echo "Meme for Trees — charity deposit"
echo "  Fund:       $FRIENDLY"
echo "  Address:    $FUND"
echo "  Deposit:    $AMOUNT (${ASSET}, chainId ${CHAIN_ID})"
echo "  Receipt to: $MINT_TO"
echo ""

# ---- Step 1: approve ---------------------------------------------------------
echo "Step 1/2: approving $AMOUNT to the fund..."
APPROVE_TX="{\"to\": \"$ASSET\", \"data\": \"$APPROVE_DATA\", \"value\": \"0\", \"chainId\": $CHAIN_ID}"
APPROVE_RESULT=$(bankr agent "Submit this transaction: $APPROVE_TX" 2>&1) || {
  echo "  Approve call to Bankr failed:" >&2
  echo "$APPROVE_RESULT" >&2
  exit 1
}
if echo "$APPROVE_RESULT" | grep -q "basescan.org/tx"; then
  APPROVE_HASH=$(echo "$APPROVE_RESULT" | grep -o 'https://basescan.org/tx/[^ "]*' | head -1)
  echo "  Approved: $APPROVE_HASH"
else
  echo "  Approve did not confirm. Bankr response:" >&2
  echo "$APPROVE_RESULT" >&2
  exit 1
fi

# ---- Step 2: deposit ---------------------------------------------------------
echo "Step 2/2: depositing..."
DEPOSIT_TX="{\"to\": \"$FUND\", \"data\": \"$DEPOSIT_DATA\", \"value\": \"0\", \"chainId\": $CHAIN_ID}"
DEPOSIT_RESULT=$(bankr agent "Submit this transaction: $DEPOSIT_TX" 2>&1) || {
  echo "  Deposit call to Bankr failed:" >&2
  echo "$DEPOSIT_RESULT" >&2
  exit 1
}
if echo "$DEPOSIT_RESULT" | grep -q "basescan.org/tx"; then
  DEPOSIT_HASH=$(echo "$DEPOSIT_RESULT" | grep -o 'https://basescan.org/tx/[^ "]*' | head -1)
  echo "  Deposited: $DEPOSIT_HASH"
else
  echo "  Deposit did not confirm. Bankr response:" >&2
  echo "$DEPOSIT_RESULT" >&2
  exit 1
fi

echo ""
echo "Done. You hold ~$AMOUNT $FRIENDLY receipt tokens (1:1, redeemable)."
