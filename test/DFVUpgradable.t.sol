// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/DFVV1.sol";
import "forge-std/console.sol";
import "../src/DFVV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DFVV1Test is Test {
    DFV dfvv1;
    ERC1967Proxy proxy;
    address owner;
    address newOwner;

    // Set up the test environment before running tests
    function setUp() public {
        // Deploy the token implementation
        DFV implementation = new DFV();
        // Define the owner address
        owner = vm.addr(1);
        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, owner));
        // Attach the DFVV1 interface to the deployed proxy
        dfvv1 = DFV(address(proxy));
        // Define a new owner address for upgrade tests
        newOwner = address(1);
        // Emit the owner address for debugging purposes
        emit log_address(owner);
    }

    // Test the basic ERC20 functionality of the DFVV1 contract
    function testERC20Functionality() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        dfvv1.mint(address(2), 1000);
        assertEq(dfvv1.balanceOf(address(2)), 1000);
    }

    // Test the upgradeability of the DFVV1 contract
    function testUpgradeability() public {
        // Upgrade the proxy to a new version; DFVV2
        Upgrades.upgradeProxy(address(proxy), "DFVV2.sol:DFVV2", "", owner);
        // test whether the new contract is upgraded

        DFVV2 dfvv2 = DFVV2(address(proxy));

        // Owner should be able to mint tokens
        vm.prank(owner);
        dfvv2.mint(address(2), 1000);

        vm.prank(address(1));
        vm.expectRevert();
        dfvv2.mint(address(2), 1000);
    }
}