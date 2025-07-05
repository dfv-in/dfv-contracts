// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/DFVV1.sol";
import "../src/DFVV2.sol";
import "../src/DFVV4.sol";
import "../src/DFVPlain.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

interface ITransparentUpgradeableProxy {
    function changeAdmin(address newAdmin) external;

    function upgradeTo(address newImplementation) external;

    function admin() external view returns (address);
}

import {Script, console} from "forge-std/Script.sol";

contract Deployer is Script {
    function _setDeployer() internal {
        uint256 deployerPrivateKey = vm.envUint("DFV_DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
    }
}

contract SetTier is Deployer {
    function run() public {
        _setDeployer();

        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;

        DFVV4(address(proxy)).setTier(
            address(0x3068722291E90e7251D37b9b5Bc1E3D303885bb7),
            1
        );

    }
}

contract SetBB is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;
        DFVV4(address(proxy)).setTier(
            address(0xA3785AFC932826BffA229fF5cf187BE3786a77a6),
            0
        );
    }
}

contract GetTier is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;
        DFVV4(address(proxy)).memberTiers(address(0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448));
    }
}

contract SetSellAllowance is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;
        DFVV4(address(proxy)).setSellAllowance(address(0xA3785AFC932826BffA229fF5cf187BE3786a77a6), 100*1e18);
    }
}

contract SetExchangeWhitelist is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x3908b45Ce7395dBa8A76bFbc16ee99e85b9e88A3;
        DFVV4(address(proxy)).setExchangeWhitelist(
            address(0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af),
            true
        );
    }
}

contract GetSellAllowance is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x3908b45Ce7395dBa8A76bFbc16ee99e85b9e88A3;
        DFVV4(address(proxy)).sellAllowance(address(0xA3785AFC932826BffA229fF5cf187BE3786a77a6));
    }
}

contract GetAllowedFund is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x3908b45Ce7395dBa8A76bFbc16ee99e85b9e88A3;
        (uint256 a, bool b) = DFVV4(address(proxy)).allowedFund(address(0x3068722291E90e7251D37b9b5Bc1E3D303885bb7), address(0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af), 1000000000000000000, 1000000000000000000);
        console.log(a);
        console.log(b);
    }
}

contract MintDFVToMultisigs is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;
        // Add minting wallets with amounts
        
        // Blind Believers
        DFV(address(proxy)).mint(
            address(0xF5D46bDe4dC092aa637A7A04212Acb7aB030fa32),
            20_826_000_000 * 10 ** 18
        ); 
               

        uint256 higherGasPrice = 10 gwei; // Increase this value

        vm.txGasPrice(higherGasPrice);
        // Eternal Hodlers
        DFV(address(proxy)).mint(
            address(0x311a14194664B0B4c58433C33626dF0b32F14372),
            13_884_000_000 * 10 ** 18
        );
        
        // Diamond Hands
        DFV(address(proxy)).mint(
            address(0x214eB48EB73BB0d79BAB2B4fD4C406A6547cba14),
            6_942_000_000 * 10 ** 18
        );
        // Just Hodlers
        DFV(address(proxy)).mint(
            address(0xb0B43A98Af1C88c755673A81913707638D261392),
            13_884_000_000 * 10 ** 18
        );
        // Community Airdrop
        DFV(address(proxy)).mint(
            address(0xCa628438886dcf4854cE6C6Db94e4B9fB47EE07b),
            13_884_000_000 * 10 ** 18
        );

        // Uniswap Liquidity
        DFV(address(proxy)).mint(
            address(0xdF80e38699bb963a91c5F04F83378A597995932a),
            67_337_400_000 * 10 ** 18
        );
        // Team
        DFV(address(proxy)).mint(
            address(0x7c837A5b15439725AdA552b7e36d642B60F119a1),
            2_082_600_000 * 10 ** 18
        );
        vm.stopBroadcast();
    }
}

