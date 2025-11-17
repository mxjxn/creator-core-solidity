# Deployment Guide

This guide covers different methods for deploying Creator Core contracts, from simple direct deployments to advanced proxy patterns.

## Table of Contents

- [Direct Deployment (Non-Upgradeable)](#direct-deployment-non-upgradeable)
- [Proxy Deployment (Upgradeable)](#proxy-deployment-upgradeable)
- [DeploymentProxy (CREATE2 Deterministic)](#deploymentproxy-create2-deterministic)
- [Network-Specific Considerations](#network-specific-considerations)
- [Gas Optimization Tips](#gas-optimization-tips)
- [Verification](#verification)

## Direct Deployment (Non-Upgradeable)

The simplest deployment method for `ERC721Creator` and `ERC1155Creator` contracts.

### Using Foundry

```solidity
// DeployERC721.s.sol
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../contracts/ERC721Creator.sol";

contract DeployERC721 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        ERC721Creator creator = new ERC721Creator("My Collection", "MC");
        
        console.log("ERC721Creator deployed at:", address(creator));
        vm.stopBroadcast();
    }
}
```

Run with:
```bash
forge script script/DeployERC721.s.sol:DeployERC721 --rpc-url $RPC_URL --broadcast
```

### Using Hardhat

```javascript
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const ERC721Creator = await hre.ethers.getContractFactory("ERC721Creator");
  const creator = await ERC721Creator.deploy("My Collection", "MC");
  
  await creator.deployed();
  console.log("ERC721Creator deployed to:", creator.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Run with:
```bash
npx hardhat run scripts/deploy.js --network <network>
```

### Using ethers.js

```javascript
const { ethers } = require("ethers");
const ERC721Creator = require("./artifacts/contracts/ERC721Creator.sol/ERC721Creator.json");

async function deploy() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  
  const factory = new ethers.ContractFactory(
    ERC721Creator.abi,
    ERC721Creator.bytecode,
    wallet
  );
  
  const creator = await factory.deploy("My Collection", "MC");
  await creator.deployed();
  
  console.log("Deployed to:", creator.address);
}
```

## Proxy Deployment (Upgradeable)

For upgradeable contracts, you need to deploy both the implementation and a proxy.

### ERC1967 Proxy Pattern

The upgradeable contracts use ERC1967 transparent proxy pattern.

#### Step 1: Deploy Implementation

```solidity
// DeployImplementation.s.sol
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../contracts/ERC721CreatorImplementation.sol";

contract DeployImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        ERC721CreatorImplementation impl = new ERC721CreatorImplementation();
        
        console.log("Implementation deployed at:", address(impl));
        vm.stopBroadcast();
    }
}
```

#### Step 2: Deploy Proxy

Using OpenZeppelin's proxy contracts:

```solidity
// DeployProxy.s.sol
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";
import "../contracts/ERC721CreatorImplementation.sol";

contract DeployProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        address impl = vm.envAddress("IMPLEMENTATION_ADDRESS");
        address admin = msg.sender; // Or your desired admin
        
        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        
        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            ERC721CreatorImplementation.initialize.selector,
            "My Collection",
            "MC"
        );
        
        // Deploy proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            impl,
            address(proxyAdmin),
            initData
        );
        
        console.log("Proxy deployed at:", address(proxy));
        console.log("ProxyAdmin at:", address(proxyAdmin));
        vm.stopBroadcast();
    }
}
```

#### Using OpenZeppelin Upgrades Plugin

For Hardhat, use the OpenZeppelin upgrades plugin:

```javascript
// scripts/deploy-upgradeable.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const ERC721CreatorUpgradeable = await ethers.getContractFactory(
    "ERC721CreatorUpgradeable"
  );
  
  const creator = await upgrades.deployProxy(
    ERC721CreatorUpgradeable,
    ["My Collection", "MC"],
    { initializer: "initialize" }
  );
  
  await creator.deployed();
  console.log("ERC721CreatorUpgradeable deployed to:", creator.address);
}

main();
```

## DeploymentProxy (CREATE2 Deterministic)

The DeploymentProxy allows for deterministic contract addresses using CREATE2, useful for factory patterns.

### Deploying the DeploymentProxy

First, deploy the DeploymentProxy itself:

```solidity
// DeployDeploymentProxy.s.sol
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployDeploymentProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Salt is: 0x6d616e69666f6c6420636f6e7472616374206465706c6f7965722070726f7879
        // Hex of "manifold contract deployer proxy"
        bytes memory bytecode = abi.decode(
            vm.parseJson(
                vm.readFile("out/DeploymentProxy.yul/DeploymentProxy.json"),
                "$.bytecode.object"
            ),
            (bytes)
        );
        
        bytes memory initcode = abi.encodePacked(
            bytes32(0x6d616e69666f6c6420636f6e7472616374206465706c6f7965722070726f7879),
            bytecode
        );
        
        (bool success, bytes memory data) = address(0x4e59b44847b379578588920cA78FbF26c0B4956C).call(initcode);
        require(success, "DeploymentProxy deployment failed");
        
        address deployedAddress = address(uint160(bytes20(data)));
        console.log("DeploymentProxy deployed at:", deployedAddress);
        
        vm.stopBroadcast();
    }
}
```

### Using DeploymentProxy

```solidity
// DeployViaProxy.s.sol
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

