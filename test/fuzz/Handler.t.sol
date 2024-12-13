// handler narrows down the way we call functions, so we dont waste runs, like deposit collateral without approving the erc20
// handles the way we make calls to the contract, without calling functions randomly and wasting runs

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2, Test} from "forge-std/Test.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DSCEngine.sol";

contract Handler is Test {
    DSCEngine dscE;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    // these are the contracts we want the handler to handle calls to
    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dscE = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dscE.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // redeem collateral when you have collateral

    // we want to keep randomization, deposit random collaterals that are valid collaterals
    // example below is without guardrails and it will break, bc random addresses and 0 collateral goes against the requirements of this function
    //     function depositCollateral(address collateral, uint256 amountCollateral) public {
    //         dscE.depositCollateral(collateral, amountCollateral);
    //     }

    // Instead of depositing any collateral type, now we specify the type of collateral
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) external {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        dscE.depositCollateral(address(collateral), amountCollateral);
    }

    // Helper Functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc; // otherwise return wbtc
    }
}
