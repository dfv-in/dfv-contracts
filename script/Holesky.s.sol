// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/DFVV1.sol";
import "../src/DFVV2.sol";
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
        DFV implementation = new DFV();

        // Log the token address
        console.log("Token Implementation Address:", address(implementation));

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(
                implementation.initialize,
                0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448
            )
        );

        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));

        DFV(address(proxy)).mint(
            address(0xdF80e38699bb963a91c5F04F83378A597995932a),
            67_337_400_000 * 1e18
        );

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract UpgradeDFVProxy is Deployer {
    address proxy = 0x030c5FF9aaFd365fB2fe6215bE614a8Ee765eaFd;
    function run() public {
        _setDeployer();
        
        // Log the token address
        //console.log("Token Implementation Address:", address(implementation));

        Upgrades.upgradeProxy(address(proxy), "DFVV2.sol:DFVV2", "", 0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448);

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}
