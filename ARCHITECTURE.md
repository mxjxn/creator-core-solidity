# Contract Architecture

This document provides a comprehensive explanation of how the Creator Core contracts work, including the proxy pattern, extension system, and internal mechanisms.

## Table of Contents

- [Proxy Pattern Architecture](#proxy-pattern-architecture)
- [Contract Inheritance Hierarchy](#contract-inheritance-hierarchy)
- [Extension System](#extension-system)
- [Minting Mechanisms](#minting-mechanisms)
- [Royalty System](#royalty-system)
- [Transfer Control](#transfer-control)
- [Token URI Resolution](#token-uri-resolution)
- [Access Control](#access-control)
- [Data Flow Examples](#data-flow-examples)

## Proxy Pattern Architecture

### Why Use a Proxy?

The `ERC721CreatorImplementation` contract is large and exceeds the 24KB EVM contract size limit when compiled. The proxy pattern solves this by:

1. **Separating Storage from Logic**: The proxy contract (small) stores state, while the implementation (large) contains logic
2. **Enabling Upgrades**: The implementation can be upgraded without changing the proxy address
3. **Gas Efficiency**: Multiple proxies can share the same implementation

### Three-Component System

When deploying an upgradeable collection, three contracts are created:

```
┌─────────────────────────────────────────────────────────┐
│  Proxy (0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A)     │
│  - Small contract (< 24KB)                               │
│  - Stores state (owner, token balances, etc.)            │
│  - Delegates all calls to implementation                │
│  - Users interact with this address                     │
└──────────────────┬──────────────────────────────────────┘
                   │ delegatecall
                   ▼
┌─────────────────────────────────────────────────────────┐
│  Implementation (0x0C1f9d0b4b92411B145E70A33052AE87D19e99c4) │
│  - Contains all business logic                          │
│  - No state storage (uses proxy's storage)              │
│  - Can be upgraded                                      │
└─────────────────────────────────────────────────────────┘
                   │
                   │ controlled by
                   ▼
┌─────────────────────────────────────────────────────────┐
│  ProxyAdmin (0xDF6c66d24C6DDBC9CcfDc74A243E8e098981a26E) │
│  - Owns the proxy                                        │
│  - Only owner can upgrade implementation                │
│  - Protects against unauthorized upgrades               │
└─────────────────────────────────────────────────────────┘
```

### How Delegation Works

When a user calls a function on the proxy:

1. **User calls**: `proxy.mintBase(to)`
2. **Proxy receives call**: Checks if it's an admin function (upgrade)
3. **If not admin**: Uses `delegatecall` to forward to implementation
4. **Implementation executes**: Logic runs in proxy's storage context
5. **State changes**: Written to proxy's storage, not implementation's
6. **Return value**: Passed back through proxy to user

### Storage Layout

The proxy uses a specific storage layout to avoid collisions:

```solidity
// Proxy storage slot (OpenZeppelin standard)
bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

// Implementation storage (ERC721CreatorImplementation)
mapping(uint256 => address) private _owners;           // Slot 0
mapping(address => uint256) private _balances;        // Slot 1
mapping(uint256 => address) private _tokenApprovals;  // Slot 2
// ... etc
```

The implementation's storage slots start after the proxy's reserved slots, preventing conflicts.

## Contract Inheritance Hierarchy

The `ERC721CreatorImplementation` contract inherits from multiple base contracts:

```
ERC721CreatorImplementation
├── AdminControlUpgradeable
│   └── OwnableUpgradeable (OpenZeppelin)
│       └── Initializable
├── ERC721Upgradeable
│   ├── ERC721Core
│   │   ├── ERC721 (OpenZeppelin)
│   │   └── IERC721Metadata
│   └── ReentrancyGuardUpgradeable
└── ERC721CreatorCore
    └── CreatorCore
        └── ICreatorCore
```

### Component Responsibilities

#### AdminControlUpgradeable
- Manages owner and admin addresses
- Provides `adminRequired` modifier
- Handles ownership transfers

#### ERC721Upgradeable
- Standard ERC721 functionality (mint, transfer, approve)
- Token ownership tracking
- Metadata support (name, symbol, tokenURI)
- Reentrancy protection

#### ERC721CreatorCore
- Extension management
- Extension-based minting
- Transfer approval hooks
- Token extension tracking

#### CreatorCore
- Base extension registry
- URI management (base, prefix, per-token)
- Royalty configuration
- Mint permissions

## Extension System

The extension system allows external contracts to extend the functionality of the creator contract.

### Extension Registration

```solidity
// Admin registers an extension
creatorCore.registerExtension(extensionAddress, baseURI, false);
```

**What happens internally:**

1. **Validation**: Checks extension is a contract and not blacklisted
2. **Index Assignment**: Assigns unique index (1-65535) to extension
3. **Storage Updates**:
   ```solidity
   _extensions.add(extension);                    // Add to set
   _extensionToIndex[extension] = index;          // Map extension → index
   _indexToExtension[index] = extension;          // Map index → extension
   _extensionBaseURI[extension] = baseURI;        // Store base URI
   ```
4. **Transfer Approval**: Sets up transfer approval delegation if extension supports it

### Extension Minting

When an extension mints a token:

```solidity
// Extension calls
uint256 tokenId = creatorCore.mintExtension(to);
```

**Internal flow:**

1. **Require Extension**: `requireExtension()` checks `msg.sender` is registered
2. **Check Permissions**: Calls mint permission contract if configured
3. **Pre-Mint Hook**: Calls `_preMintExtension(to, tokenId)`
4. **Mint Token**: Calls `_safeMint(to, tokenId, data)`
   - `data` encodes: `(extensionIndex << 16) | extensionData`
5. **Store Extension**: Token's data field stores extension index
6. **Post-Mint**: Extension can set custom URI or royalties

### Extension Token Data

Each token stores its originating extension in the `_tokenData` mapping:

```solidity
struct TokenData {
    address owner;      // Token owner
    uint96 data;        // Extension index (lower 16 bits) + custom data (upper 80 bits)
}

mapping(uint256 => TokenData) private _tokenData;
```

**Decoding token data:**
- Lower 16 bits: Extension index (0 = base mint, >0 = extension index)
- Upper 80 bits: Custom data (set by extension)

### Extension Capabilities

Extensions can implement interfaces to gain additional capabilities:

#### ICreatorExtensionTokenURI
Override token URI generation:
```solidity
function tokenURI(address creator, uint256 tokenId) 
    external view returns (string memory);
```

#### IERC721CreatorExtensionApproveTransfer
Control transfers before execution:
```solidity
function approveTransfer(address operator, address from, address to, uint256 tokenId)
    external returns (bool);
```

#### IERC721CreatorExtensionBurnable
Handle burn events:
```solidity
function onBurn(address owner, uint256 tokenId) external;
```

#### ICreatorExtensionRoyalties
Define royalties for extension-minted tokens:
```solidity
function getRoyalties(address creator, uint256 tokenId)
    external view returns (address payable[] memory, uint256[] memory);
```

## Minting Mechanisms

### Base Minting (Admin-Only)

Base minting is for direct admin-controlled minting:

```solidity
// Single mint
uint256 tokenId = creatorCore.mintBase(to, "ipfs://...");

// Batch mint
uint256[] memory tokenIds = creatorCore.mintBaseBatch(to, 100);
```

**Characteristics:**
- Requires `adminRequired` modifier
- Token extension index = 0 (no extension)
- No mint permission checks
- Direct URI assignment possible

**Gas costs:**
- Single mint: ~65,000 gas
- Batch mint (100 tokens): ~65,000 gas (same transaction, amortized)

### Extension Minting

Extension minting allows registered extensions to mint:

```solidity
// Extension calls
uint256 tokenId = creatorCore.mintExtension(to);
```

**Characteristics:**
- Requires extension to be registered
- Token extension index > 0 (stored in token data)
- Mint permission checks (if configured)
- Extension can set custom URI after mint

**Flow:**
```
Extension Contract
    │
    ├─> creatorCore.mintExtension(to)
    │       │
    │       ├─> requireExtension() [check msg.sender is registered]
    │       ├─> _checkMintPermissions(to, tokenId) [if permissions set]
    │       ├─> _preMintExtension(to, tokenId) [hook]
    │       ├─> _safeMint(to, tokenId, extensionIndex) [mint with extension data]
    │       └─> return tokenId
    │
    └─> extension.setTokenURI(tokenId, customURI) [optional]
```

### Token ID Assignment

Token IDs are assigned sequentially:

```solidity
uint256 private _tokenCount;  // Current token count

// When minting
++_tokenCount;
tokenId = _tokenCount;  // First token is ID 1
```

**Important:** Token IDs start at 1, not 0. This is standard ERC721 practice.

## Royalty System

The contract supports multiple royalty standards and configuration levels.

### Royalty Standards

1. **EIP-2981** (`royaltyInfo`): Standard royalty interface
2. **Manifold Registry**: Via `getRoyalties()`
3. **Rarible V2**: Via `getFeeRecipients()` and `getFeeBps()`

### Royalty Configuration Levels

Royalties can be set at three levels (checked in order):

1. **Per-Token Royalties** (highest priority)
   ```solidity
   creatorCore.setRoyalties(tokenId, receivers, basisPoints);
   ```

2. **Extension Royalties** (for extension-minted tokens)
   ```solidity
   creatorCore.setRoyaltiesExtension(extension, receivers, basisPoints);
   ```

3. **Default Royalties** (fallback for all tokens)
   ```solidity
   creatorCore.setRoyalties(receivers, basisPoints);
   ```

### Royalty Resolution

When `royaltyInfo(tokenId, salePrice)` is called:

```solidity
function royaltyInfo(uint256 tokenId, uint256 value) 
    external view returns (address, uint256) 
{
    // 1. Check per-token royalties
    if (_tokenRoyalty[tokenId].receivers.length > 0) {
        return _getRoyaltyInfo(_tokenRoyalty[tokenId], value);
    }
    
    // 2. Check extension royalties (if token has extension)
    address extension = _tokenExtension(tokenId);
    if (extension != address(0) && _extensionRoyalty[extension].receivers.length > 0) {
        return _getRoyaltyInfo(_extensionRoyalty[extension], value);
    }
    
    // 3. Fall back to default royalties
    return _getRoyaltyInfo(_defaultRoyalty, value);
}
```

### Basis Points

Royalties are specified in basis points (bps):
- 100 bps = 1%
- 500 bps = 5%
- 1000 bps = 10%
- 10000 bps = 100% (maximum)

**Example:**
```solidity
address payable[] memory receivers = new address payable[](1);
receivers[0] = payable(0x1234...);
uint256[] memory basisPoints = new uint256[](1);
basisPoints[0] = 500;  // 5% royalty

creatorCore.setRoyalties(receivers, basisPoints);
```

## Transfer Control

The contract provides hooks for extensions to control transfers.

### Transfer Approval Flow

When a transfer is initiated:

```
User calls transferFrom(from, to, tokenId)
    │
    ├─> _beforeTokenTransfer(from, to, tokenId, data)
    │       │
    │       ├─> Extract extension index from token data
    │       ├─> Get extension address from index
    │       └─> _approveTransfer(from, to, tokenId, extension)
    │               │
    │               ├─> If extension has approve transfer enabled:
    │               │       └─> extension.approveTransfer(operator, from, to, tokenId)
    │               │           └─> Must return true or revert
    │               │
    │               └─> If base approve transfer set:
    │                       └─> _approveTransferBase.approveTransfer(...)
    │
    └─> Execute transfer (if approved)
```

### Extension Transfer Approval

Extensions can implement `IERC721CreatorExtensionApproveTransfer`:

```solidity
interface IERC721CreatorExtensionApproveTransfer {
    function approveTransfer(
        address operator,  // Who initiated the transfer
        address from,      // Current owner
        address to,        // New owner
        uint256 tokenId    // Token being transferred
    ) external returns (bool);
}
```

**Use cases:**
- Restrict transfers during certain periods
- Require additional approvals
- Implement cooldown periods
- Enforce whitelist requirements

### Base Transfer Approval

A single contract can be set as the base transfer approver:

```solidity
creatorCore.setApproveTransfer(approvalContract);
```

This contract will be called for all transfers, regardless of extension.

## Token URI Resolution

The contract supports flexible URI management with multiple resolution strategies.

### URI Resolution Order

When `tokenURI(tokenId)` is called:

1. **Extension URI** (if token has extension and extension implements `ICreatorExtensionTokenURI`)
   ```solidity
   extension.tokenURI(creatorAddress, tokenId)
   ```

2. **Per-Token URI** (if explicitly set)
   ```solidity
   _tokenURIs[tokenId]
   ```

3. **Base URI + Token ID** (if base URI is set)
   ```solidity
   string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)))
   ```

4. **Extension Base URI + Token ID** (if token has extension)
   ```solidity
   string(abi.encodePacked(_extensionBaseURI[extension], Strings.toString(tokenId)))
   ```

### URI Patterns

#### Base URI Pattern
```solidity
creatorCore.setBaseTokenURI("https://api.example.com/metadata/");
// Token 1: https://api.example.com/metadata/1
// Token 2: https://api.example.com/metadata/2
```

#### Prefix Pattern
```solidity
creatorCore.setTokenURIPrefix("ipfs://");
creatorCore.setTokenURI(tokenId, "QmHash...");
// Result: ipfs://QmHash...
```

#### Per-Token URI
```solidity
creatorCore.setTokenURI(tokenId, "https://example.com/token/1.json");
```

#### Extension URI Override
```solidity
// Extension implements ICreatorExtensionTokenURI
function tokenURI(address creator, uint256 tokenId) 
    external view returns (string memory) 
{
    // Dynamic URI generation
    return string(abi.encodePacked(
        "https://api.example.com/token/",
        Strings.toString(tokenId),
        "?v=",
        Strings.toString(block.timestamp)
    ));
}
```

## Access Control

The contract uses a two-tier access control system.

### Owner

- Single address with full control
- Can transfer ownership
- Can add/remove admins
- Can perform all admin functions

### Admins

- Multiple addresses with admin privileges
- Can call functions with `adminRequired` modifier
- Cannot transfer ownership
- Cannot add/remove other admins (unless they're also owner)

### Admin Functions

Functions protected by `adminRequired`:

- `registerExtension()` / `unregisterExtension()`
- `blacklistExtension()`
- `mintBase()` / `mintBaseBatch()`
- `setRoyalties()`
- `setBaseTokenURI()` / `setTokenURI()`
- `setMintPermissions()`

### Access Control Flow

```solidity
modifier adminRequired() {
    require(
        owner() == msg.sender || 
        admins.contains(msg.sender),
        "Admin access required"
    );
    _;
}
```

## Data Flow Examples

### Example 1: Base Minting

```
User (Admin)
    │
    ├─> creatorCore.mintBase(to, "ipfs://QmHash")
    │       │
    │       ├─> adminRequired() [check]
    │       ├─> _mintBase(to, "ipfs://QmHash", 0)
    │       │       │
    │       │       ├─> _preMintBase(to, tokenId) [hook]
    │       │       ├─> ++_tokenCount
    │       │       ├─> _safeMint(to, tokenId, 0) [extension index = 0]
    │       │       │       │
    │       │       │       ├─> _owners[tokenId] = to
    │       │       │       ├─> _balances[to]++
    │       │       │       └─> emit Transfer(address(0), to, tokenId)
    │       │       │
    │       │       └─> _tokenURIs[tokenId] = "ipfs://QmHash"
    │       │
    │       └─> return tokenId
    │
    └─> Token minted with ID = _tokenCount, extension = 0
```

### Example 2: Extension Minting with Transfer Control

```
Extension Contract
    │
    ├─> creatorCore.mintExtension(to)
    │       │
    │       ├─> requireExtension() [check registered]
    │       ├─> _checkMintPermissions(to, tokenId) [if set]
    │       ├─> _mintExtension(to, "", 0, 0)
    │       │       │
    │       │       ├─> ++_tokenCount
    │       │       ├─> extensionIndex = _extensionToIndex[msg.sender]
    │       │       ├─> _safeMint(to, tokenId, extensionIndex << 16)
    │       │       │       │
    │       │       │       └─> Token data stores extension index
    │       │       │
    │       │       └─> return tokenId
    │       │
    │       └─> return tokenId
    │
    ├─> User tries to transfer token
    │       │
    │       ├─> creatorCore.transferFrom(from, to, tokenId)
    │       │       │
    │       │       ├─> _beforeTokenTransfer(from, to, tokenId, data)
    │       │       │       │
    │       │       │       ├─> Extract extension index from token data
    │       │       │       ├─> Get extension address
    │       │       │       └─> extension.approveTransfer(operator, from, to, tokenId)
    │       │       │               │
    │       │       │               └─> Extension logic (e.g., check cooldown)
    │       │       │                   └─> return true/false
    │       │       │
    │       │       └─> Execute transfer (if approved)
    │       │
    │       └─> Transfer succeeds or reverts based on extension approval
```

### Example 3: Royalty Resolution

```
Marketplace calls royaltyInfo(tokenId, salePrice)
    │
    ├─> creatorCore.royaltyInfo(tokenId, salePrice)
    │       │
    │       ├─> Check _tokenRoyalty[tokenId]
    │       │   └─> If set: return token-specific royalty
    │       │
    │       ├─> Check extension (if token has one)
    │       │   ├─> Get extension from token data
    │       │   └─> Check _extensionRoyalty[extension]
    │       │       └─> If set: return extension royalty
    │       │
    │       └─> Return _defaultRoyalty (fallback)
    │
    └─> Marketplace pays royalty to returned address
```

### Example 4: Token URI Resolution

```
User calls tokenURI(tokenId)
    │
    ├─> creatorCore.tokenURI(tokenId)
    │       │
    │       ├─> Get extension from token data
    │       │   └─> If extension exists:
    │       │       └─> Check if extension implements ICreatorExtensionTokenURI
    │       │           └─> If yes: return extension.tokenURI(creator, tokenId)
    │       │
    │       ├─> Check _tokenURIs[tokenId]
    │       │   └─> If set: return per-token URI
    │       │
    │       ├─> Check _baseTokenURI
    │       │   └─> If set: return baseURI + tokenId
    │       │
    │       └─> Check extension base URI
    │           └─> If set: return extensionBaseURI + tokenId
    │
    └─> Return resolved URI
```

## Storage Layout

### Proxy Storage (OpenZeppelin)

```solidity
// Slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
address private _implementation;

// Slot 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
address private _admin;
```

### Implementation Storage

```solidity
// ERC721 Storage
mapping(uint256 => address) private _owners;                    // Slot 0
mapping(address => uint256) private _balances;                 // Slot 1
mapping(uint256 => address) private _tokenApprovals;           // Slot 2
mapping(address => mapping(address => bool)) private _operatorApprovals; // Slot 3

// ERC721Metadata Storage
string private _name;                                          // Slot 4
string private _symbol;                                        // Slot 5
mapping(uint256 => string) internal _tokenURIs;               // Slot 6

// CreatorCore Storage
EnumerableSet.AddressSet private _extensions;                 // Slot 7
EnumerableSet.AddressSet private _blacklistedExtensions;     // Slot 8
mapping(address => string) internal _extensionBaseURI;        // Slot 9
mapping(uint256 => string) internal _tokenURIs;               // Slot 10 (overlaps with ERC721)
mapping(address => RoyaltyConfig) internal _extensionRoyalty; // Slot 11
mapping(uint256 => RoyaltyConfig) internal _tokenRoyalty;     // Slot 12
RoyaltyConfig internal _defaultRoyalty;                        // Slot 13

// ERC721CreatorCore Storage
uint16 private _extensionCounter;                              // Slot 14
mapping(address => uint16) internal _extensionToIndex;        // Slot 15
mapping(uint16 => address) internal _indexToExtension;      // Slot 16
mapping(address => bool) internal _extensionApproveTransfers; // Slot 17
mapping(address => address) internal _extensionPermissions;  // Slot 18

// AdminControl Storage
address private _owner;                                       // Slot 19
EnumerableSet.AddressSet private _admins;                    // Slot 20
```

## Security Considerations

### Proxy Upgrade Safety

- Only ProxyAdmin owner can upgrade
- Implementation contract should be verified before upgrade
- Storage layout must remain compatible
- Use `storage` keyword in implementation to reference proxy storage

### Extension Security

- Extensions are external contracts - validate before registration
- Blacklist mechanism prevents malicious extensions
- Transfer approval can block malicious transfers
- Mint permissions can restrict who can mint

### Reentrancy Protection

- `nonReentrant` modifier on minting functions
- Transfer approval checks before state changes
- Safe external calls with proper error handling

## Gas Optimization

### Batch Operations

Always use batch functions when minting multiple tokens:
- `mintBaseBatch()`: Single transaction for multiple mints
- `setTokenURI()` with arrays: Batch URI updates

### Storage Optimization

- Use base URI instead of per-token URIs when possible
- Extension indices (uint16) instead of addresses save gas
- EnumerableSet for efficient extension management

### Proxy Pattern Benefits

- Implementation deployed once, reused by multiple proxies
- Proxy deployment: ~500k gas
- Implementation deployment: ~5M gas (one-time)

## Related Documentation

- [Deployment Guide](./DEPLOYMENT_GUIDE.md) - How to deploy contracts
- [Integration Guide](./INTEGRATION_GUIDE.md) - How to integrate with marketplaces
- [Deployments](./DEPLOYMENTS.md) - Tracked deployments
- [README](./README.md) - Overview and quick start

