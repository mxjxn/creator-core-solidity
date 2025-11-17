// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/ERC721Creator.sol";
import "../contracts/ERC1155Creator.sol";
import "../contracts/ERC721CreatorImplementation.sol";
import "../contracts/ERC1155CreatorImplementation.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

/**
 * @title DeployCreatorCore
 * @notice Comprehensive deployment script for all Creator Core contract types
 * @dev Supports ERC721/ERC1155, upgradeable and non-upgradeable variants
 */
contract DeployCreatorCore is Script {
    struct DeploymentConfig {
        string name;
        string symbol;
        bool isERC721;
        bool isUpgradeable;
        address owner;
    }

    function run() external {
        // Read configuration from environment or use defaults
        string memory name = vm.envOr("CONTRACT_NAME", string("My NFT Collection"));
        string memory symbol = vm.envOr("CONTRACT_SYMBOL", string("MNFT"));
        bool isERC721 = vm.envOr("IS_ERC721", true);
        bool isUpgradeable = vm.envOr("IS_UPGRADEABLE", false);
        address owner = vm.envOr("OWNER", msg.sender);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DeploymentConfig memory config = DeploymentConfig({
            name: name,
            symbol: symbol,
            isERC721: isERC721,
            isUpgradeable: isUpgradeable,
            owner: owner
        });

        address deployedAddress;

        if (isUpgradeable) {
            deployedAddress = _deployUpgradeable(config);
        } else {
            deployedAddress = _deployNonUpgradeable(config);
        }

        console.log("==========================================");
        console.log("Deployment Complete!");
        console.log("==========================================");
        console.log("Contract Type:", isERC721 ? "ERC721" : "ERC1155");
        console.log("Upgradeable:", isUpgradeable ? "Yes" : "No");
        console.log("Name:", config.name);
        console.log("Symbol:", config.symbol);
        console.log("Deployed Address:", deployedAddress);
        console.log("Owner:", config.owner);
        console.log("==========================================");

        // Save deployment info to JSON
        _saveDeploymentInfo(deployedAddress, config);

        vm.stopBroadcast();
    }

    function _deployNonUpgradeable(DeploymentConfig memory config) internal returns (address) {
        if (config.isERC721) {
            ERC721Creator creator = new ERC721Creator(config.name, config.symbol);
            // Transfer ownership if different from deployer
            if (creator.owner() != config.owner) {
                creator.transferOwnership(config.owner);
            }
            return address(creator);
        } else {
            ERC1155Creator creator = new ERC1155Creator(config.name, config.symbol);
            // Transfer ownership if different from deployer
            if (creator.owner() != config.owner) {
                creator.transferOwnership(config.owner);
            }
            return address(creator);
        }
    }

    function _deployUpgradeable(DeploymentConfig memory config) internal returns (address) {
        // Deploy implementation
        address implementation;
        if (config.isERC721) {
            ERC721CreatorImplementation impl = new ERC721CreatorImplementation();
            implementation = address(impl);
        } else {
            ERC1155CreatorImplementation impl = new ERC1155CreatorImplementation();
            implementation = address(impl);
        }

        console.log("Implementation deployed at:", implementation);

        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            config.isERC721
                ? ERC721CreatorImplementation.initialize.selector
                : ERC1155CreatorImplementation.initialize.selector,
            config.name,
            config.symbol
        );

        // Deploy proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            address(proxyAdmin),
            initData
        );

        console.log("Proxy deployed at:", address(proxy));

        // Transfer ProxyAdmin ownership if needed
        if (proxyAdmin.owner() != config.owner) {
            proxyAdmin.transferOwnership(config.owner);
        }

        // Transfer contract ownership
        if (config.isERC721) {
            ERC721CreatorImplementation(address(proxy)).transferOwnership(config.owner);
        } else {
            ERC1155CreatorImplementation(address(proxy)).transferOwnership(config.owner);
        }

        return address(proxy);
    }

    function _saveDeploymentInfo(address deployedAddress, DeploymentConfig memory config) internal {
        string memory filename = string.concat("deployments/", vm.toString(block.chainid), ".json");
        
        // Create deployments directory if it doesn't exist
        try vm.fsMetadata("deployments") returns (VmSafe.FsMetadata memory) {} catch {
            vm.writeFile("deployments/.gitkeep", "");
        }

        // Read existing deployments or create new
        string memory existingData = "";
        try vm.readFile(filename) returns (string memory data) {
            existingData = data;
        } catch {}

        // Parse or create JSON
        string memory deploymentJson = string.concat(
            '{"address":"',
            vm.toString(deployedAddress),
            '","name":"',
            config.name,
            '","symbol":"',
            config.symbol,
            '","type":"',
            config.isERC721 ? "ERC721" : "ERC1155",
            '","upgradeable":',
            config.isUpgradeable ? "true" : "false",
            ',"owner":"',
            vm.toString(config.owner),
            '","chainId":',
            vm.toString(block.chainid),
            ',"blockNumber":',
            vm.toString(block.number),
            ',"timestamp":',
            vm.toString(block.timestamp),
            '}'
        );

        // Append to file (simple approach - in production, use proper JSON library)
        vm.writeLine(filename, deploymentJson);
    }
}

