// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {IDAO} from "./interfaces/IDAO.sol";

/// @notice OFT is an ERC-20 token that extends the OFTCore contract.
contract DFV is OFT {

    address public dao;
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        address _dao
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        dao = _dao;
    }
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 burnAmount = IDAO(dao).isOk(msg.sender, to, value);
        if(burnAmount > 0) {
            // burn token from owner
            _burn(msg.sender, burnAmount);
        }
        _transfer(owner, to, allowedAmount);
        return true;
    }
}
