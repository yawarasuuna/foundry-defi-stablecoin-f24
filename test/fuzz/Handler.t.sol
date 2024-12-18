// handler narrows down the way we call functions, so we dont waste runs, like deposit collateral without approving the erc20
// handles the way we make calls to the contract, without calling functions randomly and wasting runs

// continueOnRevert: quicker looser test
// failOnRevert: every single transaction you run on your invariant test, it will pass

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

    uint256 public timesMintIsCalled; // ghost variable
    address[] public usersWithCollateralDeposited;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max; // if uint256.max, it would revert due to overflow of max uin256+1

    // these are the contracts we want the handler to handle calls to
    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dscE = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dscE.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    function mintDSC(uint256 amount, uint256 addressSeed) public {
        // amount = bound(amount, 1, MAX_DEPOSIT_SIZE);
        if (usersWithCollateralDeposited.length == 0) {
            return;
        }
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = dscE.getAccountInformation(sender);

        int256 maxDSCToMint = (int256(collateralValueInUSD) / 2) - int256(totalDSCMinted);
        if (maxDSCToMint < 0) {
            return;
        }
        amount = bound(amount, 0, uint256(maxDSCToMint));
        if (amount == 0) {
            return;
        }
        vm.startPrank(sender);
        dscE.mintDSC(amount);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    // redeem collateral when you have collateral

    // we want to keep randomization, deposit random collaterals that are valid collaterals
    // example below is without guardrails and it will break, bc random addresses and 0 collateral goes against the requirements of this function
    //     function depositCollateral(address collateral, uint256 amountCollateral) public {
    //         dscE.depositCollateral(collateral, amountCollateral);
    //     }

    // Instead of depositing any collateral type, now we specify the type of collateral
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dscE), amountCollateral);
        dscE.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxAmountCollateralToRedeem = dscE.getCollateralBalanceOfUser(address(collateral), msg.sender);
        amountCollateral = bound(amountCollateral, 0, maxAmountCollateralToRedeem);
        if (amountCollateral == 0) {
            // vm.assume // try it out
            return; // and dont call function redeemCollateral
        }

        dscE.redeemCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    // Helper Functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc; // otherwise return wbtc
    }
}