contract SetTierOnBlindBelievers is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;

        // Blind Believers
        DFVV4Plain dfvv4 = DFVV4Plain(address(proxy));
        /*
        dfvv4.setTier(address(0xF5D46bDe4dC092aa637A7A04212Acb7aB030fa32), 1);
        dfvv4.setTier(address(0x5279d4F55096a427b9121c6D642395a4f0Cd04a4), 1);
        dfvv4.setTier(address(0x250e6E64276D5e9a1cA0B6C5B2B11c5139CD1Fc7), 1);
        dfvv4.setTier(address(0xA68D88522E06c226f1a3B9D04A86d4CdaCE666fE), 1);
        dfvv4.setTier(address(0x4Bd6300fc61Fa86b3d98A73CeE89bb54140b45e3), 1);
        dfvv4.setTier(address(0x7b1D81Ba131F551DA2f70f7c2363b45DbD451d83), 1);
        dfvv4.setTier(address(0xac783aEA23528862E2e4E7c9F8Bbc65bfAFe33B3), 1);
        dfvv4.setTier(address(0xdf99908D22D2F18B50E15D962E77666da4A04717), 1); nonce 70
        
        dfvv4.setTier(address(0x3e46e4e203Bc6Aa3b3c6a2993C3cCEDeAF177f61), 1);
        dfvv4.setTier(address(0xD94A8E20CbDD95D050f1356259E18C4Dd10f661A), 1);
        dfvv4.setTier(address(0xe079E4AfB3FDd8F02B29C7A333D526b9c4C94B23), 1);
        dfvv4.setTier(address(0x0aF20A5C0FFb89dAD55076309925014EaeBb5568), 1);
        dfvv4.setTier(address(0x015FC9C8B333Aeb7A91Fd966bbFE6FF9A0ef8331), 1); nonce 75
        
        dfvv4.setTier(address(0x049E035Fb280b1df29e1c9BaE586F8E2E03311E1), 1);
        dfvv4.setTier(address(0xE63cE53A4Ed7B5180311143AA3FE9131b4E0AB88), 1);
        dfvv4.setTier(address(0xBD34Dc3FBb661612AAbCADaf758Caa6E22787297), 1);
        dfvv4.setTier(address(0x60C7d0B2cD22e9D20BE93f9EFFBabF15fd599936), 1); nonce 79
        dfvv4.setTier(address(0x6068efCd7DEdDED2A8444cbb218ffE71fa022D08), 1);
        dfvv4.setTier(address(0xF52eB9b90C0CE6B037381aEa62BfA7A1B5519D31), 1);
        dfvv4.setTier(address(0x128c21DFE98E7478e3cc6513AEF959BBD266Ed0F), 1); nonce 85
        
        dfvv4.setTier(address(0x255252421d42949843e6bdB40065d39c110c8191), 1);
        dfvv4.setTier(address(0xC5DCb0A22551FbA93e260028813F0eef25bFfeA6), 1);
        dfvv4.setTier(address(0xEaF85B68ce6AC308946580b907C4f84d0Abb07ee), 1);
        dfvv4.setTier(address(0x63d97917852e12F1591A39D20ba8a2547169B298), 1); nonce 89
        
        dfvv4.setTier(address(0x8e80410Ae2c5a394D1a81364fB932dF86Eb4992d), 1);
        dfvv4.setTier(address(0x88C3f21CeCd5846D55d9A82f5A40FBd88E2fC5a5), 1);
        dfvv4.setTier(address(0x49e5c7645EaF21A531D933dE365ABDB01Ba3A2f6), 1);
        dfvv4.setTier(address(0xACce9487EcF6F32325ad612df0D1f1288653905A), 1);
        dfvv4.setTier(address(0x84240C190FB0761527bA3A490BFe2e002413CDe4), 1);
        dfvv4.setTier(address(0xeE6343ED1b521440A3c952FCAAA1E487a0403DbC), 1); nonce 95
        
        dfvv4.setTier(address(0x147EC80822AFD4C6bC13aC116Ce3ae886099AB47), 1); nonce 96 
        */
        vm.stopBroadcast();
    }
}

contract SetAdmin is Deployer {
    function run() public {
        _setDeployer();

        DFVV4 implementation = DFVV4(
            0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19
        );
        implementation.grantRole(
            0x00,
            0x71B83d53FED1154901C58B8A7ff9569Ac1D45c25
        );
    }
}

