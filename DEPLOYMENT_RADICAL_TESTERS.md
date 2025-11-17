# Radical Testers Collection Deployment

## Deployment Summary

Successfully deployed the "Radical Testers" (RT) ERC721 collection on Base Sepolia testnet using the upgradeable proxy pattern.

**Deployment Date**: December 2024  
**Network**: Base Sepolia (Chain ID: 84532)  
**Deployment Script**: `script/DeployAndMintCollection.s.sol`

## Contract Addresses

### Main Collection Contract (Proxy)
- **Address**: `0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A`
- **Type**: TransparentUpgradeableProxy
- **Explorer**: https://sepolia.basescan.org/address/0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A

### Implementation Contract
- **Address**: `0x0C1f9d0b4b92411B145E70A33052AE87D19e99c4`
- **Type**: ERC721CreatorImplementation
- **Explorer**: https://sepolia.basescan.org/address/0x0C1f9d0b4b92411B145E70A33052AE87D19e99c4

### ProxyAdmin
- **Address**: `0xDF6c66d24C6DDBC9CcfDc74A243E8e098981a26E`
- **Type**: ProxyAdmin
- **Explorer**: https://sepolia.basescan.org/address/0xDF6c66d24C6DDBC9CcfDc74A243E8e098981a26E

## Collection Details

- **Name**: Radical Testers
- **Symbol**: RT
- **Total Supply**: 100 NFTs
- **Token IDs**: 1 - 100
- **Owner**: `0x6dA173B1d50F7Bc5c686f8880C20378965408344`
- **All NFTs Owned By**: `0x6dA173B1d50F7Bc5c686f8880C20378965408344`

## Deployment Transactions

### Transaction 1: Implementation Deployment
- **Hash**: `0x15ca655b0b6b8e96181260022bad9b0c4c9f6b72d0c6ac8257ab1c36a51d5dbc`
- **Block**: 33797628
- **Gas Used**: 5,323,221
- **Gas Price**: 0.001000122 gwei
- **Cost**: 0.000005323870432962 ETH

### Transaction 2: ProxyAdmin Deployment
- **Hash**: `0x80658bc58a9a2f20acdbd05c0cbbea2f3b93db5a6404a753a39282005345aeb5`
- **Block**: 33797628
- **Gas Used**: 2,652,023
- **Gas Price**: 0.001000122 gwei
- **Cost**: 0.000002652346546806 ETH

### Transaction 3: Proxy Deployment
- **Hash**: `0xcba4b6d00eda216ea5cd61c75af54c0d33aab426f11eab24f80aab83ef2ffb67`
- **Block**: 33797628
- **Gas Used**: 482,038
- **Gas Price**: 0.001000122 gwei
- **Cost**: 0.000000482096808636 ETH

### Transaction 4: Minting & Initialization
- **Hash**: `0xb311bb13298567d19a1d1b462f5e6498b653f83e91a1e074014def50a3fb1ffa`
- **Block**: 33797628
- **Gas Used**: 751,410
- **Gas Price**: 0.001000122 gwei
- **Cost**: 0.00000075150167202 ETH

**Total Deployment Cost**: 0.000009209815460424 ETH (9,208,692 gas)

## Deployment Configuration

### Environment Variables Used
- **MNEMONIC**: Derived from `.env.local`
- **MNEMONIC_INDEX**: 2
- **RPC_URL**: `https://base-sepolia.g.alchemy.com/v2/MEjC8w6RhYcMkObFOCryjeEmgPKnY6ut`
- **CONTRACT_NAME**: Radical Testers (default)
- **CONTRACT_SYMBOL**: RT (default)
- **NFT_COUNT**: 100 (default)
- **MINT_TO**: `0x6dA173B1d50F7Bc5c686f8880C20378965408344` (derived from mnemonic)

### Compiler Settings
- **Solidity Version**: 0.8.17
- **Optimizer**: Enabled
- **Optimizer Runs**: 1000
- **Pattern**: Upgradeable Proxy (TransparentUpgradeableProxy)

## Why Upgradeable Proxy?

The contract was deployed using the upgradeable proxy pattern because:

1. **Contract Size Limit**: The ERC721CreatorImplementation contract exceeds the 24KB EVM contract size limit when compiled without optimizations
2. **Solution**: Using a proxy pattern allows:
   - Small proxy contract (well under size limit)
   - Large implementation contract deployed separately
   - Proxy delegates all calls to implementation
   - Future upgradeability if needed

## Verification

### Verify on BaseScan

To verify the contracts on BaseScan, use:

```bash
# Verify Implementation
forge verify-contract \
  0x0C1f9d0b4b92411B145E70A33052AE87D19e99c4 \
  contracts/ERC721CreatorImplementation.sol:ERC721CreatorImplementation \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify ProxyAdmin
forge verify-contract \
  0xDF6c66d24C6DDBC9CcfDc74A243E8e098981a26E \
  lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify Proxy
forge verify-contract \
  0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A \
  lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy \
  --constructor-args $(cast abi-encode "constructor(address,address,bytes)" \
    0x0C1f9d0b4b92411B145E70A33052AE87D19e99c4 \
    0xDF6c66d24C6DDBC9CcfDc74A243E8e098981a26E \
    $(cast calldata "initialize(string,string)" "Radical Testers" "RT")) \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY
```

## Interacting with the Collection

### Check NFT Balance

```bash
cast call 0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A \
  "balanceOf(address)" \
  0x6dA173B1d50F7Bc5c686f8880C20378965408344 \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

### Check Owner of Token ID

```bash
cast call 0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A \
  "ownerOf(uint256)" \
  1 \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

### Get Collection Name

```bash
cast call 0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A \
  "name()" \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

### Get Collection Symbol

```bash
cast call 0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A \
  "symbol()" \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

## Minting Additional NFTs

To mint more NFTs to the collection owner:

```bash
cast send 0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A \
  "mintBaseBatch(address,uint16)" \
  0x6dA173B1d50F7Bc5c686f8880C20378965408344 \
  10 \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY \
  --private-key $PRIVATE_KEY
```

## Upgradeability

The contract is upgradeable through the ProxyAdmin. To upgrade:

1. Deploy a new implementation contract
2. Call `upgrade()` on the ProxyAdmin with:
   - Proxy address: `0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A`
   - New implementation address

**Note**: Only the ProxyAdmin owner (`0x6dA173B1d50F7Bc5c686f8880C20378965408344`) can perform upgrades.

## Files Generated

Deployment artifacts saved to:
- **Broadcast**: `broadcast/DeployAndMintCollection.s.sol/84532/run-latest.json`
- **Cache**: `cache/DeployAndMintCollection.s.sol/84532/run-latest.json`

## Notes

- All 100 NFTs were successfully minted in a single transaction
- Ownership of all NFTs verified on-chain
- Contract uses OpenZeppelin's TransparentUpgradeableProxy pattern
- ProxyAdmin ownership transferred to the deployer address
- Collection is ready for use on Base Sepolia testnet

## Related Documentation

- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Deploy and Mint Script README](./script/DEPLOY_AND_MINT_README.md)
- [Base Sepolia Explorer](https://sepolia.basescan.org/)

