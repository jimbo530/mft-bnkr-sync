#!/usr/bin/env bash
# Create a community LP vault on Base via a FundVaultFactory.
# Requires two pre-approvals (underlying asset + token) then calls createVault.
# The factory deploys the vault clone, seeds liquidity, burns LP to 0xdead,
# and auto-registers the LP with the paired charity fund — all in one tx.
#
# Usage:
#   ./create-vault.sh <factory-key> <token> <seedAmount> <tokenAmount> <maxImpactBps>
#
#   factory-key   : mft-vault | char-r-vault | ccc-r-vault | prgt-vault | btc-t-vault | eth-t-vault
#   token         : 0x address of the community/meme token to pair
#   seedAmount    : seed of the underlying asset in RAW BASE UNITS
#                     USDC:  6 dec  (e.g. 20000000 = $20)
#                     cbBTC: 8 dec  (e.g. 32000 = 32000 sats)
#                     wETH: 18 dec  (e.g. 11500000000000000 = 0.0115 wETH)
#   tokenAmount   : amount of token in raw base units (sets initial price ratio)
#   maxImpactBps  : max price impact in bps (1-1500; 500 = 5%)
#
# Examples:
#   ./create-vault.sh mft-vault 0xYourToken 20000000 1000000000000000000 500
#   ./create-vault.sh btc-t-vault 0xYourToken 32000 1000000000000000000 500
#   ./create-vault.sh eth-t-vault 0xYourToken 11500000000000000 1000000000000000000 500
set -euo pipefail

if ! command -v bankr >/dev/null 2>&1; then
  echo "Bankr CLI not found. Install with: npm install -g @bankr/cli" >&2
  exit 1
fi

FACTORY_KEY="${1:-}"
TOKEN="${2:-}"
SEED_AMOUNT="${3:-}"
TOKEN_AMOUNT="${4:-}"
MAX_IMPACT="${5:-}"

usage() {
  cat >&2 <<'EOF'
Usage: ./create-vault.sh <factory-key> <token> <seedAmount> <tokenAmount> <maxImpactBps>
  factory-key  : mft-vault | char-r-vault | ccc-r-vault | prgt-vault | btc-t-vault | eth-t-vault
  token        : 0x community token address
  seedAmount   : seed underlying in raw base units (USDC 6dec, cbBTC 8dec, wETH 18dec)
  tokenAmount  : token amount in raw base units
  maxImpactBps : max price impact (1-1500; 500=5%)
EOF
}

if [[ -z "$FACTORY_KEY" || -z "$TOKEN" || -z "$SEED_AMOUNT" || -z "$TOKEN_AMOUNT" || -z "$MAX_IMPACT" ]]; then
  usage
  exit 1
fi

# ---- Factory registry (VERIFIED on-chain 2026-07-14; see references/factories.md) ----
# createVault(address token, uint256 seedAmount, uint256 tokenAmount, uint256 maxImpactBps)
# selector: 0x0eabcca1
case "$(echo "$FACTORY_KEY" | tr '[:upper:]' '[:lower:]')" in
  mft-vault)
    FACTORY="0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1"
    UNDERLYING="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC
    UNDERLYING_NAME="USDC"
    MIN_SEED="10000000"
    ;;
  char-r-vault)
    FACTORY="0x503fe2226ed8c93bC7864a3E59cEb2c64C305c64"
    UNDERLYING="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC
    UNDERLYING_NAME="USDC"
    MIN_SEED="20000000"
    ;;
  ccc-r-vault)
    FACTORY="0x4a2DFd07A13aBD64553d34F65074fc716D97C290"
    UNDERLYING="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC
    UNDERLYING_NAME="USDC"
    MIN_SEED="20000000"
    ;;
  prgt-vault)
    FACTORY="0xA54C86b545F6451c761Da684740bb390495170Df"
    UNDERLYING="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"   # USDC
    UNDERLYING_NAME="USDC"
    MIN_SEED="20000000"
    ;;
  btc-t-vault)
    FACTORY="0xA7BeD0d9963837E8426F241f132e1F8daEA6bD8B"
    UNDERLYING="0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"   # cbBTC
    UNDERLYING_NAME="cbBTC"
    MIN_SEED="32000"
    ;;
  eth-t-vault)
    FACTORY="0xc2Dbb3A02CF43270e3A69c2e15354887E094575f"
    UNDERLYING="0x4200000000000000000000000000000000000006"   # wETH
    UNDERLYING_NAME="wETH"
    MIN_SEED="11500000000000000"
    ;;
  *)
    echo "Unknown factory key: '$FACTORY_KEY'" >&2
    echo "Expected: mft-vault | char-r-vault | ccc-r-vault | prgt-vault | btc-t-vault | eth-t-vault" >&2
    usage
    exit 1
    ;;
esac

CHAIN_ID=8453

