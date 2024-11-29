// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DFVV1.sol";
import "../src/DFVV2.sol";
import "../src/DFVV3.sol";
import "../src/DFVV4.sol";
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

    // Thest the persistance of the previous data
    function testPersistenceOfDataAfterUpgrade() public {
        // Mint tokens with DFVV1
        vm.prank(owner);
        dfvv1.mint(address(2), 15000);

        // Upgrade the proxy to DFVV2
        Upgrades.upgradeProxy(address(proxy), "DFVV2.sol:DFVV2", "", owner);
        DFVV2 dfvv2 = DFVV2(address(proxy));

        // Check that the balance of address(2) is still 1000
        assertEq(dfvv2.balanceOf(address(2)), 15000);
    }

    // Test that the new functionalities provided by the v2 are usable
    function testNewFunctionalityInDFVV2() public {
        // Upgrade to DFVV2
        Upgrades.upgradeProxy(address(proxy), "DFVV2.sol:DFVV2", "", owner);
        DFVV2 dfvv2 = DFVV2(address(proxy));

        // Test new functionality
        vm.prank(owner);
        dfvv2.storeAnAddress(owner);

        // Assert that the stored address matches the owner
        assertEq(dfvv2.storedAddress(), owner);
    }
    
    // Test that the v3 has access to the data introduced in v2
    function testV3AccessToDataFromV2() public {
        // Upgrade the proxy to DFVV2
        Upgrades.upgradeProxy(address(proxy), "DFVV2.sol:DFVV2", "", owner);
        DFVV2 dfvv2 = DFVV2(address(proxy));

        // Store an address using DFVV2
        vm.prank(owner);
        dfvv2.storeAnAddress(owner);

        // Upgrade the proxy to DFVV3
        Upgrades.upgradeProxy(address(proxy), "DFVV3.sol:DFVV3", "", owner);
        DFVV3 dfvv3 = DFVV3(address(proxy));

        // Ensure the stored address is still accessible in DFVV3
        assertEq(dfvv3.storedAddress(), owner);
    }

    // Test that the v4 has access to the data introduced in v2
    function testV4AccessToDataFromV2() public {
        // Upgrade the proxy to DFVV2
        Upgrades.upgradeProxy(address(proxy), "DFVV3.sol:DFVV3", "", owner);
        DFVV3 dfvv3 = DFVV3(address(proxy));

        // Store an address using DFVV2
        vm.prank(owner);
        dfvv3.storeAnAddress(owner);

        // Upgrade the proxy to DFVV3
        Upgrades.upgradeProxy(address(proxy), "DFVV4.sol:DFVV4", "", owner);
        DFVV4 dfvv4 = DFVV4(address(proxy));

        // Ensure the stored address is still accessible in DFVV3
        assertEq(dfvv4.storedAddress(), owner);
    }
}