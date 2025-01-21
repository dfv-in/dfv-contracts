// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/DFVV1.sol";
import "../src/DFVV2.sol";
import "../src/DFVV4.sol";
import {TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";


interface ITransparentUpgradeableProxy {
    function changeAdmin(address newAdmin) external;
    function upgradeTo(address newImplementation) external;
    function admin() external view returns (address);
}

import {Script, console} from "forge-std/Script.sol";

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

        // Deploy the proxy contract with the implementation address and initializer
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448),
            abi.encodeCall(
                implementation.initialize,
                0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448
            )
        );

        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));

        DFV(address(proxy)).mint(
            address(0xF5D46bDe4dC092aa637A7A04212Acb7aB030fa32),
            138_840_000_000 * 10 ** 18
        );        

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract UpgradeDFVProxy is Deployer {
    address proxy = 0xA0D465b1e213Ea5C4E099F998C5cACC68328690D;

    function run() public {
        _setDeployer();

        // Log the token address
        //console.log("Token Implementation Address:", address(implementation));

        Upgrades.upgradeProxy(
            address(proxy),
            "DFVV4.sol:DFVV4",
            "",
            0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448
        );

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract AddPresale is Deployer {
    address proxy = 0xA0D465b1e213Ea5C4E099F998C5cACC68328690D;

    function run() public {
        _setDeployer();

        // prompt for the presale recipient address
        address presaleRecipient = vm.promptAddress(
            "Enter the presale recipient address"
        );

        // prompt for the presale amount
        uint256 presaleAmount = vm.promptUint(
            "Enter the presale amount without 18 decimals"
        );

        DFVV4(address(proxy)).mint(
            address(presaleRecipient),
            presaleAmount * 1e18
        );

        // set the presale tier
        uint256 presaleTier = vm.promptUint(
            "Enter the presale tier (0, 1, 2, 3, 4, or 5)"
        );
        DFVV4(address(proxy)).setTier(presaleRecipient, presaleTier);

        // set the allowed sell presale amount

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract GetTier is Deployer {
    address proxy = 0xA0D465b1e213Ea5C4E099F998C5cACC68328690D;

    function run() public {
        _setDeployer();

        // prompt for the presale recipient address
        address presaleRecipient = vm.promptAddress(
            "Enter the presale recipient address"
        );

        DFVV4(address(proxy)).memberTiers(presaleRecipient);
        vm.prank(presaleRecipient);
        DFVV4(address(proxy)).transfer(
            0xA0D465b1e213Ea5C4E099F998C5cACC68328690D,
            10
        );
        vm.stopBroadcast();
    }
}

contract SetSaleAllowance is Deployer {
    address proxy = 0xA0D465b1e213Ea5C4E099F998C5cACC68328690D;

    function run() public {
        _setDeployer();

        // prompt for the presale recipient address
        address allowanceAccount = vm.promptAddress(
            "Enter the address to set the sale allowance for"
        );

        // set the presale tier
        uint256 allowance = vm.promptUint(
            "Enter the allowance DFV token amount in 18 decimals"
        );
        DFVV4(address(proxy)).setSellAllowance(allowanceAccount, allowance);

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}
