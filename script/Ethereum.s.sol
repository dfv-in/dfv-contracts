// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DFV} from "../src/DFV.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

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
        dfv.mint(0xF5D46bDe4dC092aa637A7A04212Acb7aB030fa32, 138_840_000_000 * 10**18);

        vm.stopBroadcast();
    }
}

contract DFVProxy is TransparentUpgradeableProxy, AccessControl {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }
}

contract DeployDFVProxy is Deployer {
    address admin = 0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448;

    function run() external {
        _setDeployer();
        bytes memory data = "";
        DFV impl = new DFV();
        ProxyAdmin proxyAdmin = new ProxyAdmin(admin);
        DFVProxy proxy = new DFVProxy(
            address(impl),
            address(proxyAdmin),
            data
        );
        proxyAdmin.transferOwnership(admin);
        DFV dfvProxy = DFV((address(proxy)));
         // Grant DEFAULT_ADMIN_ROLE to the deployer
        dfvProxy.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), admin);
        
        // Grant MINTER_ROLE to the deployer
        dfvProxy.grantRole(keccak256("MINTER_ROLE"), admin);
    
        dfvProxy.mint(address(1), 1000000000000000000000000000);
        vm.stopBroadcast();
    }
}
