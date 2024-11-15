// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

/// @custom:oz-upgrades-from DFV
contract DFVV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor

    error InvalidRole(bytes32 role, address sender);

    function initialize(address initialOwner) public initializer {
        _disableInitializers();
        __ERC20_init("DeepFuckinValue", "DFV");
        __AccessControl_init();
        __ERC20Permit_init("DFVV2");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
        _mint(to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