contract DeployDFVProxy is Deployer {
    function run() public {
        _setDeployer();
        // Deploy the ERC-20 token
        DFVV4Plain implementation = new DFVV4Plain();

        // Log the token address
        console.log("Token Implementation Address:", address(implementation));

        // Deploy the proxy contract with the implementation address and initializer
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448),
            abi.encodeCall(
                implementation.initialize,
                0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448
            )
        );

        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));

        // Add minting wallets with amounts
        // Blind Believers
        DFV(address(proxy)).mint(
            address(0xF5D46bDe4dC092aa637A7A04212Acb7aB030fa32),
            20_826_000_000 * 10 ** 18
        );
    
        // Eternal Hodlers
        DFV(address(proxy)).mint(
            address(0x311a14194664B0B4c58433C33626dF0b32F14372),
            13_884_000_000 * 10 ** 18
        );
        // Diamond Hands
        DFV(address(proxy)).mint(
            address(0x214eB48EB73BB0d79BAB2B4fD4C406A6547cba14),
            6_942_000_000 * 10 ** 18
        );
        // Just Hodlers
        DFV(address(proxy)).mint(
            address(0xb0B43A98Af1C88c755673A81913707638D261392),
            13_884_000_000 * 10 ** 18
        );
        // Community Airdrop
        DFV(address(proxy)).mint(
            address(0xCa628438886dcf4854cE6C6Db94e4B9fB47EE07b),
            13_884_000_000 * 10 ** 18
        );

        // Uniswap Liquidity
        DFV(address(proxy)).mint(
            address(0xdF80e38699bb963a91c5F04F83378A597995932a),
            67_337_400_000 * 10 ** 18
        );
        // Team
        DFV(address(proxy)).mint(
            address(0x7c837A5b15439725AdA552b7e36d642B60F119a1),
            2_082_600_000 * 10 ** 18
        );

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract UpgradeDFVProxy is Deployer {
    address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;

    function run() public {
        _setDeployer();

        // Log the token address
        //console.log("Token Implementation Address:", address(implementation));

        Upgrades.upgradeProxy(
            address(proxy),
            "DFVV4Init.sol:DFVV4Init",
            "",
            0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448
        );

        /*
        Upgrades.upgradeProxy(
            address(proxy),
            "DFVV4.sol:DFVV4",
            "",
            0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448
        );
        */

       
        // Stop broadcasting calls from our address
        vm.stopBroadcast();
       
    }
}

contract MintTestDFV is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;
        DFVV4(address(proxy)).mint(address(0x84Dc6f8A9CB1E042A0E5A3b4a809c90BEB9d3448), 1000000000000000000);
    }
}

