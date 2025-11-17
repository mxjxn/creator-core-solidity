# Deploy and Mint Collection Script

This script deploys a new ERC721 collection on testnet and mints all NFTs to a specified address.

## Quick Start

### Step 1: Set Environment Variables

```bash
# Required: Your deployer private key (without 0x prefix)
export PRIVATE_KEY=your_private_key_here

# Required: Address to receive all NFTs
export MINT_TO=0x6dA173B1d50F7Bc5c686f8880C20378965408344

# Optional: RPC URL (defaults to Base Sepolia testnet)
export RPC_URL=https://sepolia.base.org

# Optional: Collection name (default: "Test Collection")
export CONTRACT_NAME="My Collection"

# Optional: Collection symbol (default: "TEST")
export CONTRACT_SYMBOL="MC"

# Optional: Number of NFTs to mint (default: 100)
export NFT_COUNT=100
```

### Step 2: Run the Script

```bash
cd packages/creator-core-contracts
./script/deploy-and-mint.sh
```

Or run directly with forge:

```bash
cd packages/creator-core-contracts
forge script script/DeployAndMintCollection.s.sol:DeployAndMintCollection \
    --rpc-url $RPC_URL \
    --broadcast \
    -vvv
```

## What It Does

1. **Deploys** a new ERC721Creator contract on testnet
2. **Mints** all NFTs (default: 100) to the specified address
3. **Verifies** that all NFTs are owned by the target address
4. **Prints** a summary with the collection address and token IDs

## Example Output

```
==========================================
Deploying Collection and Minting NFTs
==========================================
Collection Name: Test Collection
Collection Symbol: TEST
Mint To: 0x6dA173B1d50F7Bc5c686f8880C20378965408344
NFT Count: 100
==========================================
Deploying ERC721Creator...
Collection deployed at: 0x...
Owner: 0x...
Minting NFTs...
Minting complete!
First token ID: 1
Last token ID: 100
Total tokens minted: 100
Verifying ownership...
All NFTs verified to be owned by: 0x6dA173B1d50F7Bc5c686f8880C20378965408344
==========================================
            DEPLOYMENT SUMMARY
==========================================
Collection Address: 0x...
Collection Name: Test Collection
Collection Symbol: TEST
Total Supply: 100
All NFTs owned by: 0x6dA173B1d50F7Bc5c686f8880C20378965408344
Token IDs: 1 - 100
==========================================
```

## Network Support

The script works with any EVM-compatible testnet. Default RPC URLs:

- **Base Sepolia**: `https://sepolia.base.org`
- **Ethereum Sepolia**: `https://sepolia.infura.io/v3/YOUR_API_KEY`
- **Local Anvil**: `http://localhost:8545`

## Notes

- Make sure you have enough testnet ETH for gas fees
- The deployer address will be the owner of the collection contract
- All NFTs will be minted sequentially starting from token ID 1
- The script verifies ownership after minting to ensure everything worked correctly

