# Integration Guide

This guide covers integrating Creator Core contracts with marketplaces, extensions, and other systems.

## Table of Contents

- [Marketplace Integration](#marketplace-integration)
- [Extension Development](#extension-development)
- [Royalties Setup](#royalties-setup)
- [Token URI Management](#token-uri-management)
- [Publishing Pipelines](#publishing-pipelines)
- [Best Practices](#best-practices)

## Marketplace Integration

### Auctionhouse Integration

The auctionhouse contracts support lazy minting and dynamic pricing. See the [Auctionhouse Integration Guide](../auctionhouse-contracts/INTEGRATION_GUIDE.md) for detailed instructions.

#### Quick Setup

```solidity
// 1. Deploy lazy delivery adapter
ERC721CreatorLazyDelivery adapter = new ERC721CreatorLazyDelivery(creatorContract);

// 2. Register adapter as extension
ICreatorCore(creatorContract).registerExtension(address(adapter), "");

// 3. Authorize marketplace
adapter.setAuthorizedMarketplace(marketplaceAddress, true);

// 4. Create listing with lazy=true
// (See auctionhouse integration guide for full example)
```

### OpenSea Seaport Integration

Seaport is OpenSea's marketplace protocol. To integrate:

#### 1. Install Seaport Contracts

```bash
npm install @opensea/seaport-js
```

#### 2. Create Seaport Order

```javascript
const { Seaport } = require("@opensea/seaport-js");
const { ethers } = require("ethers");

const seaport = new Seaport(provider, {
  seaportVersion: "1.5",
});

// Create order for ERC721 token
const { executeAllActions } = await seaport.createSellOrder({
  asset: {
    tokenAddress: creatorContractAddress,
    tokenId: tokenId,
    schemaName: "ERC721",
  },
  accountAddress: sellerAddress,
  startAmount: ethers.utils.parseEther("1.0"),
  endAmount: ethers.utils.parseEther("1.0"),
  expirationTime: Math.floor(Date.now() / 1000) + 86400, // 24 hours
});
```

#### 3. Approve Seaport

```solidity
// Approve Seaport contract to transfer tokens
IERC721(creatorContract).approve(seaportAddress, tokenId);
```

### Generic Marketplace Integration

For any marketplace, ensure your contract:

1. **Implements EIP-2981** (royalties)
2. **Supports standard transfers** (ERC721/ERC1155)
3. **Emits Transfer events** (standard)
4. **Has verified source code** (for trust)

## Extension Development

### Creating a Basic Extension

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

contract MyExtension is CreatorExtension, ICreatorExtensionTokenURI {
    IERC721CreatorCore public creatorCore;
    mapping(uint256 => string) private _tokenURIs;
    
    constructor(address _creatorCore) {
        creatorCore = IERC721CreatorCore(_creatorCore);
    }
    
    function mintWithCustomURI(address to, string memory uri) external {
        uint256 tokenId = creatorCore.mintExtension(to);
        _tokenURIs[tokenId] = uri;
    }
    
    function tokenURI(address creator, uint256 tokenId) 
        external 
        view 
        override 
        returns (string memory) 
    {
        return _tokenURIs[tokenId];
    }
}
```

### Extension Interfaces

#### ICreatorExtensionTokenURI

Override token URI generation:

```solidity
interface ICreatorExtensionTokenURI {
    function tokenURI(address creator, uint256 tokenId) 
        external 
        view 
        returns (string memory);
}
```

#### ICreatorExtensionRoyalties

Set royalties for extension-minted tokens:

```solidity
interface ICreatorExtensionRoyalties {
    function getRoyalties(address creator, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}
```

#### IERC721CreatorExtensionApproveTransfer

Control transfers before they execute:

```solidity
interface IERC721CreatorExtensionApproveTransfer {
    function approveTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external returns (bool);
}
```

### Registering Your Extension

```solidity
// After deploying extension
creatorCore.registerExtension(address(myExtension), "https://api.example.com/");

// Extension can now mint tokens
uint256 tokenId = creatorCore.mintExtension(toAddress);
```

## Royalties Setup

### Setting Default Royalties

```solidity
address payable[] memory receivers = new address payable[](1);
receivers[0] = payable(0x1234...); // Creator address
uint256[] memory basisPoints = new uint256[](1);
basisPoints[0] = 500; // 5%

creatorCore.setRoyalties(receivers, basisPoints);
```

### Per-Token Royalties

```solidity
// Set royalties for specific token
creatorCore.setRoyalties(
    tokenId,
    receivers,
    basisPoints
);
```

### Extension-Level Royalties

```solidity
// All tokens minted by this extension get these royalties
creatorCore.setRoyaltiesExtension(
    address(extension),
    receivers,
    basisPoints
);
```

### Royalty Standards Supported

- **EIP-2981**: `royaltyInfo(uint256 tokenId, uint256 salePrice)`
- **Manifold Royalty Registry**: Via `getRoyalties()`
- **Rarible V2**: Via `getFeeRecipients()` and `getFeeBps()`

## Token URI Management

### Base URI Pattern

```solidity
// Set base URI
creatorCore.setBaseTokenURI("https://api.example.com/metadata/");

// Token 1 URI: https://api.example.com/metadata/1
// Token 2 URI: https://api.example.com/metadata/2
```

### Prefix Pattern (IPFS/Arweave)

```solidity
// Set prefix
creatorCore.setTokenURIPrefix("ipfs://");

// Set token URI (without prefix)
creatorCore.setTokenURI(tokenId, "QmHash...");

// Final URI: ipfs://QmHash...
```

### Per-Token URIs

```solidity
// Set individual token URI
creatorCore.setTokenURI(tokenId, "https://example.com/token/1.json");

// Batch set
uint256[] memory tokenIds = new uint256[](3);
tokenIds[0] = 1;
tokenIds[1] = 2;
tokenIds[2] = 3;

string[] memory uris = new string[](3);
uris[0] = "https://example.com/token/1.json";
uris[1] = "https://example.com/token/2.json";
uris[2] = "https://example.com/token/3.json";

creatorCore.setTokenURI(tokenIds, uris);
```

### Extension Token URIs

Extensions can override token URIs:

```solidity
// In your extension
function tokenURI(address creator, uint256 tokenId) 
    external 
    view 
    override 
    returns (string memory) 
{
    // Dynamic URI generation
    return string(abi.encodePacked(
        "https://api.example.com/token/",
        Strings.toString(tokenId),
        "?timestamp=",
        Strings.toString(block.timestamp)
    ));
}
```

## Publishing Pipelines

### Pipeline 1: 1/1 → Auction

```solidity
// 1. Create and mint 1/1 NFT
uint256 tokenId = creatorCore.mintBase(creator, "ipfs://...");

// 2. Transfer to auctionhouse (or use lazy minting)
IERC721(creatorContract).transferFrom(creator, auctionhouse, tokenId);

// 3. Create auction listing
// (See auctionhouse integration guide)
```

### Pipeline 2: Edition → Fixed Price

```solidity
// 1. Create edition (ERC1155)
address[] memory to = new address[](1);
to[0] = creator;
uint256[] memory amounts = new uint256[](1);
amounts[0] = 100; // 100 copies
uint256[] memory tokenIds = creatorCore.mintBaseNew(to, amounts, []);

// 2. Create fixed-price listing
// (See auctionhouse integration guide)
```

### Pipeline 3: Series → Multiple Marketplaces

```solidity
// 1. Mint series
uint256[] memory tokenIds = creatorCore.mintBaseBatch(creator, uris);

// 2. Approve multiple marketplaces
for (uint i = 0; i < marketplaces.length; i++) {
    IERC721(creatorContract).setApprovalForAll(marketplaces[i], true);
}

// 3. Create listings on each marketplace
// (Marketplace-specific code)
```

## Best Practices

### Security

1. **Access Control**: Always use `adminRequired` modifier for admin functions
2. **Input Validation**: Validate all inputs in extensions
3. **Reentrancy**: Use `nonReentrant` modifier for state-changing functions
4. **Extension Validation**: Verify extension contracts before registration

### Gas Optimization

1. **Batch Operations**: Use batch functions when possible
2. **Base URI**: Prefer base URI over per-token URIs
3. **Storage**: Minimize storage writes in extensions
4. **Events**: Emit events for important state changes

### Integration Patterns

1. **Lazy Minting**: Use for on-demand minting (saves upfront gas)
2. **Extension Minting**: Use extensions for complex minting logic
3. **Royalty Configuration**: Set royalties before first sale
4. **URI Management**: Use IPFS/Arweave for decentralized storage

### Testing

```solidity
// Test extension registration
function testExtensionRegistration() public {
    creatorCore.registerExtension(address(extension), "");
    assertTrue(creatorCore.getExtensions().length == 1);
}

// Test minting via extension
function testExtensionMinting() public {
    uint256 tokenId = creatorCore.mintExtension(to);
    assertEq(creatorCore.ownerOf(tokenId), to);
    assertEq(creatorCore.tokenExtension(tokenId), address(extension));
}

// Test royalties
function testRoyalties() public {
    (address[] memory receivers, uint256[] memory bps) = 
        creatorCore.getRoyalties(tokenId);
    assertEq(receivers[0], creator);
    assertEq(bps[0], 500);
}
```

## Troubleshooting

### Extension Not Minting

- Check extension is registered: `creatorCore.getExtensions()`
- Verify extension implements required interfaces
- Ensure extension is not blacklisted
- Check mint permissions are set correctly

### Royalties Not Working

- Verify royalties are set: `creatorCore.getRoyalties(tokenId)`
- Check marketplace supports EIP-2981
- Ensure receivers are payable addresses
- Verify basis points are correct (10000 = 100%)

### Token URI Not Resolving

- Check base URI is set correctly
- Verify token exists: `creatorCore.ownerOf(tokenId)`
- Test URI in browser/IPFS gateway
- Check extension tokenURI function (if applicable)

### Transfer Failing

- Verify approval is set: `isApprovedForAll(owner, operator)`
- Check extension approve transfer logic
- Ensure token is not locked
- Verify recipient can receive ERC721/ERC1155

## Additional Resources

- [Auctionhouse Integration Guide](../auctionhouse-contracts/INTEGRATION_GUIDE.md)
- [Extension Examples](https://github.com/manifoldxyz/creator-core-extensions-solidity)
- [Manifold Documentation](https://docs.manifold.xyz/v/manifold-for-developers/manifold-creator-architecture/overview)

