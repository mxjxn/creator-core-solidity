// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title VerifyContracts
 * @notice Script to verify deployed Creator Core contracts on Etherscan/Basescan
 * @dev Reads contract addresses from deployments JSON and verifies them
 */
contract VerifyContracts is Script {
    function run() external {
        uint256 chainId = vm.envOr("CHAIN_ID", block.chainid);
        string memory contractAddress = vm.envString("CONTRACT_ADDRESS");
        
        // Determine if contract is ERC721 or ERC1155
        // This would need to be passed as env var or read from deployments JSON
        bool isERC721 = vm.envOr("IS_ERC721", true);
        bool isUpgradeable = vm.envOr("IS_UPGRADEABLE", false);
        
        string memory name = vm.envOr("CONTRACT_NAME", string("My NFT Collection"));
        string memory symbol = vm.envOr("CONTRACT_SYMBOL", string("MNFT"));
        
        console.log("Verifying contract...");
        console.log("Address:", contractAddress);
        console.log("Type:", isERC721 ? "ERC721" : "ERC1155");
        console.log("Upgradeable:", isUpgradeable ? "Yes" : "No");
        
        if (isUpgradeable) {
            // For upgradeable contracts, verify the implementation
            string memory implAddress = vm.envString("IMPLEMENTATION_ADDRESS");
            console.log("Implementation Address:", implAddress);
            
            // Verify implementation
            _verifyImplementation(implAddress, isERC721);
        } else {
            // For non-upgradeable, verify directly
            _verifyContract(contractAddress, name, symbol, isERC721);
        }
    }
    
    function _verifyContract(
        string memory contractAddress,
        string memory name,
        string memory symbol,
        bool isERC721
    ) internal {
        string memory contractName = isERC721 ? "ERC721Creator" : "ERC1155Creator";
        string memory contractPath = string.concat("contracts/", contractName, ".sol:", contractName);
        
        console.log("Contract Path:", contractPath);
        console.log("Constructor Args - name:", name);
        console.log("Constructor Args - symbol:", symbol);
        
        // Note: Actual verification would use forge verify-contract command
        // This script serves as a template and reminder
        console.log("Run the following command to verify:");
        console.log("forge verify-contract \\");
        console.log("  Contract Address:", contractAddress);
        console.log("  Contract Path:", contractPath);
        console.log("  Chain ID:", vm.toString(block.chainid));
        console.log("  Constructor args: (cast abi-encode 'constructor(string,string)' name symbol)");
    }
    
    function _verifyImplementation(
        string memory implAddress,
        bool isERC721
    ) internal {
        string memory contractName = isERC721 
            ? "ERC721CreatorImplementation" 
            : "ERC1155CreatorImplementation";
        string memory contractPath = string.concat("contracts/", contractName, ".sol:", contractName);
        
        console.log("Implementation Path:", contractPath);
        console.log("Note: Implementation has no constructor args");
        
        console.log("Run the following command to verify implementation:");
        console.log("forge verify-contract");
        console.log("  Implementation Address:", implAddress);
        console.log("  Contract Path:", contractPath);
        console.log("  Chain ID:", vm.toString(block.chainid));
    }
}

