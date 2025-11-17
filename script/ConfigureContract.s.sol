// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/core/ICreatorCore.sol";
import "../contracts/core/IERC721CreatorCore.sol";
import "../contracts/core/IERC1155CreatorCore.sol";

/**
 * @title ConfigureContract
 * @notice Script to configure deployed Creator Core contracts
 * @dev Sets royalties, base URI, and other post-deployment configurations
 */
contract ConfigureContract is Script {
    function run() external {
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");
        bool isERC721 = vm.envOr("IS_ERC721", true);
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        ICreatorCore creatorCore = ICreatorCore(contractAddress);
        
        // Configure base URI if provided
        string memory baseURI = vm.envOr("BASE_URI", string(""));
        if (bytes(baseURI).length > 0) {
            console.log("Setting base URI:", baseURI);
            creatorCore.setBaseTokenURI(baseURI);
        }
        
        // Configure URI prefix if provided
        string memory uriPrefix = vm.envOr("URI_PREFIX", string(""));
        if (bytes(uriPrefix).length > 0) {
            console.log("Setting URI prefix:", uriPrefix);
            creatorCore.setTokenURIPrefix(uriPrefix);
        }
        
        // Configure default royalties if provided
        address royaltyReceiver = vm.envOr("ROYALTY_RECEIVER", address(0));
        uint256 royaltyBPS = vm.envOr("ROYALTY_BPS", uint256(0));
        
        if (royaltyReceiver != address(0) && royaltyBPS > 0) {
            console.log("Setting default royalties:");
            console.log("  Receiver:", vm.toString(royaltyReceiver));
            console.log("  BPS:", vm.toString(royaltyBPS));
            
            address payable[] memory receivers = new address payable[](1);
            receivers[0] = payable(royaltyReceiver);
            uint256[] memory basisPoints = new uint256[](1);
            basisPoints[0] = royaltyBPS;
            
            creatorCore.setRoyalties(receivers, basisPoints);
        }
        
        // Test mint if enabled
        bool testMint = vm.envOr("TEST_MINT", false);
        if (testMint) {
            address mintTo = vm.envOr("MINT_TO", msg.sender);
            console.log("Test minting to:", vm.toString(mintTo));
            
            if (isERC721) {
                IERC721CreatorCore erc721 = IERC721CreatorCore(contractAddress);
                uint256 tokenId = erc721.mintBase(mintTo);
                console.log("Minted token ID:", vm.toString(tokenId));
            } else {
                IERC1155CreatorCore erc1155 = IERC1155CreatorCore(contractAddress);
                address[] memory to = new address[](1);
                to[0] = mintTo;
                uint256[] memory amounts = new uint256[](1);
                amounts[0] = 1;
                string[] memory uris = new string[](0);
                
                uint256[] memory tokenIds = erc1155.mintBaseNew(to, amounts, uris);
                console.log("Minted token IDs:");
                for (uint256 i = 0; i < tokenIds.length; i++) {
                    console.log("  Token ID:", vm.toString(tokenIds[i]));
                }
            }
        }
        
        console.log("Configuration complete!");
        vm.stopBroadcast();
    }
}