contract AddPresale is Deployer {
    address proxy = 0xA0D465b1e213Ea5C4E099F998C5cACC68328690D;

    function run() public {
        _setDeployer();

        // prompt for the presale recipient address
        address presaleRecipient = vm.promptAddress(
            "Enter the presale recipient address"
        );

        // prompt for the presale amount
        uint256 presaleAmount = vm.promptUint(
            "Enter the presale amount without 18 decimals"
        );

        DFVV4(address(proxy)).mint(
            address(presaleRecipient),
            presaleAmount * 1e18
        );

        // set the presale tier
        uint256 presaleTier = vm.promptUint(
            "Enter the presale tier (0, 1, 2, 3, 4, or 5)"
        );
        DFVV4(address(proxy)).setTier(presaleRecipient, presaleTier);

        // set the allowed sell presale amount

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract GetTier2 is Deployer {
    address proxy = 0xA0D465b1e213Ea5C4E099F998C5cACC68328690D;

    function run() public {
        _setDeployer();

        // prompt for the presale recipient address
        address presaleRecipient = vm.promptAddress(
            "Enter the presale recipient address"
        );

        DFVV4(address(proxy)).memberTiers(presaleRecipient);
        vm.prank(presaleRecipient);
        DFVV4(address(proxy)).transfer(
            0xA0D465b1e213Ea5C4E099F998C5cACC68328690D,
            10
        );
        vm.stopBroadcast();
    }
}

contract SetSaleAllowance is Deployer {
    address proxy = 0xA0D465b1e213Ea5C4E099F998C5cACC68328690D;

    function run() public {
        _setDeployer();

        // prompt for the presale recipient address
        address allowanceAccount = vm.promptAddress(
            "Enter the address to set the sale allowance for"
        );

        // set the presale tier
        uint256 allowance = vm.promptUint(
            "Enter the allowance DFV token amount in 18 decimals"
        );
        DFVV4(address(proxy)).setSellAllowance(allowanceAccount, allowance);

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}

contract SetTierBatch is Deployer {
    function run() public {
        _setDeployer();
        address proxy = 0x06B5c84C6fB16B9C043cCbb5399Ac267f38e9E19;

        address[] memory addresses = new address[](30);
        addresses[0] = 0x5279d4F55096a427b9121c6D642395a4f0Cd04a4;
        addresses[1] = 0x250e6E64276D5e9a1cA0B6C5B2B11c5139CD1Fc7;
        addresses[2] = 0xA68D88522E06c226f1a3B9D04A86d4CdaCE666fE;
        addresses[3] = 0x4Bd6300fc61Fa86b3d98A73CeE89bb54140b45e3;
        addresses[4] = 0x7b1D81Ba131F551DA2f70f7c2363b45DbD451d83;
        addresses[5] = 0xac783aEA23528862E2e4E7c9F8Bbc65bfAFe33B3;
        addresses[6] = 0xdf99908D22D2F18B50E15D962E77666da4A04717;
        addresses[7] = 0x3e46e4e203Bc6Aa3b3c6a2993C3cCEDeAF177f61;
        addresses[8] = 0xD94A8E20CbDD95D050f1356259E18C4Dd10f661A;
        addresses[9] = 0xe079E4AfB3FDd8F02B29C7A333D526b9c4C94B23;
        addresses[10] = 0x0aF20A5C0FFb89dAD55076309925014EaeBb5568;
        addresses[11] = 0x015FC9C8B333Aeb7A91Fd966bbFE6FF9A0ef8331;
        addresses[12] = 0x049E035Fb280b1df29e1c9BaE586F8E2E03311E1;
        addresses[13] = 0xE63cE53A4Ed7B5180311143AA3FE9131b4E0AB88;
        addresses[14] = 0xBD34Dc3FBb661612AAbCADaf758Caa6E22787297;
        addresses[15] = 0x60C7d0B2cD22e9D20BE93f9EFFBabF15fd599936;
        addresses[16] = 0x6068efCd7DEdDED2A8444cbb218ffE71fa022D08;
        addresses[17] = 0xF52eB9b90C0CE6B037381aEa62BfA7A1B5519D31;
        addresses[18] = 0x128c21DFE98E7478e3cc6513AEF959BBD266Ed0F;
        addresses[19] = 0x255252421d42949843e6bdB40065d39c110c8191;
        addresses[20] = 0xC5DCb0A22551FbA93e260028813F0eef25bFfeA6;
        addresses[21] = 0xEaF85B68ce6AC308946580b907C4f84d0Abb07ee;
        addresses[22] = 0x63d97917852e12F1591A39D20ba8a2547169B298;
        addresses[23] = 0x8e80410Ae2c5a394D1a81364fB932dF86Eb4992d;
        addresses[24] = 0x3068722291E90e7251D37b9b5Bc1E3D303885bb7;
        addresses[25] = 0x49e5c7645EaF21A531D933dE365ABDB01Ba3A2f6;
        addresses[26] = 0xACce9487EcF6F32325ad612df0D1f1288653905A;
        addresses[27] = 0x84240C190FB0761527bA3A490BFe2e002413CDe4;
        addresses[28] = 0xeE6343ED1b521440A3c952FCAAA1E487a0403DbC;
        addresses[29] = 0x147EC80822AFD4C6bC13aC116Ce3ae886099AB47;

        DFVV4Plain dfvv4 = DFVV4Plain(address(proxy));
        
        for (uint256 i = 0; i < addresses.length; i++) {
            // check if the tier is already set
            if (dfvv4.memberTiers(addresses[i]) == DFVV4Plain.DFVTiers.Community) {
                dfvv4.setTier(addresses[i], 1);
            }
        }

        vm.stopBroadcast();
    }
}
