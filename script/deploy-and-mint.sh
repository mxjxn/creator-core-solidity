#!/bin/bash

# Deployment script to deploy a new collection on testnet and mint all NFTs to a specified address
# Usage: ./script/deploy-and-mint.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load and export environment variables from .env.local if it exists
if [ -f .env.local ]; then
    print_info "Loading environment variables from .env.local..."
    set -a  # Automatically export all variables
    source .env.local
    set +a  # Turn off automatic export
fi

# Strip quotes from MNEMONIC if present (handles both single and double quotes from .env files)
if [ -n "$MNEMONIC" ]; then
    MNEMONIC=$(echo "$MNEMONIC" | sed "s/^[[:space:]]*['\"]//; s/['\"][[:space:]]*$//; s/^[[:space:]]*//; s/[[:space:]]*$//")
fi

# Debug: Show what we found (mask sensitive values)
if [ -n "$MNEMONIC" ]; then
    MNEMONIC_PREVIEW=$(echo "$MNEMONIC" | awk '{print $1 " " $2 " ... " $NF}')
    print_info "Found MNEMONIC: $MNEMONIC_PREVIEW"
fi
if [ -n "$MNEMONIC_INDEX" ]; then
    print_info "Found MNEMONIC_INDEX: $MNEMONIC_INDEX"
fi
if [ -n "$PRIVATE_KEY" ]; then
    print_info "Found PRIVATE_KEY"
fi

# Derive private key from mnemonic if provided
if [ -n "$MNEMONIC" ]; then
    # Use MNEMONIC_INDEX if set, otherwise default to 0
    MNEMONIC_INDEX=${MNEMONIC_INDEX:-0}
    export MNEMONIC_INDEX  # Export for forge script
    export MNEMONIC  # Export for forge script (after quote stripping)
    
    print_info "Using MNEMONIC to derive private key (index $MNEMONIC_INDEX)..."
    DERIVED_PRIVATE_KEY=$(cast wallet private-key "$MNEMONIC" $MNEMONIC_INDEX 2>/dev/null || echo "")
    
    if [ -n "$DERIVED_PRIVATE_KEY" ]; then
        PRIVATE_KEY="$DERIVED_PRIVATE_KEY"
        DERIVED_ADDRESS=$(cast wallet address $PRIVATE_KEY 2>/dev/null || echo "")
        print_info "✓ Derived private key from mnemonic (index $MNEMONIC_INDEX)"
        print_info "  Address: $DERIVED_ADDRESS"
        
        # Use derived address as MINT_TO if not explicitly set
        if [ -z "$MINT_TO" ]; then
            MINT_TO="$DERIVED_ADDRESS"
            print_info "Using derived address as MINT_TO: $MINT_TO"
        fi
    else
        print_error "Could not derive private key from mnemonic at index $MNEMONIC_INDEX!"
        exit 1
    fi
elif [ -z "$PRIVATE_KEY" ]; then
    print_error "Either PRIVATE_KEY or MNEMONIC environment variable must be set"
    print_info "Set PRIVATE_KEY with: export PRIVATE_KEY=your_private_key"
    print_info "Or set MNEMONIC with: export MNEMONIC=\"your twelve word seed phrase\""
    exit 1
fi

# Set default RPC URL for Base Sepolia testnet
RPC_URL=${RPC_URL:-"https://sepolia.base.org"}
print_info "Using RPC URL: $RPC_URL"

# Set default values
CONTRACT_NAME=${CONTRACT_NAME:-"Radical Testers"}
CONTRACT_SYMBOL=${CONTRACT_SYMBOL:-"RT"}
NFT_COUNT=${NFT_COUNT:-100}

# Use derived address if MINT_TO still not set
if [ -z "$MINT_TO" ] && [ -n "$DERIVED_ADDRESS" ]; then
    MINT_TO="$DERIVED_ADDRESS"
fi

print_info "Configuration:"
print_info "  Collection Name: $CONTRACT_NAME"
print_info "  Collection Symbol: $CONTRACT_SYMBOL"
print_info "  Mint To: $MINT_TO"
print_info "  NFT Count: $NFT_COUNT"
print_info "  RPC URL: $RPC_URL"

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    print_error "forge command not found. Please install Foundry."
    print_info "Install from: https://book.getfoundry.sh/getting-started/installation"
    exit 1
fi

# Build contracts first
print_info "Building contracts..."
forge build

# Deploy and mint
print_info "Deploying collection and minting NFTs..."

forge script script/DeployAndMintCollection.s.sol:DeployAndMintCollection \
    --rpc-url $RPC_URL \
    --broadcast \
    -vvv

print_info "Deployment complete!"

