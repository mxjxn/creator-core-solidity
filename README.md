# manifoldxyz-creator-core-solidity

## The Manifold Creator Core Contracts

**A library for extendible creator contracts.**

 * Implementation for ERC721
 * Implementation for ERC1155

The Manifold Creator Core contracts provide creators with the ability to deploy an ERC721/ERC1155 NFT smart contract with basic minting functionality, on-chain royalties and permissioning.  Additionally, they provide a framework for extending the functionality of the smart contract by installing extension applications.

These contracts are used in the [Manifold Studio](https://studio.manifoldxyz.dev/).

This enables creators to use the same underlying Manifold Creator Core contract to continue creating new and innovative NFT's and experiences.

See our [developer documentation](https://docs.manifold.xyz/v/manifold-for-developers/manifold-creator-architecture/overview) and [blog post](https://manifoldxyz.substack.com/p/manifold-creator) for more information.

Go [here](https://docs.manifold.xyz/v/manifold-for-developers/manifold-creator-architecture/contracts/extensions/extensions-examples) for example applications that have been added to Manifold Creator Core contracts.

## Architecture Overview

The Creator Core contracts are built with a modular architecture that separates concerns into distinct layers:

### Core Components

1. **CreatorCore** - Base interface and functionality for all creator contracts
   - Extension management (register, unregister, blacklist)
   - Token URI management (base URI, prefixes, per-token URIs)
   - Royalty configuration
   - Mint permissions

2. **ERC721CreatorCore / ERC1155CreatorCore** - Standard-specific core functionality
   - Minting functions (base and extension)
   - Token-specific operations
   - Burn functionality

3. **Token Base Contracts** - ERC standard implementations
   - `ERC721Base` / `ERC1155Base` - Non-upgradeable implementations
   - `ERC721Upgradeable` / `ERC1155Upgradeable` - Upgradeable implementations
   - `ERC721Core` / `ERC1155Core` - Core ERC functionality

4. **AdminControl** - Access control layer
   - Owner and admin management
   - Permission modifiers

### Contract Types

The library provides several contract variants:

#### ERC721Creator
- **Non-upgradeable** ERC721 implementation
- Direct deployment via constructor
- Lower gas costs for deployment
- Best for: Simple collections, one-time deployments

#### ERC721CreatorUpgradeable
- **Upgradeable** ERC721 implementation using ERC1967 proxy pattern
- Initialized via `initialize()` function
- Can be upgraded to fix bugs or add features
- Best for: Production deployments requiring future flexibility

#### ERC721CreatorEnumerable
- **Non-upgradeable** with enumerable functionality
- Supports `totalSupply()` and iteration
- **Note**: Significantly increases mint costs (~2x)
- Best for: Collections requiring enumeration

#### ERC1155Creator
- **Non-upgradeable** ERC1155 implementation
- Supports multiple token IDs with different supplies
- Best for: Multi-token collections, editions

#### ERC1155CreatorUpgradeable
- **Upgradeable** ERC1155 implementation
- Same benefits as ERC721CreatorUpgradeable
- Best for: Production multi-token collections

### Extension System

The extension system is the most powerful feature of Creator Core contracts. Extensions can:

- **Override minting logic** - Custom mint functions with validation
- **Customize token URIs** - Dynamic metadata generation
- **Control transfers** - Approve/reject transfers before execution
- **Manage burns** - Custom burn logic and validation
- **Define royalties** - Per-extension or per-token royalty structures

Extensions are registered with the main contract and can mint tokens that are "owned" by the extension, allowing for sophisticated minting workflows.

### Royalties Configuration

Creator Core supports multiple royalty standards:
- EIP-2981 (royaltyInfo)
- Manifold Royalty Registry
- Rarible V2 royalties

Royalties can be set at multiple levels:
- Default royalties (all tokens)
- Per-token royalties
- Per-extension royalties

### Access Control

The contracts use `AdminControl` which provides:
- **Owner** - Single address with full control
- **Admins** - Multiple addresses with admin privileges
- Admin functions are protected by `adminRequired` modifier

## Overview

### Installation

```console
$ npm install @manifoldxyz/creator-core-solidity
```

### Usage

Once installed, you can use the contracts in the library by importing them:

```solidity
pragma solidity ^0.8.0;

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

contract MyContract is ERC721Creator  {
    constructor() ERC721Creator ("MyContract", "MC") {
    }
}
```

The available contracts are:

 * ERC721Creator
 * ERC721CreatorUpgradeable - A transparent proxy upgradeable version of ERC721Creator
 * ERC721CreatorEnumerable - Note that using enumerable significantly increase mint costs by around 2x
 * ERC1155Creator

[Manifold Studio](https://studio.manifoldxyz.dev/) currently makes use of ERC721Creator and ERC1155Creator

### Extension Applications

The most powerful aspect of Manifold Creator Core contracts is the ability to extend the functionality of your smart contract by adding new Extension Applications (Apps). Apps have the ability to override the following functionality for any token created by that App:

**ERC721**
 * mint
 * tokenURI
 * transferFrom/safeTransferFrom pre-transfer check
 * burn pre-burn check
 * define royalties for extension minted tokens

**ERC1155**
 * mint
 * uri
 * safeTransferFrom pre-transfer check
 * burn pre-burn check
 * define royalties for extension minted tokens

In order to create an app, you'll need to implement one or more interfaces within contracts/extensions, deploy the new app and register it to the main Creator Core contract using the registerExtension function (which is only accessible to the contract owner or admins).

Example applications can be found [here](https://github.com/manifoldxyz/creator-core-extensions-solidity).

## Running the package unit tests

```
forge test
```
