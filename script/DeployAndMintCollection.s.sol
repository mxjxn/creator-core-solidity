// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/ERC721CreatorImplementation.sol";
import "../contracts/core/IERC721CreatorCore.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

/**
 * @title DeployAndMintCollection
 * @notice Deploys a new ERC721 collection on testnet and mints all NFTs to a specified address
 * @dev Configure via environment variables:
 *      - CONTRACT_NAME: Collection name (default: "Radical Testers")
 *      - CONTRACT_SYMBOL: Collection symbol (default: "RT")
 *      - MINT_TO: Address to receive all NFTs (optional, defaults to derived address)
 *      - NFT_COUNT: Number of NFTs to mint (default: 100)
 *      - PRIVATE_KEY: Deployer private key (optional if MNEMONIC is set)
 *      - MNEMONIC: Mnemonic phrase to derive private key (optional)
 *      - MNEMONIC_INDEX: Index for mnemonic derivation (default: 0)
 */
contract DeployAndMintCollection is Script {
    function run() external {
        // Derive private key from mnemonic if provided, otherwise use PRIVATE_KEY
        uint256 deployerPrivateKey;
        address derivedAddress;
        
        try vm.envString("MNEMONIC") returns (string memory mnemonic) {
            uint32 mnemonicIndex = uint32(vm.envOr("MNEMONIC_INDEX", uint256(0)));
            deployerPrivateKey = vm.deriveKey(mnemonic, mnemonicIndex);
            derivedAddress = vm.addr(deployerPrivateKey);
            console.log("Derived private key from mnemonic");
            console.log("Mnemonic index:", vm.toString(mnemonicIndex));
            console.log("Derived address:", derivedAddress);
        } catch {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
            derivedAddress = vm.addr(deployerPrivateKey);
        }

        // Read configuration from environment
        string memory name = vm.envOr("CONTRACT_NAME", string("Radical Testers"));
        string memory symbol = vm.envOr("CONTRACT_SYMBOL", string("RT"));
        
        // Use MINT_TO if provided, otherwise use derived address
        address mintTo;
        try vm.envAddress("MINT_TO") returns (address addr) {
            mintTo = addr;
        } catch {
            mintTo = derivedAddress;
        }
        
        uint16 nftCount = uint16(vm.envOr("NFT_COUNT", uint256(100)));

        vm.startBroadcast(deployerPrivateKey);

        console.log("==========================================");
        console.log("Deploying Collection and Minting NFTs");
        console.log("==========================================");
        console.log("Collection Name:", name);
        console.log("Collection Symbol:", symbol);
        console.log("Mint To:", vm.toString(mintTo));
        console.log("NFT Count:", vm.toString(nftCount));
        console.log("==========================================");

        // Deploy ERC721 collection using upgradeable proxy pattern (to avoid contract size limit)
        console.log("Deploying ERC721CreatorImplementation...");
        ERC721CreatorImplementation impl = new ERC721CreatorImplementation();
        console.log("Implementation deployed at:", address(impl));
        
        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        
        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            ERC721CreatorImplementation.initialize.selector,
            name,
            symbol
        );
        
        // Deploy proxy
        console.log("Deploying proxy...");
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            address(proxyAdmin),
            initData
        );
        
        ERC721CreatorImplementation creator = ERC721CreatorImplementation(address(proxy));
        console.log("Collection (proxy) deployed at:", address(creator));
        console.log("Owner:", creator.owner());
        
        // Transfer ProxyAdmin ownership to deployer if needed
        if (proxyAdmin.owner() != derivedAddress) {
            proxyAdmin.transferOwnership(derivedAddress);
        }

        // Mint all NFTs to the specified address
        console.log("Minting NFTs...");
        IERC721CreatorCore creatorCore = IERC721CreatorCore(address(creator));
        uint256[] memory tokenIds = creatorCore.mintBaseBatch(mintTo, nftCount);
        
        console.log("Minting complete!");
        console.log("First token ID:", vm.toString(tokenIds[0]));
        console.log("Last token ID:", vm.toString(tokenIds[tokenIds.length - 1]));
        console.log("Total tokens minted:", vm.toString(tokenIds.length));

        // Verify ownership
        console.log("Verifying ownership...");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address owner = creator.ownerOf(tokenIds[i]);
            require(owner == mintTo, "Ownership verification failed");
        }
        console.log("All NFTs verified to be owned by:", vm.toString(mintTo));

        vm.stopBroadcast();

        // Print summary
        console.log("==========================================");
        console.log("            DEPLOYMENT SUMMARY");
        console.log("==========================================");
        console.log("Collection Address:", address(creator));
        console.log("Collection Name:", name);
        console.log("Collection Symbol:", symbol);
        console.log("Total Supply:", vm.toString(nftCount));
        console.log("All NFTs owned by:", vm.toString(mintTo));
        console.log("Token IDs: 1 -", vm.toString(nftCount));
        console.log("==========================================");
    }
}

