// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DFV} from "../src/DFV.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deployer is Script {
    function _setDeployer() internal {
        uint256 deployerPrivateKey = vm.envUint("DFV_DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
    }
}

contract DeployDFV is Script {
    DFV public dfv;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dfv = new DFV();

        vm.stopBroadcast();
    }
}

contract DeployDFVProxy is Deployer {
    address admin = 0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448;

    function run() external {
        _setDeployer();
        bytes memory data = "";
        DFV impl = new DFV();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            admin,
            data
        );
        DFV dfvProxy = DFV(payable(address(proxy)));
        dfvProxy.mint(msg.sender, 1000000000000000000000000000);
        vm.stopBroadcast();
    }
}
