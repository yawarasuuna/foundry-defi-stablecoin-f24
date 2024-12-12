// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// invariants properties that hte system should always hold

// what are our invariants?

// 1. supply of dsc should be less than total value of collateral
// 2. getter view functions should never revert <- evergreen invariant

// fail_on_revert = false
// pro
// good for sanity check
// quickly write open test functions and minimal handler functions that arent perfect
// con
// hard to make sure all calls made are making sense 

import {console2, Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DSCEngine.sol";

contract OpenInvariantsTests is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dscE;
    DecentralizedStableCoin dsc;
    HelperConfig helperConfig;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscE, helperConfig) = deployer.run();
        (,, weth, wbtc,) = helperConfig.activeNetworkConfig();
        targetContract(address(dscE));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscE)); // total amount of weth deposited/set to contract dscE
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscE));

        uint256 wethValue = dscE.getUSDValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscE.getUSDValue(wbtc, totalWbtcDeposited);

        console2.log("weth value: ", wethValue);
        console2.log("wbtc value: ", wbtcValue);
        console2.log("total supply: ", totalSupply);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
