// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/DFVV1.sol";
import "../src/DFVV2.sol";
import "../src/DFVV4.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract Deployer is Script {
    function _setDeployer() internal {
        uint256 deployerPrivateKey = vm.envUint("DFV_DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
    }
}

contract DeployDFVProxy is Deployer {
    function run() public {
        _setDeployer();
        // Deploy the ERC-20 token
        DFVV4 implementation = new DFVV4();

        // Log the token address
        console.log("Token Implementation Address:", address(implementation));

        // prompt the deployer address to get admin access
        address deployerAddress = vm.promptAddress("Enter the deployer address to grant admin access");

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(
                implementation.initialize,
                deployerAddress
            )
        );

        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));

        // prompt the DAO address to receive 67_337_400_000 DFV tokens for liquidity provision
        address daoAddress = vm.promptAddress("Enter the DAO address to receive 67_337_400_000 DFV tokens for liquidity provision");

        DFV(address(proxy)).mint(
            daoAddress,
            67_337_400_000 * 1e18
        );

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract UpgradeDFVProxy is Deployer {
    address proxy;
    function run() public {
        _setDeployer();

        // prompt for the proxy address
        proxy = vm.promptAddress("Enter the DFV token proxy address to upgrade");

        // prompt for the deployer address to grant admin access
        address deployerAddress = vm.promptAddress("Enter the deployer address to grant admin access");
        
        // Log the token address
        //console.log("Token Implementation Address:", address(implementation));

        Upgrades.upgradeProxy(address(proxy), "DFVV4.sol:DFVV4", "", deployerAddress);

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract AddPresale is Deployer {
    address proxy;
    function run() public {
        _setDeployer();

         // prompt for the proxy address
        proxy = vm.promptAddress("Enter the DFV token proxy address to upgrade");

        
        // prompt for the presale recipient address
        address presaleRecipient = vm.promptAddress("Enter the presale recipient address");

        // prompt for the presale amount
        uint256 presaleAmount = vm.promptUint("Enter the presale amount without 18 decimals");

        DFVV4(address(proxy)).mint(
            address(presaleRecipient),
            presaleAmount * 1e18
        );

        // set the presale tier
        uint256 presaleTier = vm.promptUint("Enter the presale tier (0, 1, 2, 3, 4, or 5)");
        DFVV4(address(proxy)).setTier(presaleRecipient, presaleTier);

        // set the allowed sell presale amount

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract SetSaleAllowance is Deployer {
    address proxy = 0x030c5FF9aaFd365fB2fe6215bE614a8Ee765eaFd;
    function run() public {
        _setDeployer();
        
        // prompt for the presale recipient address
        address allowanceAccount = vm.promptAddress("Enter the address to set the sale allowance for");

        // set the presale tier
        uint256 allowance = vm.promptUint("Enter the allowance DFV token amount in 18 decimals");
        DFVV4(address(proxy)).setSellAllowance(allowanceAccount, allowance);

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}
