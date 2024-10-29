// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {IDAO} from "./interfaces/IDAO.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice OFT is an ERC-20 token that extends the OFTCore contract.
contract DFV is OFT, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private constant MAX_SUPPLY = 138_840_000_000 * 10**18; // 138.84 billion tokens with 18 decimals
    error MaxSupplyReached(uint256 currentSupply, uint256 newSupply);


    address public dao;
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        address _dao
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        dao = _dao;

        // Grant the contract deployer the default admin role: they can grant and revoke any roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant the minter role to the deployer
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert MaxSupplyReached(totalSupply(), totalSupply() + amount);
        }
        _mint(to, amount);
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
