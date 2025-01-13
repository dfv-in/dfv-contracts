// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

/// @custom:oz-upgrades-from DFV
contract DFVV4 is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20CappedUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    /// address value to represent all addresses in whitelist
    address constant ALL_ADDRESSES = address(1);
    uint256 constant INFINITY = type(uint256).max;
    /// total supply of the token
    uint256 private constant MAX_SUPPLY = 138_840_000_000 * 10 ** 18; // 138.84 billion tokens with 18 decimals

    /// enum for identifying tiers
    enum DFVTiers {
        // first value in Enum is the default value
        Community,
        BlindBelievers,
        EthernalHodlers,
        DiamondHands,
        JustHodlers,
        Airdrops
    }

    /// mapping for whitelisting
    mapping(address => mapping(address => uint256)) public otcAllowance;

    /// mapping for exchange whitelisting
    mapping(address => bool) public exchangeWhiteLists;

    /// mapping to register tiers of each member
    mapping(address => DFVTiers) public memberTiers;

    /// address for Allowed Liquidation Platforms
    mapping(address => uint256) public sellAllowance;

    /// events
    event OTCAllowed(address from, address to, uint256 amount);
    event ExchangeAllowed(address exchange, bool isAllowed);
    event SellAllowed(address exchange, uint256 amount);
    event TierSet(address member, uint256 tierRank);
    event ApplyPenalty(address from, uint256 amount);

    /// errors
    error OTCNotAllowed(
        address from,
        address to,
        uint256 allowedAmount,
        uint256 sendingAmount
    );

    function initialize(address initialOwner) public reinitializer(4) {
        __ERC20_init("DeepFuckinValue", "DFV");
        __AccessControl_init();
        __ERC20Permit_init("DFVV4");
        __ERC20Capped_init(MAX_SUPPLY);
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function mint(
        address to,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
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
        (uint256 burnAmount, bool isOTC) = allowedFund(
            owner,
            to,
            value,
            balanceOf(owner)
        );
        if (isOTC) {
            // reduce OTC allowance
            otcAllowance[owner][to] -= burnAmount;
        } else {
            // in case of just buying DFV from exchange, increase sell allowance
            if (exchangeWhiteLists[owner]) {
                sellAllowance[to] += value;
            } else {
                sellAllowance[owner] = _subtractWithoutUnderflow(
                    sellAllowance[owner],
                    burnAmount
                );
            }
            if (burnAmount > 0) {
                // burn token from owner
                _burn(owner, burnAmount);
                emit ApplyPenalty(owner, burnAmount);
            }
        }
        uint sending = isOTC
            ? value
            : _subtractWithoutUnderflow(value, burnAmount);
        _transfer(owner, to, sending);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        // check allowance
        require(
            value <= allowance(from, to),
            "ERC20: transfer amount exceeds allowance"
        );
        (uint256 burnAmount, bool isOTC) = allowedFund(
            from,
            to,
            value,
            balanceOf(from)
        );
        _spendAllowance(from, to, value);
        if (isOTC) {
            // reduce OTC allowance
            otcAllowance[from][to] -= burnAmount;
        } else {
            // in case of buying DFV from exchange, increase sell allowance
            if (exchangeWhiteLists[from]) {
                sellAllowance[to] += value;
            } else {
                sellAllowance[from] = _subtractWithoutUnderflow(
                    sellAllowance[from],
                    value
                );
            }
            if (burnAmount > 0) {
                // burn token from owner
                _burn(from, burnAmount);
                emit ApplyPenalty(from, burnAmount);
            }
        }
        uint sending = isOTC
            ? value
            : _subtractWithoutUnderflow(value, burnAmount);
        _transfer(from, to, sending);
        return true;
    }

    // DFV admin functions
    /// admin functions
    function setOTCAllowance(
        address from,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        otcAllowance[from][to] = amount;
        emit OTCAllowed(from, to, amount);
    }

    function setExchangeWhitelist(
        address exchange,
        bool isExchange
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        exchangeWhiteLists[exchange] = isExchange;
        emit ExchangeAllowed(exchange, isExchange);
    }

    function setSellAllowance(
        address exchange,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sellAllowance[exchange] = amount;
        emit SellAllowed(exchange, amount);
    }

    function setTier(
        address member,
        uint tierRank
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tierRank == 0) {
            memberTiers[member] = DFVTiers.Community;
        } else if (tierRank == 1) {
            memberTiers[member] = DFVTiers.BlindBelievers;
        } else if (tierRank == 2) {
            memberTiers[member] = DFVTiers.EthernalHodlers;
        } else if (tierRank == 3) {
            memberTiers[member] = DFVTiers.DiamondHands;
        } else if (tierRank == 4) {
            memberTiers[member] = DFVTiers.JustHodlers;
        } else if (tierRank == 5) {
            memberTiers[member] = DFVTiers.Airdrops;
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
    ) public view returns (uint256 burnAmount, bool isOTC) {
        // 1. check if to is from exchange whitelist
        if (exchangeWhiteLists[to]) {
            // check sell amount
            uint256 allowed = sellAllowance[from];
            if (value > allowed) {
                // apply penalty
                DFVTiers tier = memberTiers[from];
                return (_applyPenalty(tier, balance), false);
            } else {
                return (0, false);
            }
        }
        // 2. check if from, to is OTC whitelisted
        else {
            DFVTiers fromTier = memberTiers[from];
            if (fromTier == DFVTiers.Community) {
                return (0, true);
            }
            // check if from is allowed to send token to all
            if (otcAllowance[from][ALL_ADDRESSES] > 0) {
                if (otcAllowance[from][ALL_ADDRESSES] == INFINITY) {
                    return (0, true);
                }
                // check if sending amount exceeds allowed amount, if not revert
                else if (otcAllowance[from][ALL_ADDRESSES] < value) {
                    revert OTCNotAllowed(
                        from,
                        to,
                        otcAllowance[from][ALL_ADDRESSES],
                        value
                    );
                }
                return (value, true);
            } else {
                if (otcAllowance[from][to] == INFINITY) {
                    return (0, true);
                }
                // check if sending amount exceeds allowed amount, if not revert
                else if (otcAllowance[from][to] < value) {
                    revert OTCNotAllowed(
                        from,
                        to,
                        otcAllowance[from][to],
                        value
                    );
                }
                return (value, true);
            }
        }
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
        } else if (tier == DFVTiers.Airdrops) {
            // burn 99% of the balance
            return (balance * 99) / 100;
        }
        // all else are from community airdrops
        else {
            // no penalty
            return 0;
        }
    }

    function _subtractWithoutUnderflow(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20CappedUpgradeable, ERC20Upgradeable) {
        ERC20CappedUpgradeable._update(from, to, value);
    }
}
