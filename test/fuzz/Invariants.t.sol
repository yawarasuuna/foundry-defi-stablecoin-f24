// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {console2, Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DSCEngine.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dscE;
    DecentralizedStableCoin dsc;
    HelperConfig helperConfig;
    Handler handler;

    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscE, helperConfig) = deployer.run();
        (,, weth, wbtc,) = helperConfig.activeNetworkConfig();
        // targetContract(address(dscE));
        handler = new Handler(dscE, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() external view {
        uint256 totalDSCSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscE));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscE));

        uint256 valueWeth = dscE.getUSDValue(weth, totalWethDeposited);
        uint256 valueWbtc = dscE.getUSDValue(wbtc, totalWbtcDeposited);

        assert(valueWeth + valueWbtc >= totalDSCSupply);
    }

    // 12m15
}
