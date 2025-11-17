# Contract Deployments

This document tracks all contract deployments made from this repository.

## Base Sepolia Testnet (Chain ID: 84532)

### Radical Testers Collection

**Deployment Date**: December 2024  
**Status**: ✅ Deployed Successfully

#### Contract Addresses

| Contract | Address | Type |
|----------|---------|------|
| Collection (Proxy) | `0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A` | TransparentUpgradeableProxy |
| Implementation | `0x0C1f9d0b4b92411B145E70A33052AE87D19e99c4` | ERC721CreatorImplementation |
| ProxyAdmin | `0xDF6c66d24C6DDBC9CcfDc74A243E8e098981a26E` | ProxyAdmin |

#### Collection Details

- **Name**: Radical Testers
- **Symbol**: RT
- **Total Supply**: 100 NFTs
- **Token IDs**: 1-100
- **Owner**: `0x6dA173B1d50F7Bc5c686f8880C20378965408344`
- **All NFTs Owned By**: `0x6dA173B1d50F7Bc5c686f8880C20378965408344`

#### Deployment Transactions

| Transaction | Hash | Block | Gas Used | Cost (ETH) |
|-------------|------|-------|----------|------------|
| Implementation | `0x15ca655b0b6b8e96181260022bad9b0c4c9f6b72d0c6ac8257ab1c36a51d5dbc` | 33797628 | 5,323,221 | 0.00000532 |
| ProxyAdmin | `0x80658bc58a9a2f20acdbd05c0cbbea2f3b93db5a6404a753a39282005345aeb5` | 33797628 | 2,652,023 | 0.00000265 |
| Proxy | `0xcba4b6d00eda216ea5cd61c75af54c0d33aab426f11eab24f80aab83ef2ffb67` | 33797628 | 482,038 | 0.00000048 |
| Minting | `0xb311bb13298567d19a1d1b462f5e6498b653f83e91a1e074014def50a3fb1ffa` | 33797628 | 751,410 | 0.00000075 |

**Total Cost**: 0.00000921 ETH (9,208,692 gas)

#### Links

- [Collection on BaseScan](https://sepolia.basescan.org/address/0x6302C5F1F2E3d0e4D5ae5aeB88bd8044c88Eef9A)
- [Implementation on BaseScan](https://sepolia.basescan.org/address/0x0C1f9d0b4b92411B145E70A33052AE87D19e99c4)
- [ProxyAdmin on BaseScan](https://sepolia.basescan.org/address/0xDF6c66d24C6DDBC9CcfDc74A243E8e098981a26E)
- [Detailed Deployment Documentation](./DEPLOYMENT_RADICAL_TESTERS.md)

---

## Deployment Scripts

### DeployAndMintCollection.s.sol

Script for deploying a new collection and minting NFTs in one transaction.

**Location**: `script/DeployAndMintCollection.s.sol`

**Usage**:
```bash
./script/deploy-and-mint.sh
```

**Configuration**:
- Supports mnemonic-based key derivation
- Automatically loads from `.env.local`
- Uses upgradeable proxy pattern to avoid contract size limits
- Mints all NFTs to specified address

See [Deploy and Mint README](./script/DEPLOY_AND_MINT_README.md) for detailed usage.

---

## Adding New Deployments

When deploying new contracts, please update this file with:

1. Network and chain ID
2. Contract addresses
3. Deployment transaction hashes
4. Key details (name, symbol, supply, etc.)
5. Links to block explorer
6. Reference to detailed deployment documentation

## Notes

- All deployments use compiler optimizations (optimizer_runs: 1000)
- Upgradeable contracts use TransparentUpgradeableProxy pattern
- Deployment artifacts are saved in `broadcast/` directory
- Sensitive values are cached in `cache/` directory