interface DeploymentProxy {
    function deploy(
        bytes32 nonce,
        address[] calldata extensions,
        address[] calldata admins,
        bytes calldata bytecode
    ) external returns (address);
}

contract DeployViaProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        DeploymentProxy proxy = DeploymentProxy(vm.envAddress("DEPLOYMENT_PROXY"));
        
        bytes32 nonce = bytes32(uint256(1)); // Your nonce
        address[] memory extensions = new address[](0);
        address[] memory admins = new address[](0);
        
        // Get bytecode for ERC721CreatorImplementation
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ERC721CreatorImplementation.sol:ERC721CreatorImplementation"),
            abi.encode("My Collection", "MC")
        );
        
        address deployed = proxy.deploy(nonce, extensions, admins, bytecode);
        console.log("Contract deployed at:", deployed);
        
        vm.stopBroadcast();
    }
}
```

## Network-Specific Considerations

### Base Network

```bash
# Foundry
forge script script/DeployERC721.s.sol:DeployERC721 \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Hardhat
npx hardhat run scripts/deploy.js --network base
```

### Ethereum Mainnet

```bash
# Foundry
forge script script/DeployERC721.s.sol:DeployERC721 \
  --rpc-url https://eth.llamarpc.com \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Test Networks

For testnets, ensure you have testnet ETH:
- Sepolia: https://sepoliafaucet.com/
- Base Sepolia: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

## Gas Optimization Tips

### 1. Use ERC1155 for Editions

ERC1155 is more gas-efficient for multiple copies of the same token:

```solidity
// ERC1155: ~65k gas per mint (any quantity)
mintBaseExisting([to], [tokenId], [100]);

// ERC721: ~65k gas per token
// For 100 tokens: ~6.5M gas
mintBaseBatch(to, 100);
```

### 2. Batch Operations

Always use batch functions when minting multiple tokens:

```solidity
// Good: Single transaction
mintBaseBatch(to, ["uri1", "uri2", "uri3"]);

// Bad: Multiple transactions
mintBase(to, "uri1");
mintBase(to, "uri2");
mintBase(to, "uri3");
```

### 3. Avoid Enumerable Unless Necessary

`ERC721CreatorEnumerable` doubles mint costs. Only use if you need:
- `totalSupply()`
- Token enumeration
- Index-based queries

### 4. Use Base URI When Possible

Setting a base URI is cheaper than per-token URIs:

```solidity
// Set once
setBaseTokenURI("https://api.example.com/metadata/");

// Tokens automatically use: https://api.example.com/metadata/{tokenId}
```

### 5. Deploy Implementation Once

For upgradeable contracts, deploy the implementation once and reuse:

```solidity
// Deploy implementation (expensive, ~2M gas)
ERC721CreatorImplementation impl = new ERC721CreatorImplementation();

// Deploy proxies (cheap, ~500k gas each)
TransparentUpgradeableProxy proxy1 = new TransparentUpgradeableProxy(...);
TransparentUpgradeableProxy proxy2 = new TransparentUpgradeableProxy(...);
```

## Verification

### Foundry Verification

```bash
forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/ERC721Creator.sol:ERC721Creator \
  --chain-id 8453 \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string)" "My Collection" "MC")
```

### Hardhat Verification

Add to `hardhat.config.js`:
```javascript
module.exports = {
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY,
      mainnet: process.env.ETHERSCAN_API_KEY,
    },
  },
};
```

Then verify:
```bash
npx hardhat verify --network base <CONTRACT_ADDRESS> "My Collection" "MC"
```

### Manual Verification

1. Go to block explorer (Etherscan/Basescan)
2. Navigate to contract address
3. Click "Contract" tab → "Verify and Publish"
4. Select compiler version and settings
5. Paste contract source code
6. Provide constructor arguments (ABI-encoded)

## Post-Deployment Checklist

- [ ] Contract verified on block explorer
- [ ] Owner address is correct
- [ ] Admins configured (if needed)
- [ ] Base URI set (if using)
- [ ] Default royalties configured
- [ ] Test mint successful
- [ ] Token URI returns correctly
- [ ] Royalties verified
- [ ] Transfer functionality tested

## Troubleshooting

### "Insufficient funds for gas"

Ensure your deployer wallet has enough ETH for:
- Contract deployment: ~2-5M gas
- Proxy deployment: ~500k-1M gas
- Verification: Free (but requires API key)

### "Contract already deployed"

If using CREATE2 (DeploymentProxy), the address is deterministic. Change the nonce to deploy to a different address.

### "Initialization failed"

For upgradeable contracts, ensure:
- `initialize()` is called correctly
- Initializer is only called once
- Parameters match function signature

### "Extension registration failed"

Check:
- Extension contract is deployed
- Extension implements required interfaces
- Caller is owner or admin
- Extension is not blacklisted

