// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract DAO is AccessControl {
    /// address value to represent all addresses in whitelist
    address constant ALL = address(1);

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
    mapping(address => mapping(address => uint256)) OTCWhitelists;

    /// mapping for exchange whitelisting
    mapping(address => bool) ExchangeWhiteLists;

    /// mapping to register tiers of each member
    mapping(address => DFVTiers) MemberTiers;

    /// address for Allowed Liquidation Platforms
    mapping(address => uint256) SellAllowance;

    /// events
    event OTCAllowed(address from, address to, uint256 amount);
    event ExchangeAllowed(address exchange, bool isAllowed);
    event SellAllowed(address exchange, uint256 amount);
    event TierSet(address member, uint256 tierRank);

    /// errors
    error OTCNotAllowed(address from, address to, uint256 allowedAmount, uint256 sendingAmount);
    error InvalidRole(bytes32 role, address sender);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// admin functions
    function setOTCWhitelist(
        address from,
        address to,
        uint256 amount
    ) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
        OTCWhitelists[from][to] = amount;
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
        if(tierRank == 0) {
            MemberTiers[member] = DFVTiers.Community;
        }
        else if (tierRank == 1) {
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

    function isOk(
        address from,
        address to,
        uint256 value,
        uint256 balance
    ) external view returns (uint256 burnAmount) {
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
            if(OTCWhitelists[from][ALL] > 0) {
                // check if sending amount exceeds allowed amount, if not revert
                if (OTCWhitelists[from][ALL] < value) {
                    revert OTCNotAllowed(from, to, OTCWhitelists[from][ALL], value);
                }
                return 0;
            }
            else {
                // check if sending amount exceeds allowed amount, if not revert
                if (OTCWhitelists[from][to] < value) {
                    revert OTCNotAllowed(from, to, OTCWhitelists[from][to], value);
                }
                return 0;
            }
        }
    }

    function _applyPenalty(
        DFVTiers tier,
        uint256 balance
    ) internal pure returns (uint256 burnAmount) {
        if (tier == DFVTiers.BlindBelievers) {
            // burn 99% of the balance
            return balance * 99 / 100;
        } else if (tier == DFVTiers.EthernalHodlers) {
            // burn 97% of the balance
            return balance * 97 / 100;
        } else if (tier == DFVTiers.DiamondHands) {
            // burn 95% of the balance
            return balance * 95 / 100;
        } else if (tier == DFVTiers.JustHodlers) {
            // burn 92% of the balance
            return balance * 92 / 100;
        }
        // all else are from community airdrops
        else {
            // burn 99% of the balance
            return 0;
        }
    }
}
