#!/usr/bin/env bash
# Deploy a new CharityFund clone via CharityFundFactory on Base.
# No asset transfer needed — only ETH for gas.
# The new fund is immediately ready to accept deposit(uint256) calls.
#
# Usage:
#   ./create-fund.sh <name> <symbol> <charityWallet> <charityBps>
#
#   name          : token name  (e.g. "My Charity Token")
#   symbol        : token symbol (e.g. "MCT")
#   charityWallet : 0x address that receives the charity's USDC yield share
#   charityBps    : charity yield share in basis points (min 1000=10%; max determined
#                   by factory's serviceBps: charityBps + serviceBps <= 9000)
#
# Example:
#   ./create-fund.sh "Rainforest Trust" RFT 0xCharityWalletAddress 5000
#   # 50% charity, factory serviceBps, remainder to holders
#
# ABI:
#   createFund(string name_, string symbol_, address charityWallet, uint16 charityBps)
#   selector: 0x5c275a39
set -euo pipefail

if ! command -v bankr >/dev/null 2>&1; then
  echo "Bankr CLI not found. Install with: npm install -g @bankr/cli" >&2
  exit 1
fi

FUND_NAME="${1:-}"
FUND_SYMBOL="${2:-}"
CHARITY_WALLET="${3:-}"
CHARITY_BPS="${4:-}"

usage() {
  cat >&2 <<'EOF'
Usage: ./create-fund.sh <name> <symbol> <charityWallet> <charityBps>
  name          : token name  (e.g. "My Charity Token")
  symbol        : token symbol (e.g. "MCT")
  charityWallet : 0x address to receive charity's USDC yield share
  charityBps    : charity share in basis points (min 1000=10%, e.g. 3334=33.34%)

Example:
  ./create-fund.sh "Rainforest Trust" RFT 0xCharityAddress 5000
EOF
}

if [[ -z "$FUND_NAME" || -z "$FUND_SYMBOL" || -z "$CHARITY_WALLET" || -z "$CHARITY_BPS" ]]; then
  usage
  exit 1
fi

# ---- Validate ------------------------------------------------------------------
if ! [[ "$CHARITY_WALLET" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  echo "charityWallet must be a 0x address (40 hex chars). Got: '$CHARITY_WALLET'" >&2
  exit 1
fi
if ! [[ "$CHARITY_BPS" =~ ^[0-9]+$ ]] || (( CHARITY_BPS < 1000 )) || (( CHARITY_BPS > 9000 )); then
  echo "charityBps must be an integer 1000-9000 (10%-90%). Got: '$CHARITY_BPS'" >&2
  exit 1
fi

# ---- Constants ------------------------------------------------------------------
FACTORY="0x955383723E8A1AD82800406D6f492260918DF882"   # CharityFundFactory (Base, verified 2026-07-14)
CHAIN_ID=8453

# ---- ABI-encode createFund(string,string,address,uint16) ---------------------
# Selector: 0x5c275a39
# ABI encoding for (string, string, address, uint16):
#   - 4-byte selector
#   - offset to name  (dynamic, = 0x80 = 4th slot after 4 fixed slots... actually:
#     ABI tuple = [offset_name, offset_symbol, address_padded, charityBps_padded])
#   - offset to symbol
#   - charityWallet (address, 32 bytes)
#   - charityBps (uint16, 32 bytes)
#   - name length + data (padded to 32)
#   - symbol length + data (padded to 32)

# Because this requires dynamic ABI encoding (string params), we use a Bankr
# natural-language call rather than raw calldata to avoid brittle manual encoding.
# The agent interprets the structured call and handles ABI encoding correctly.
#
# If you need raw calldata, see references/abi.json and use ethers.js:
#   iface.encodeFunctionData("createFund", [name, symbol, wallet, bps])

echo ""
echo "Meme for Trees — create CharityFund clone"
echo "  Factory:       $FACTORY (CharityFundFactory, Base)"
echo "  Name:          $FUND_NAME"
echo "  Symbol:        $FUND_SYMBOL"
echo "  Charity wallet: $CHARITY_WALLET"
echo "  Charity share: $CHARITY_BPS bps ($(awk -v b="$CHARITY_BPS" 'BEGIN{printf "%.2f%%", b/100}'))"
echo ""
echo "Infrastructure inherited from factory (immutable once deployed):"
echo "  Deposit asset: USDC 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
echo "  Aave V3:       0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"
echo "  Reactor:       0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA"
echo ""
read -r -p "Proceed? (y/N) " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then
  echo "Aborted." >&2
  exit 1
fi

echo ""
echo "Calling CharityFundFactory.createFund via Bankr..."
RESULT=$(bankr agent "Call createFund on contract $FACTORY on Base (chainId 8453) with arguments: name=\"$FUND_NAME\", symbol=\"$FUND_SYMBOL\", charityWallet=$CHARITY_WALLET, charityBps=$CHARITY_BPS. ABI: {\"name\":\"createFund\",\"type\":\"function\",\"stateMutability\":\"nonpayable\",\"inputs\":[{\"name\":\"name_\",\"type\":\"string\"},{\"name\":\"symbol_\",\"type\":\"string\"},{\"name\":\"charityWallet\",\"type\":\"address\"},{\"name\":\"charityBps\",\"type\":\"uint16\"}],\"outputs\":[{\"name\":\"fund\",\"type\":\"address\"}]}" 2>&1) || {
  echo "createFund call to Bankr failed:" >&2
  echo "$RESULT" >&2
  exit 1
}
echo "$RESULT"
if echo "$RESULT" | grep -q "basescan.org/tx"; then
  echo ""
  echo "Done. CharityFund clone deployed."
  echo "Check the tx on basescan for the FundCreated event to get the new fund address."
  echo "The new fund accepts deposit(uint256) immediately (USDC at 6 dec)."
else
  echo ""
  echo "Note: confirm success on basescan. If Bankr could not encode the string args," >&2
  echo "use ethers.js with the ABI in references/abi.json to build raw calldata." >&2
fi
