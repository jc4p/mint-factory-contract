#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment from .env file"
    export $(grep -v '^#' .env | xargs)
fi

# Default configuration
DEFAULT_BASE_URI="https://fc-nfts.kasra.codes/tokens/"
DEFAULT_NFT_NAME="Generic Farcaster NFT"
DEFAULT_NFT_SYMBOL="GNFT"
DEFAULT_MINT_PRICE="0.0025 ether"
DEFAULT_PAYMENT_RECIPIENT=""  # Will default to sender in the contract
DEFAULT_MAX_SUPPLY=0  # 0 means unlimited supply
DEFAULT_CHAIN_ID=8453  # Base chain
DEFAULT_COMPILER_VERSION="0.8.28"
DEFAULT_VERIFY_NEEDED="false"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-uri)
            BASE_URI="$2"
            shift 2
            ;;
        --name)
            NFT_NAME="$2"
            shift 2
            ;;
        --symbol)
            NFT_SYMBOL="$2"
            shift 2
            ;;
        --price)
            MINT_PRICE="$2"
            shift 2
            ;;
        --recipient)
            PAYMENT_RECIPIENT="$2"
            shift 2
            ;;
        --max-supply)
            MAX_SUPPLY="$2"
            shift 2
            ;;
        --chain-id)
            CHAIN_ID="$2"
            shift 2
            ;;
        --compiler)
            COMPILER_VERSION="$2"
            shift 2
            ;;
        --rpc-url)
            RPC_URL="$2"
            shift 2
            ;;
        --private-key)
            PRIVATE_KEY="$2"
            shift 2
            ;;
        --api-key)
            BASESCAN_API_KEY="$2"
            shift 2
            ;;
        --manual-verify)
            VERIFY_NEEDED="true"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Use environment variables if provided, otherwise use defaults
BASE_URI="${BASE_URI:-$DEFAULT_BASE_URI}"
NFT_NAME="${NFT_NAME:-$DEFAULT_NFT_NAME}"
NFT_SYMBOL="${NFT_SYMBOL:-$DEFAULT_NFT_SYMBOL}"
MINT_PRICE="${MINT_PRICE:-$DEFAULT_MINT_PRICE}"
PAYMENT_RECIPIENT="${PAYMENT_RECIPIENT:-$DEFAULT_PAYMENT_RECIPIENT}"
MAX_SUPPLY="${MAX_SUPPLY:-$DEFAULT_MAX_SUPPLY}"
CHAIN_ID="${CHAIN_ID:-$DEFAULT_CHAIN_ID}"
COMPILER_VERSION="${COMPILER_VERSION:-$DEFAULT_COMPILER_VERSION}"
VERIFY_NEEDED="${VERIFY_NEEDED:-$DEFAULT_VERIFY_NEEDED}"

# Required environment variables
if [ -z "$RPC_URL" ]; then
    echo "Error: RPC_URL is required (via environment variable or --rpc-url)"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY is required (via environment variable or --private-key)"
    exit 1
fi

if [ -z "$BASESCAN_API_KEY" ]; then
    echo "Error: BASESCAN_API_KEY is required (via environment variable or --api-key)"
    exit 1
fi

echo "Deploying contract with the following parameters:"
echo "NFT Name: $NFT_NAME"
echo "NFT Symbol: $NFT_SYMBOL"
echo "Base URI: $BASE_URI"
echo "Mint Price: $MINT_PRICE"
echo "Max Supply: $MAX_SUPPLY"
if [ -n "$PAYMENT_RECIPIENT" ]; then
    echo "Payment Recipient: $PAYMENT_RECIPIENT"
else
    echo "Payment Recipient: <deployer address>"
fi

# Deploy the contract
echo "Deploying contract..."
echo "Setting environment variables for deployment..."
export BASE_URI="$BASE_URI"
export NFT_NAME="$NFT_NAME"
export NFT_SYMBOL="$NFT_SYMBOL"
export MINT_PRICE="$MINT_PRICE"
export PAYMENT_RECIPIENT="$PAYMENT_RECIPIENT"
export MAX_SUPPLY="$MAX_SUPPLY"

DEPLOY_OUTPUT=$(forge script script/GenericFarcasterNFT.s.sol:GenericFarcasterNFT_Script \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast \
    --verify \
    --etherscan-api-key "$BASESCAN_API_KEY" \
    --chain-id "$CHAIN_ID")

# Extract contract address from deployment output
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP "Deployed GenericFarcasterNFT at: \K0x[a-fA-F0-9]{40}")

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Failed to extract contract address from deployment output"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

echo "Contract deployed at: $CONTRACT_ADDRESS"

# With --verify flag, verification is handled automatically during deployment
# This block is for manual verification if needed
if [ "$VERIFY_NEEDED" = "true" ]; then
    echo "Verifying contract on Basescan..."
    forge verify-contract --chain-id "$CHAIN_ID" --watch --compiler-version "$COMPILER_VERSION" \
        "$CONTRACT_ADDRESS" src/GenericFarcasterNFT.sol:GenericFarcasterNFT \
        --etherscan-api-key "$BASESCAN_API_KEY" \
        --constructor-args "$(cast abi-encode "constructor(string,string,string,uint256,address,uint256)" \
        "$BASE_URI" "$NFT_NAME" "$NFT_SYMBOL" "$MINT_PRICE" "$PAYMENT_RECIPIENT" "$MAX_SUPPLY")"
else
    echo "Contract verification was handled during deployment with --verify flag"
fi

echo "✅ Contract successfully deployed and verified!"
echo "Contract address: $CONTRACT_ADDRESS"
echo "View on Basescan: https://basescan.org/address/$CONTRACT_ADDRESS"

# Print usage instructions
# echo ""
# echo "Usage instructions:"
# echo "  1. From environment variables (.env file):"
# echo "     ./deploy-and-verify.sh"
# echo ""
# echo "  2. Using command line arguments:"
# echo "     ./deploy-and-verify.sh --name \"My NFT\" --symbol \"MNFT\" --base-uri \"https://example.com/tokens/\" \\"
# echo "                           --price \"0.05 ether\" --recipient \"0x1234...\" --max-supply 5000 \\"
# echo "                           --rpc-url \"https://...\" --private-key \"0x...\" --api-key \"...\""
# echo "     # Note: Use --max-supply 0 for unlimited supply"
# echo ""
# echo "  3. Mixed approach (some from .env, some from command line):"
# echo "     ./deploy-and-verify.sh --name \"My NFT\" --price \"0.1 ether\""
# echo ""
