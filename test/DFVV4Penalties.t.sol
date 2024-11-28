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
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {MockExchange} from "../src/mock/MockExchange.sol";

contract DFVV4PenaltiesTest is Test {
    DFVV4 dfvv4;
    ERC1967Proxy proxy;
    address owner;
    address newOwner;
    address tier1Account;
    address tier2Account;
    address tier3Account;
    address tier4Account;
    MockExchange exchange;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Set up the test environment before running tests
    function setUp() public {
        // Define the owner address
        owner = vm.addr(1);

        // Deploy the token implementation
        DFVV4 implementation = new DFVV4();

        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(implementation.initialize, owner)
        );
        // Attach the DFVV4 interface to the deployed proxy
        dfvv4 = DFVV4(address(proxy));

         // Define tier accounts
        tier1Account = vm.addr(2);
        tier2Account = vm.addr(3);
        tier3Account = vm.addr(4);
        tier4Account = vm.addr(5);

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

        // Emit the owner address for debugging purposes
        emit log_address(owner);
        emit log_address(tier1Account);
        emit log_address(tier2Account);
        emit log_address(tier3Account);
        emit log_address(tier4Account);
        emit log_address(address(exchange));
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
        dfvv4.setSellAllowance(address(exchange), 1);
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
        dfvv4.setSellAllowance(address(exchange), 1);
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
        dfvv4.setSellAllowance(address(exchange), 1);
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
        dfvv4.setSellAllowance(address(exchange), 1);
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
    function testUnauthorizedTokenTransferByAirdropRecipientBurns() public {}

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
    function testAuthorizedTransferAfterLockUpPeriod() public {}

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
    function testTransferToWhitelistedAddress() public {}

    /*
     * Scenario 8: Unauthorized Interaction with a Smart Contract
     *
     * Action:
     * A participant attempts to interact with a DeFi protocol (e.g., staking, lending) without authorization.
     *
     * Expected Result:
     * Applicable burn penalty is applied based on their tier.
     * Only the remaining tokens after the burn are processed.
     * An event is emitted indicating the burn.
     */
    function testUnauthorizedInteractionWithSmartContract() public {}

    /*
     * Scenario 9: Authorized Interaction with a Smart Contract
     *
     * Action:
     * A participant interacts with an approved smart contract.
     *
     * Expected Result:
     * No tokens are burned.
     * The interaction proceeds normally.
     * Standard events are emitted.
     */
    function testAuthorizedInteractionWithSmartContract() public {}

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
        dfvv4.mint(address(2), 3000);
        assertEq(dfvv4.balanceOf(address(2)), 3000);

        // Set the participant to Tier 3
        vm.prank(owner);
        dfvv4.setTier(address(2), 3);

        // Impersonate the participant to batch transfer tokens to multiple addresses
        address[] memory recipients = new address[](3);
        recipients[0] = address(3);
        recipients[1] = address(4);
        recipients[2] = address(5);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1000;
        amounts[1] = 1000;
        amounts[2] = 1000;

        for (uint256 i = 0; i < recipients.length; i++) {
            vm.prank(address(2));
            dfvv4.transfer(recipients[i], amounts[i]);
        }

        // Assert the balances after the batch transfers
        // 95% of the tokens should be burned for each transfer, so only 5% should be transferred
        assertEq(dfvv4.balanceOf(address(2)), 0); // Remaining balance after transfers
        assertEq(dfvv4.balanceOf(address(3)), 50); // 5% of 1000
        assertEq(dfvv4.balanceOf(address(4)), 50); // 5% of 1000
        assertEq(dfvv4.balanceOf(address(5)), 50); // 5% of 1000
    }

    /*
     * Scenario 11: Transfers of Minimal Amounts
     *
     * Action:
     * A participant transfers a very small number of tokens (e.g., 10 tokens).
     *
     * Expected Result:
     * Burn penalty is correctly calculated (consider rounding).
     * The recipient receives the correct amount.
     * An event is emitted indicating the burn.
     */
    function testTransfersOfMinimalAmounts() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        dfvv4.mint(address(2), 10);
        assertEq(dfvv4.balanceOf(address(2)), 10);

        // Set the participant to Tier 3
        vm.prank(owner);
        dfvv4.setTier(address(2), 3);

        // Impersonate the participant to transfer a minimal amount of tokens
        vm.prank(address(2));
        dfvv4.transfer(address(3), 10);

        // Assert the balances after the transfer
        // 95% of the tokens should be burned, so only 5% should be transferred
        assertEq(dfvv4.balanceOf(address(2)), 0); // Remaining balance after transfer
    }

    /*
     * Scenario 12: Use of Proxy Contracts
     *
     * Action:
     * A participant uses a proxy contract to transfer tokens, attempting to bypass the burn.
     *
     * Expected Result:
     * Burn mechanism still applies.
     * Tokens are burned according to the penalty rate.
     * An event is emitted indicating the burn.
     */
    function testUseOfProxyContracts() public {}

    /*
     * Scenario 13: Approve and TransferFrom
     *
     * Action:
     * A participant approves another address to spend tokens, and that address attempts a transfer.
     *
     * Expected Result:
     * Burn penalty is applied if the transfer is unauthorized.
     * An event is emitted indicating the burn.
     */
    function testApproveAndTransferFrom() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        dfvv4.mint(address(2), 1000);
        assertEq(dfvv4.balanceOf(address(2)), 1000);

        // Set the participant to Tier 3
        vm.prank(owner);
        dfvv4.setTier(address(2), 3);

        // Impersonate the participant to approve another address (address(3)) to spend tokens
        vm.prank(address(2));
        dfvv4.approve(address(3), 1000);

        // Impersonate the approved address to transfer tokens
        vm.prank(address(3));
        dfvv4.transferFrom(address(2), address(4), 1000);

        // Assert the balances after the transfer
        // 95% of the tokens should be burned, so only 5% should be transferred
        assertEq(dfvv4.balanceOf(address(2)), 0); // Remaining balance after transfer
        assertEq(dfvv4.balanceOf(address(4)), 50); // 5% of 1000
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
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        dfvv4.mint(address(2), 1000);
        assertEq(dfvv4.balanceOf(address(2)), 1000);

        // Set the participant to Tier 3
        vm.prank(owner);
        dfvv4.setTier(address(2), 3);

        // Impersonate the participant to transfer tokens to another address
        vm.prank(address(2));
        dfvv4.transfer(address(3), 1000);

        // Assert the balances after the transfer
        // 95% of the tokens should be burned, so only 5% should be transferred
        assertEq(dfvv4.balanceOf(address(2)), 0); // Remaining balance after transfer
        assertEq(dfvv4.balanceOf(address(3)), 50); // 5% of 1000

        // Check the total supply reduction
        uint256 expectedTotalSupply = 1000 - 950; // Initial supply - burned tokens
        assertEq(dfvv4.totalSupply(), expectedTotalSupply);
    }

    /*
     * Scenario 15: Mix of Tokens with Transfer Bigger than LP Purchase (Presale + Purchased on DEFI)
     *
     * Action:
     * A Tier 1 participant also purchased on LP and attempts to transfer tokens to another wallet without authorization more than what he bought on LP.
     *
     * Expected Result:
     * 99% of the transferred tokens that are bigger than LP purchase are burned.
     * The recipient receives 1% of the intended transfer amount.
     * An event is emitted indicating the burn.
     */
    function testMixOfTokensWithTransferBiggerThanLPPurchase() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint presale tokens to address(2) and assert the balance
        dfvv4.mint(address(2), 1000);
        assertEq(dfvv4.balanceOf(address(2)), 1000);

        // Simulate LP purchase by minting additional tokens to address(2)
        vm.prank(owner);
        dfvv4.mint(address(2), 500);
        assertEq(dfvv4.balanceOf(address(2)), 1500);

        // Set the participant to Tier 1
        vm.prank(owner);
        dfvv4.setTier(address(2), 1);

        // Impersonate the participant to transfer tokens to another address
        vm.prank(address(2));
        dfvv4.transfer(address(3), 1200);

        // Assert the balances after the transfer
        // 99% of the transferred tokens that are bigger than LP purchase should be burned
        uint256 lpPurchase = 500;
        uint256 unauthorizedTransfer = 1200 - lpPurchase;
        uint256 burnedTokens = (unauthorizedTransfer * 99) / 100;
        uint256 transferredTokens = 1200 - burnedTokens;

        assertEq(dfvv4.balanceOf(address(2)), 300); // Remaining balance after transfer
        assertEq(dfvv4.balanceOf(address(3)), transferredTokens); // 1% of unauthorized transfer + LP purchase
    }

    /*
     * Scenario 16: Mix of Tokens with Transfer Smaller than LP Purchase (Presale + Purchased on DEFI)
     *
     * Action:
     * A Tier 1 participant also purchased on LP and attempts to transfer tokens to another wallet without authorization but less than what he bought on LP.
     *
     * Expected Result:
     * No tokens are burned.
     */
    function testMixOfTokensWithTransferSmallerThanLPPurchase() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint presale tokens to address(2) and assert the balance
        dfvv4.mint(address(2), 1000);
        assertEq(dfvv4.balanceOf(address(2)), 1000);

        // Simulate LP purchase by minting additional tokens to address(2)
        vm.prank(owner);
        dfvv4.mint(address(2), 500);
        assertEq(dfvv4.balanceOf(address(2)), 1500);

        // Set the participant to Tier 1
        vm.prank(owner);
        dfvv4.setTier(address(2), 1);

        // Impersonate the participant to transfer tokens to another address
        vm.prank(address(2));
        dfvv4.transfer(address(3), 400);

        // Assert the balances after the transfer
        // No tokens should be burned since the transfer amount is less than the LP purchase
        assertEq(dfvv4.balanceOf(address(2)), 1100); // Remaining balance after transfer
        assertEq(dfvv4.balanceOf(address(3)), 400); // Full amount transferred
    }
}