# Validate addresses
if ! [[ "$TOKEN" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  echo "Token must be a 0x address (40 hex chars). Got: '$TOKEN'" >&2
  exit 1
fi

# Validate numeric inputs
for VAR in SEED_AMOUNT TOKEN_AMOUNT MAX_IMPACT; do
  VAL="${!VAR}"
  if ! [[ "$VAL" =~ ^[0-9]+$ ]]; then
    echo "$VAR must be a positive integer (raw base units). Got: '$VAL'" >&2
    exit 1
  fi
done

# Minimum seed check
if (( SEED_AMOUNT < MIN_SEED )); then
  echo "seedAmount $SEED_AMOUNT is below minimum $MIN_SEED for $FACTORY_KEY." >&2
  exit 1
fi

if (( MAX_IMPACT < 1 || MAX_IMPACT > 1500 )); then
  echo "maxImpactBps must be 1-1500. Got: $MAX_IMPACT" >&2
  exit 1
fi

# ---- Encode hex values (64-char / 32-byte left-padded) ----------------------
factory_padded=$(printf '%064s' "${FACTORY#0x}" | tr ' ' '0')
token_padded=$(printf '%064s' "${TOKEN#0x}" | tr ' ' '0')
# Convert decimal integers to hex (portable via printf)
seed_hex=$(printf '%064x' "$SEED_AMOUNT")
token_hex=$(printf '%064x' "$TOKEN_AMOUNT")
impact_hex=$(printf '%064x' "$MAX_IMPACT")
underlying_padded=$(printf '%064s' "${UNDERLYING#0x}" | tr ' ' '0')

# Selectors
SEL_APPROVE="095ea7b3"       # approve(address,uint256)
SEL_CREATE="0eabcca1"        # createVault(address,uint256,uint256,uint256)

echo ""
echo "Meme for Trees — create LP vault"
echo "  Factory:      $FACTORY_KEY ($FACTORY)"
echo "  Token:        $TOKEN"
echo "  Underlying:   $UNDERLYING_NAME ($UNDERLYING)"
echo "  Seed amount:  $SEED_AMOUNT (raw)"
echo "  Token amount: $TOKEN_AMOUNT (raw)"
echo "  Max impact:   $MAX_IMPACT bps"
echo ""
echo "This will: approve underlying + approve token + createVault (3 txs)"
echo "LP seeding LP tokens are burned permanently to 0xdead. Verify price ratio before proceeding."
echo ""
read -r -p "Proceed? (y/N) " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then
  echo "Aborted." >&2
  exit 1
fi

# ---- Step 1: approve underlying to factory -----------------------------------
echo ""
echo "Step 1/3: approving $UNDERLYING_NAME to factory..."
approve_underlying_data="0x${SEL_APPROVE}${factory_padded}${seed_hex}"
TX="{\"to\": \"$UNDERLYING\", \"data\": \"$approve_underlying_data\", \"value\": \"0\", \"chainId\": $CHAIN_ID}"
RESULT=$(bankr agent "Submit this transaction: $TX" 2>&1) || { echo "Approve underlying failed:" >&2; echo "$RESULT" >&2; exit 1; }
if echo "$RESULT" | grep -q "basescan.org/tx"; then
  echo "  OK: $(echo "$RESULT" | grep -o 'https://basescan.org/tx/[^ "]*' | head -1)"
else
  echo "Approve underlying did not confirm:" >&2; echo "$RESULT" >&2; exit 1
fi

# ---- Step 2: approve token to factory ----------------------------------------
echo "Step 2/3: approving token to factory..."
approve_token_data="0x${SEL_APPROVE}${factory_padded}${token_hex}"
TX="{\"to\": \"$TOKEN\", \"data\": \"$approve_token_data\", \"value\": \"0\", \"chainId\": $CHAIN_ID}"
RESULT=$(bankr agent "Submit this transaction: $TX" 2>&1) || { echo "Approve token failed:" >&2; echo "$RESULT" >&2; exit 1; }
if echo "$RESULT" | grep -q "basescan.org/tx"; then
  echo "  OK: $(echo "$RESULT" | grep -o 'https://basescan.org/tx/[^ "]*' | head -1)"
else
  echo "Approve token did not confirm:" >&2; echo "$RESULT" >&2; exit 1
fi

# ---- Step 3: createVault -----------------------------------------------------
echo "Step 3/3: calling createVault..."
create_data="0x${SEL_CREATE}${token_padded}${seed_hex}${token_hex}${impact_hex}"
TX="{\"to\": \"$FACTORY\", \"data\": \"$create_data\", \"value\": \"0\", \"chainId\": $CHAIN_ID}"
RESULT=$(bankr agent "Submit this transaction: $TX" 2>&1) || { echo "createVault failed:" >&2; echo "$RESULT" >&2; exit 1; }
if echo "$RESULT" | grep -q "basescan.org/tx"; then
  echo "  OK: $(echo "$RESULT" | grep -o 'https://basescan.org/tx/[^ "]*' | head -1)"
  echo ""
  echo "Done. Vault deployed + LP seeded + LP burned to 0xdead."
  echo "Check the tx on basescan for the VaultCreated event to get the vault address."
else
  echo "createVault did not confirm:" >&2; echo "$RESULT" >&2; exit 1
fi
