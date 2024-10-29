// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DFV} from "../src/DFV.sol";

contract DeployDFV is Script {
    DFV public dfv;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dfv = new DFV(
            "DeepFuckinValue",
            "DFV",
            address(0),
            address(0),
            address(0)
        );

        vm.stopBroadcast();
    }
}
