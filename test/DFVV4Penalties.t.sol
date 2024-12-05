// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DFVV1.sol";
import "../src/DFVV2.sol";
import "../src/DFVV3.sol";
import "../src/DFVV4Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {MockExchange} from "../src/mock/MockExchange.sol";

contract DFVV4TestPenaltiesTest is Test {
    DFVV4Test dfvv4;
    ERC1967Proxy proxy;
    address owner;
    address newOwner;
    address tier1Account;
    address tier2Account;
    address tier3Account;
    address tier4Account;
    address tier5Account;
    address tier0Account;
    MockExchange exchange;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Set up the test environment before running tests
    function setUp() public {
        // Define the owner address
        owner = vm.addr(1);

        // Deploy the token implementation
        DFVV4Test implementation = new DFVV4Test();

        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(implementation.initialize, owner)
        );
        // Attach the DFVV4Test interface to the deployed proxy
        dfvv4 = DFVV4Test(address(proxy));

        // Define tier accounts
        tier1Account = vm.addr(2);
        tier2Account = vm.addr(3);
        tier3Account = vm.addr(4);
        tier4Account = vm.addr(5);
        tier5Account = vm.addr(6);
        tier0Account = vm.addr(7);

        // Define exchange address
        exchange = new MockExchange();

        // Setup exchange whitelist
        vm.prank(owner);
        dfvv4.setExchangeWhitelist(address(exchange), true);

        // set tiers for the accounts
        vm.startPrank(owner);
        dfvv4.setTier(tier1Account, 1);
        dfvv4.setTier(tier2Account, 2);
        dfvv4.setTier(tier3Account, 3);
        dfvv4.setTier(tier4Account, 4);
        dfvv4.setTier(tier5Account, 5);
        vm.stopPrank();

        // approve exchange to spend tokens
        vm.prank(tier1Account);
        dfvv4.approve(address(exchange), type(uint256).max);
        vm.prank(tier2Account);
        dfvv4.approve(address(exchange), type(uint256).max);
        vm.prank(tier3Account);
        dfvv4.approve(address(exchange), type(uint256).max);
        vm.prank(tier4Account);
        dfvv4.approve(address(exchange), type(uint256).max);
        vm.prank(tier5Account);
        dfvv4.approve(address(exchange), type(uint256).max);

        // Emit the owner address for debugging purposes
        emit log_address(owner);
        emit log_address(tier0Account);
        emit log_address(tier1Account);
        emit log_address(tier2Account);
        emit log_address(tier3Account);
        emit log_address(tier4Account);
        emit log_address(address(exchange));
    }

    function testUnderFlowOnPenalty() public {
        vm.startPrank(owner);
        // Mint tokens to tier1 account and assert the balance
        dfvv4.mint(tier1Account, 1e22);
        assertEq(dfvv4.balanceOf(tier1Account), 1e22);
        dfvv4.setTier(tier1Account, 1);
        dfvv4.setSellAllowance(tier1Account, 1000);
        vm.stopPrank();
        // approve the transfer
        vm.prank(tier1Account);
        dfvv4.transfer(address(exchange), 5e20);
        assertEq(dfvv4.balanceOf(tier1Account), 1e22 - 99e20);
    }

    function testTransferToWhitelistedExchangeWithoutAnyInteraction() public {
        vm.startPrank(owner);
        // Mint tokens to tier1 account and assert the balance
        dfvv4.mint(tier1Account, 1000);
        assertEq(dfvv4.balanceOf(tier1Account), 1000);
        dfvv4.setTier(tier1Account, 1);
        dfvv4.setSellAllowance(tier1Account, 1000);
        vm.stopPrank();
        // check balance of tier1 account
        assertEq(dfvv4.balanceOf(tier1Account), 1000);
        // approve the transfer
        vm.prank(tier1Account);
        dfvv4.transfer(address(exchange), 100);
        assertEq(dfvv4.balanceOf(tier1Account), 900);
    }

    function testTransferFrominCommunity() public {
        vm.startPrank(owner);
        // Mint tokens to tier 0 account and assert the balance
        dfvv4.mint(tier0Account, 1000);
        assertEq(dfvv4.balanceOf(tier0Account), 1000);
        vm.stopPrank();
        vm.prank(tier0Account);
        vm.expectRevert();
        dfvv4.transferFrom(tier0Account, tier1Account, 100);
        // check balance of tier0 account
        assertEq(dfvv4.balanceOf(tier0Account), 1000);
        // approve the transfer
        vm.prank(tier0Account);
        dfvv4.approve(tier1Account, 100);
        vm.prank(tier1Account);
        dfvv4.transferFrom(tier0Account, tier1Account, 100);
        assertEq(dfvv4.balanceOf(tier0Account), 900);
    }

    function testUnauthorizedTokenTransferByTier1BurnsWithAccumulativeAllowance()
        public
    {
        vm.startPrank(owner);
        // Mint tokens to tier 0 account and assert the balance
        dfvv4.mint(tier1Account, 1000);
        assertEq(dfvv4.balanceOf(tier1Account), 1000);
        dfvv4.setSellAllowance(tier1Account, 1000);
        assertEq(dfvv4.SellAllowance(tier1Account), 1000);
        vm.stopPrank();
        vm.prank(tier1Account);
        exchange.swap(address(dfvv4), 100);
        assertEq(dfvv4.balanceOf(tier1Account), 900);
        // check sell allowance
        assertEq(dfvv4.SellAllowance(tier1Account), 900);

        // apply penalty
        vm.prank(tier1Account);
        exchange.swap(address(dfvv4), 900);
        assert(dfvv4.balanceOf(tier1Account) < 900);
    }

    function testUnauthorizedTokenTransferByCommunityWorks() public {
        vm.startPrank(owner);
        // Mint tokens to tier 0 account and assert the balance
        dfvv4.mint(tier0Account, 1000);
        assertEq(dfvv4.balanceOf(tier0Account), 1000);
        vm.stopPrank();
        vm.prank(tier0Account);
        dfvv4.transfer(tier1Account, 100);
        assertEq(dfvv4.balanceOf(tier0Account), 900);
    }

    // Test the basic ERC20 functionality of the DFVV1 contract
    /*
     * 1. Unauthorized Token Transfers (Should Trigger Burn Penalty)
     * Scenario 1: Unauthorized Transfer by Tier 1 Participant
     *
     * Action:
     * A Tier 1 participant attempts to transfer tokens to another wallet without authorization.
     *
     * Expected Result:
     * 99% of the transferred tokens are burned.
     * The recipient receives 1% of the intended transfer amount.
     * An event is emitted indicating the burn.
     */
    function testUnauthorizedTokenTransferByTier1Burns() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 1 account and assert the balance
        dfvv4.mint(tier1Account, 1000);
        assertEq(dfvv4.balanceOf(tier1Account), 1000);

        // set sell allowance for the exchange
        dfvv4.setSellAllowance(tier1Account, 1);
        vm.stopPrank();

        // Impersonate the tier 1 account to transfer tokens to exchange
        vm.prank(tier1Account);
        exchange.swap(address(dfvv4), 1000);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(address(exchange)), 10); // 1% of 1000
    }

    /*
    /*
     * Scenario 2: Unauthorized Transfer by Tier 2 Participant
     *
     * Action:
     * A Tier 2 participant tries to sell tokens on an exchange.
     *
     * Expected Result:
     * 97% of the tokens are burned.
     * The exchange receives 3% of the intended amount.
     * An event is emitted indicating the burn.
     *
     */
    function testUnauthorizedTokenTransferByTier2Burns() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 2 account and assert the balance
        dfvv4.mint(tier2Account, 1000);
        assertEq(dfvv4.balanceOf(tier2Account), 1000);

        // set sell allowance for the exchange
        dfvv4.setSellAllowance(tier2Account, 1);
        vm.stopPrank();

        // Impersonate the tier 2 account to transfer tokens to exchange
        vm.prank(tier2Account);
        exchange.swap(address(dfvv4), 1000);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(address(exchange)), 30); // 3% of 1000
    }

    /*
     *
     * Scenario 3: Unauthorized Transfer by Tier 3 Participant
     *
     * Action:
     * A Tier 3 participant sends tokens to a non-whitelisted address.
     *
     * Expected Result:
     * 95% of the tokens are burned.
     * The recipient gets 5% of the intended amount.
     * An event is emitted indicating the burn.
     */
    // Thest the persistance of the previous data
    function testUnauthorizedTokenTransferByTier3Burns() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 3 account and assert the balance
        dfvv4.mint(tier3Account, 1000);
        assertEq(dfvv4.balanceOf(tier3Account), 1000);

        // set sell allowance for the exchange
        dfvv4.setSellAllowance(tier3Account, 1);
        vm.stopPrank();

        // Impersonate the tier 3 account to transfer tokens to exchange
        vm.prank(tier3Account);
        exchange.swap(address(dfvv4), 1000);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(address(exchange)), 50); // 5% of 1000
    }

    /*
     * Scenario 4: Unauthorized Transfer by Tier 4 Participant
     *
     * Action:
     * A Tier 4 participant attempts to transfer tokens before any lock-up period ends.
     *
     * Expected Result:
     * 92% of the tokens are burned.
     * The recipient receives 8% of the intended transfer amount.
     * An event is emitted indicating the burn.
     */
    function testUnauthorizedTokenTransferByTier4Burns() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 4 account and assert the balance
        dfvv4.mint(tier4Account, 1000);
        assertEq(dfvv4.balanceOf(tier4Account), 1000);

        // set sell allowance for the exchange
        dfvv4.setSellAllowance(tier4Account, 1);
        vm.stopPrank();

        // Impersonate the tier 4 account to transfer tokens to exchange
        vm.prank(tier4Account);
        exchange.swap(address(dfvv4), 1000);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(address(exchange)), 80); // 8% of 1000
    }

    /*
     * Scenario 5: Unauthorized Transfer by Airdrop Recipient
     *
     * Action:
     * An airdrop recipient transfers tokens to another address.
     *
     * Expected Result:
     * 99% of the tokens are burned.
     * The recipient gets 1% of the intended transfer amount.
     * An event is emitted indicating the burn.
     */
    function testUnauthorizedTokenTransferByAirdropRecipientBurns() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 5 account and assert the balance
        dfvv4.mint(tier5Account, 1000);
        assertEq(dfvv4.balanceOf(tier5Account), 1000);

        // set sell allowance for the exchange
        dfvv4.setSellAllowance(tier5Account, 1);
        vm.stopPrank();

        // Impersonate the tier 5 account to transfer tokens to exchange
        vm.prank(tier5Account);
        exchange.swap(address(dfvv4), 1000);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(address(exchange)), 10); // 1% of 1000
    }

    /*
     * Scenario 6: Authorized Transfer after Lock-Up Period
     *
     * Action:
     * A participant waits until the lock-up period ends and then transfers tokens.
     *
     * Expected Result:
     * No tokens are burned.
     * The recipient receives the full transfer amount.
     * A standard transfer event is emitted.
     */
    function testAuthorizedTransferAfterLockUpPeriod() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 5 account and assert the balance
        dfvv4.mint(tier5Account, 1000);
        assertEq(dfvv4.balanceOf(tier5Account), 1000);

        // set sell allowance for the exchange
        dfvv4.setSellAllowance(tier5Account, 10000);
        vm.stopPrank();

        // Impersonate the tier 5 account to transfer tokens to exchange
        vm.prank(tier5Account);
        exchange.swap(address(dfvv4), 1000);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(address(exchange)), 1000); // 1% of 1000
    }

    /*
     * Scenario 7: Transfer to Whitelisted Address
     *
     * Action:
     * A participant transfers tokens to an address that is authorized to receive tokens without penalties.
     *
     * Expected Result:
     * No tokens are burned.
     * The recipient receives the full transfer amount.
     * A standard transfer event is emitted.
     */
    function testTransferToWhitelistedAddress() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 5 account and assert the balance
        dfvv4.mint(tier1Account, 1000);
        assertEq(dfvv4.balanceOf(tier1Account), 1000);

        // set OTC Whitelist from tier 1 account to tier 2 account
        dfvv4.setOTCAllowance(tier1Account, tier2Account, 100);
        vm.stopPrank();

        // Impersonate the tier 1 account to transfer tokens to tier 2 account
        vm.prank(tier1Account);
        dfvv4.transfer(tier2Account, 100);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(tier1Account), 900); // 1% of 1000

        // expect error when tier 1 account tries to transfer to tier 2 account again
        vm.prank(tier1Account);
        vm.expectRevert();
        dfvv4.transfer(tier2Account, 100);
    }

    /*
     * Scenario 10: Batch Transfers
     *
     * Action:
     * A participant tries to transfer tokens to multiple addresses in one transaction.
     *
     * Expected Result:
     * Burn penalty is applied to each unauthorized transfer.
     * Total tokens burned match the sum of penalties.
     * Burn events are emitted for each transfer.
     */
    function testBatchTransfers() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        dfvv4.mint(tier2Account, 3000);
        assertEq(dfvv4.balanceOf(tier2Account), 3000);

        // Set the participant to Tier 3
        vm.startPrank(owner);
        dfvv4.setTier(tier2Account, 3);

        // Set OTC whitelist from address(2) to address(5)
        dfvv4.setOTCAllowance(tier2Account, tier3Account, 1000);
        dfvv4.setOTCAllowance(tier2Account, tier4Account, 1000);
        dfvv4.setOTCAllowance(tier2Account, tier5Account, 1000);
        vm.stopPrank();

        // Impersonate the participant to batch transfer tokens to multiple addresses
        address[] memory recipients = new address[](3);
        recipients[0] = tier3Account;
        recipients[1] = tier4Account;
        recipients[2] = tier5Account;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1000;
        amounts[1] = 1000;
        amounts[2] = 1000;

        for (uint256 i = 0; i < recipients.length; i++) {
            vm.prank(tier2Account);
            dfvv4.transfer(recipients[i], amounts[i]);
        }

        // Assert the balances after the batch transfers
        // 95% of the tokens should be burned for each transfer, so only 5% should be transferred
        assertEq(dfvv4.balanceOf(tier2Account), 0); // Remaining balance after transfers
        assertEq(dfvv4.balanceOf(tier3Account), 1000); // 5% of 1000
        assertEq(dfvv4.balanceOf(tier4Account), 1000); // 5% of 1000
        assertEq(dfvv4.balanceOf(tier5Account), 1000); // 5% of 1000
    }

    /*
     * Scenario 14: Total Supply Reduction
     *
     * Action:
     * After several burns, check the total token supply.
     *
     * Expected Result:
     * Total supply decreases by the total amount of tokens burned.
     * Supply numbers match expected values.
     */
    function testTotalSupplyReduction() public {
        // Impersonate the owner to call mint function
        vm.startPrank(owner);
        // Mint tokens to tier 1 account and assert the balance
        dfvv4.mint(tier1Account, 1000);
        assertEq(dfvv4.balanceOf(tier1Account), 1000);

        // set sell allowance for the exchange
        dfvv4.setSellAllowance(tier1Account, 1);
        vm.stopPrank();

        // Impersonate the tier 1 account to transfer tokens to exchange
        vm.prank(tier1Account);
        exchange.swap(address(dfvv4), 1000);

        // Assert the balances the exchange receives after the transfer
        assertEq(dfvv4.balanceOf(address(exchange)), 10); // 1% of 1000
        assertEq(dfvv4.totalSupply(), 10); // because 99% of 1000 is burned
    }
}
