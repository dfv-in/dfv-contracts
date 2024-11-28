// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

/// @custom:oz-upgrades-from DFV
contract DFVV4 is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    /// address value to represent all addresses in whitelist
    address constant ALL = address(1);
    /// total supply of the token
    uint256 private constant MAX_SUPPLY = 138_840_000_000 * 10 ** 18; // 138.84 billion tokens with 18 decimals

    address private _storedAddress; // Variable to store an address for testing state throughout upgrades

    /// enum for identifying tiers
    enum DFVTiers {
        // first value in Enum is the default value
        Community,
        BlindBelievers,
        EthernalHodlers,
        DiamondHands,
        JustHodlers
    }

    /// mapping for whitelisting
    mapping(address => mapping(address => uint256)) public OTCAllowance;

    /// mapping for exchange whitelisting
    mapping(address => bool) public ExchangeWhiteLists;

    /// mapping to register tiers of each member
    mapping(address => DFVTiers) public MemberTiers;

    /// address for Allowed Liquidation Platforms
    mapping(address => uint256) public SellAllowance;

    /// events
    event OTCAllowed(address from, address to, uint256 amount);
    event ExchangeAllowed(address exchange, bool isAllowed);
    event SellAllowed(address exchange, uint256 amount);
    event TierSet(address member, uint256 tierRank);

    /// errors
    error OTCNotAllowed(
        address from,
        address to,
        uint256 allowedAmount,
        uint256 sendingAmount
    );
    error InvalidRole(bytes32 role, address sender);
    error MaxSupplyReached(uint256 currentSupply, uint256 newSupply);

    function initialize(address initialOwner) public initializer {
        _disableInitializers();
        __ERC20_init("DeepFuckinValue", "DFV");
        __AccessControl_init();
        __ERC20Permit_init("DFVV3");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function mint(address to, uint256 amount) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert MaxSupplyReached(totalSupply(), totalSupply() + amount);
        }
        _mint(to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // function to operate whitelists or penalties

    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 burnAmount = allowedFund(
            msg.sender,
            to,
            value,
            balanceOf(owner)
        );
        if (burnAmount > 0) {
            // burn token from owner
            _burn(msg.sender, burnAmount);
        }
        _transfer(owner, to, value - burnAmount);
        return true;
    }

    // DFV admin functions
    /// admin functions
    function setOTCAllowance(
        address from,
        address to,
        uint256 amount
    ) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
        OTCAllowance[from][to] = amount;
        emit OTCAllowed(from, to, amount);
    }

    function setExchangeWhitelist(address exchange, bool isAllowed) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
        ExchangeWhiteLists[exchange] = isAllowed;
        emit ExchangeAllowed(exchange, isAllowed);
    }

    function setSellAllowance(address exchange, uint256 amount) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
        SellAllowance[exchange] = amount;
        emit SellAllowed(exchange, amount);
    }

    function setTier(address member, uint tierRank) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
        if (tierRank == 0) {
            MemberTiers[member] = DFVTiers.Community;
        } else if (tierRank == 1) {
            MemberTiers[member] = DFVTiers.BlindBelievers;
        } else if (tierRank == 2) {
            MemberTiers[member] = DFVTiers.EthernalHodlers;
        } else if (tierRank == 3) {
            MemberTiers[member] = DFVTiers.DiamondHands;
        } else if (tierRank == 4) {
            MemberTiers[member] = DFVTiers.JustHodlers;
        } else {
            return;
        }
        emit TierSet(member, tierRank);
    }

    function allowedFund(
        address from,
        address to,
        uint256 value,
        uint256 balance
    ) public view returns (uint256 burnAmount) {
        // 1. check if to is from exchange whitelist
        if (ExchangeWhiteLists[to]) {
            // check sell amount
            uint256 allowed = SellAllowance[from];
            if (value > allowed) {
                // apply penalty
                DFVTiers tier = MemberTiers[from];
                return _applyPenalty(tier, balance);
            } else {
                return 0;
            }
        }
        // 2. check if from, to is OTC whitelisted
        else {
            // check if from is allowed to send token to all
            if (OTCAllowance[from][ALL] > 0) {
                // check if sending amount exceeds allowed amount, if not revert
                if (OTCAllowance[from][ALL] < value) {
                    revert OTCNotAllowed(
                        from,
                        to,
                        OTCAllowance[from][ALL],
                        value
                    );
                }
                return 0;
            } else {
                // check if sending amount exceeds allowed amount, if not revert
                if (OTCAllowance[from][to] < value) {
                    revert OTCNotAllowed(
                        from,
                        to,
                        OTCAllowance[from][to],
                        value
                    );
                }
                return 0;
            }
        }
    }

    /// @dev Function to store an address
    function storeAnAddress(address addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _storedAddress = addr;
    }

    /// @dev Function to retrieve the stored address
    function storedAddress() public view returns (address) {
        return _storedAddress;
    }

    function _applyPenalty(
        DFVTiers tier,
        uint256 balance
    ) internal pure returns (uint256 burnAmount) {
        if (tier == DFVTiers.BlindBelievers) {
            // burn 99% of the balance
            return (balance * 99) / 100;
        } else if (tier == DFVTiers.EthernalHodlers) {
            // burn 97% of the balance
            return (balance * 97) / 100;
        } else if (tier == DFVTiers.DiamondHands) {
            // burn 95% of the balance
            return (balance * 95) / 100;
        } else if (tier == DFVTiers.JustHodlers) {
            // burn 92% of the balance
            return (balance * 92) / 100;
        }
        // all else are from community airdrops
        else {
            // burn 99% of the balance
            return 0;
        }
    }
}
