// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockExchange {
    function swap(address token1, uint256 amount) public {
        IERC20(token1).transferFrom(msg.sender, address(this), amount);
    }
}