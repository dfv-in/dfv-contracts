// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DFV} from "../src/DFV.sol";

contract DFVTest is Test {
    DFV public dfv;

    // DAO can set exchange whitelist

    // DAO can set allowed sell amount

    // DAO can set OTC whitelist amount

    // DAO can set OTC whitelist to all receivers in case of token sale with limited amount

    // DFV can send tokens with OTC whitelist

    // DFV can be minted with only max supply

    // DFV has penalty logic on unauthorized sales
}
