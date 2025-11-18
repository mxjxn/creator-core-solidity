# Getting Started with Creator Core Contracts

This guide will help you get started with deploying and using Creator Core contracts for your NFT project.

## Installation

### Using npm

```bash
npm install @manifoldxyz/creator-core-solidity
```

### Using Foundry

Add to your `remappings.txt`:
```
@manifoldxyz/creator-core-solidity/=node_modules/@manifoldxyz/creator-core-solidity/contracts/
```

Or install as a git submodule:
```bash
forge install manifoldxyz/creator-core-solidity
```

## Quick Start

### Deploying an ERC721 Contract

```solidity
pragma solidity ^0.8.17;

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

contract MyNFTCollection is ERC721Creator {
    constructor() ERC721Creator("My NFT Collection", "MNFT") {}
}
```

### Deploying an ERC1155 Contract

```solidity
pragma solidity ^0.8.17;

import "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";

contract MyMultiTokenCollection is ERC1155Creator {
    constructor() ERC1155Creator("My Multi Token", "MMT") {}
}
```

## Contract Selection Guide

### When to Use ERC721 vs ERC1155

**Use ERC721Creator when:**
- Each token is unique (1/1s)
- You need individual token metadata
- You want standard NFT behavior
- Gas cost per mint is acceptable

**Use ERC1155Creator when:**
- You have multiple editions of the same artwork
- You want to batch mint efficiently
- You need fungible-like tokens with metadata
- You want to reduce gas costs for multi-token operations

### When to Use Upgradeable vs Non-Upgradeable

**Use Non-Upgradeable (ERC721Creator/ERC1155Creator) when:**
- You're confident in your contract design
- You want lower deployment costs
- You prefer immutability
- You're deploying simple collections

**Use Upgradeable (ERC721CreatorUpgradeable/ERC1155CreatorUpgradeable) when:**
- You may need to fix bugs post-deployment
- You want to add features later
- You're deploying to production
- You need flexibility for future changes

**Note:** Upgradeable contracts require proxy deployment and have slightly higher gas costs.

## Basic Operations

### Minting Tokens

#### ERC721 - Single Token

```solidity
// Mint a single token (admin only)
uint256 tokenId = myContract.mintBase(toAddress);

// Mint with custom URI
uint256 tokenId = myContract.mintBase(toAddress, "ipfs://Qm...");

// Batch mint
uint256[] memory tokenIds = myContract.mintBaseBatch(toAddress, 10);
```

#### ERC1155 - Multi-Token

```solidity
// Mint new token to multiple recipients
address[] memory recipients = new address[](2);
recipients[0] = address1;
recipients[1] = address2;
uint256[] memory amounts = new uint256[](1);
amounts[0] = 1;
string[] memory uris = new string[](0);

uint256[] memory tokenIds = myContract.mintBaseNew(recipients, amounts, uris);

// Mint existing token
uint256[] memory tokenIds = new uint256[](1);
tokenIds[0] = 1;
myContract.mintBaseExisting(recipients, tokenIds, amounts);
```

### Setting Token URIs

```solidity
// Set base URI for all tokens
myContract.setBaseTokenURI("https://api.example.com/metadata/");

// Set URI for specific token
myContract.setTokenURI(tokenId, "ipfs://Qm...");

// Set URI prefix (useful for IPFS/Arweave)
myContract.setTokenURIPrefix("ipfs://");
```

### Configuring Royalties

```solidity
// Set default royalties (applies to all tokens)
address payable[] memory receivers = new address payable[](1);
receivers[0] = payable(creatorAddress);
uint256[] memory basisPoints = new uint256[](1);
basisPoints[0] = 500; // 5%

myContract.setRoyalties(receivers, basisPoints);

// Set royalties for specific token
myContract.setRoyalties(tokenId, receivers, basisPoints);
```

### Registering Extensions

```solidity
// Register an extension contract
myContract.registerExtension(extensionAddress, "https://api.example.com/extension/");

// Register with identical base URI flag
myContract.registerExtension(extensionAddress, "https://api.example.com/", true);

// Unregister an extension
myContract.unregisterExtension(extensionAddress);
```

## Extension Registration Examples

### Basic Extension Registration

```solidity
// 1. Deploy your extension contract
MyExtension extension = new MyExtension();

// 2. Register it with your Creator Core contract
myContract.registerExtension(address(extension), "");

// 3. Extension can now mint tokens
uint256 tokenId = myContract.mintExtension(toAddress);
```

### Extension with Custom Base URI

```solidity
// Register extension with base URI
myContract.registerExtension(
    address(extension),
    "ipfs://QmBaseHash/",
    false // baseURIIdentical = false means each token gets unique URI
);
```

### Setting Extension Royalties

```solidity
address payable[] memory receivers = new address payable[](1);
receivers[0] = payable(extensionOwner);
uint256[] memory basisPoints = new uint256[](1);
basisPoints[0] = 750; // 7.5%

myContract.setRoyaltiesExtension(address(extension), receivers, basisPoints);
```

## Common Patterns

### Pattern 1: Simple 1/1 Collection

```solidity
contract SimpleCollection is ERC721Creator {
    constructor() ERC721Creator("My Collection", "MC") {}
    
    function mintTo(address to, string memory uri) external {
        require(owner() == msg.sender, "Not owner");
        mintBase(to, uri);
    }
}
```

### Pattern 2: Limited Edition

```solidity
contract LimitedEdition is ERC1155Creator {
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant TOKEN_ID = 1;
    
    constructor() ERC1155Creator("Limited Edition", "LE") {}
    
    function mint(address to, uint256 amount) external {
        require(owner() == msg.sender, "Not owner");
        require(totalSupply(TOKEN_ID) + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        address[] memory toArray = new address[](1);
        toArray[0] = to;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        
        mintBaseExisting(toArray, tokenIds, amounts);
    }
}
```

### Pattern 3: Extension-Based Minting

```solidity
contract MyMintingExtension {
    ICreatorCore public creatorCore;
    
    constructor(address _creatorCore) {
        creatorCore = ICreatorCore(_creatorCore);
    }
    
    function mintWithValidation(address to, string memory uri) external {
        // Your custom validation logic
        require(isValidMint(to), "Invalid mint");
        
        // Mint via extension
        IERC721CreatorCore(address(creatorCore)).mintExtension(to, uri);
    }
}
```

## Next Steps

- Read the [Deployment Guide](./DEPLOYMENT_GUIDE.md) for detailed deployment instructions
- Check the [Integration Guide](./INTEGRATION_GUIDE.md) for integrating with marketplaces and other systems
- Explore [extension examples](https://github.com/manifoldxyz/creator-core-extensions-solidity) for advanced functionality
- Understand the [Architecture](./ARCHITECTURE.md) to learn how the contracts work internally

