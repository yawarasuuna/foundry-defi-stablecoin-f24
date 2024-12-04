// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2, Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    address ethUSDPriceFeed;
    address weth;
    address btcUSDPriceFeed;
    address wbtc;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (ethUSDPriceFeed, btcUSDPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                              PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetUSDValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUSDValue = 60000e18;
        uint256 actualUSDValue = dscEngine.getUSDValue(weth, ethAmount);
        assertEq(expectedUSDValue, actualUSDValue);
    }

    /*//////////////////////////////////////////////////////////////
                   DEPOSITCOLLATERALANDMINTDSC TESTS
    //////////////////////////////////////////////////////////////*/

    // function testIfDepositAndMintWorks() public {
    //     vm.prank(USER);
    //     dscEngine.depositCollateralAndMintDSC(weth, 10, 1);
    // }

    /*//////////////////////////////////////////////////////////////
                        DEPOSITCOLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralZero() public {
        vm.prank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__MustBeGreaterThanZero.selector);

        dscEngine.depositCollateral(weth, 0);
    }

    function testRevertsIfNotAllowedToken() public {}

    function testRevertsIfFailedTransfer() public {}
}
