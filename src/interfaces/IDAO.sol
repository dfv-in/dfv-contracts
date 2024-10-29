pragma solidity ^0.8.22;
interface IDAO {
    function isOk(address from, address to, uint256 value) external returns (uint256 burnAmount);
}