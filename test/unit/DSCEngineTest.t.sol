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

    event CollateralDeposited(address indexed user, address indexed tokenCollateral, uint256 indexed amountDeposited);

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (ethUSDPriceFeed, btcUSDPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_ERC20_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLenghtDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUSDPriceFeed);
        priceFeedAddresses.push(btcUSDPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__LengthMustBeEqualForTokenAddressesAndPriceFeedAddresses.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*//////////////////////////////////////////////////////////////
                              PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetTokenAmountFromUSD() public view {
        uint256 usdAmount = 100 ether;
        uint256 expectedWETH = 0.025 ether;
        uint256 actualWETH = dscEngine.getTokenAmountFromUSD(weth, usdAmount);
        assertEq(expectedWETH, actualWETH);
    }

    function testGetUSDValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUSDValue = 60000e18;
        uint256 actualUSDValue = dscEngine.getUSDValue(weth, ethAmount);
        assertEq(expectedUSDValue, actualUSDValue);
    }


    /*//////////////////////////////////////////////////////////////
                        DEPOSITCOLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralZero() public {
        vm.prank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__MustBeGreaterThanZero.selector);

        dscEngine.depositCollateral(weth, 0);
    }

    function testRevertsIfNotAllowedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("ran", "ran", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscEngine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testNonReentrantProtection() public {}

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = dscEngine.getAccountInformation(USER);

        uint256 expectedTotalDSCMinted = 0;
        uint256 expectedDepositAmount = dscEngine.getTokenAmountFromUSD(weth, collateralValueInUSD);

        assertEq(expectedTotalDSCMinted, totalDSCMinted);
        assertEq(expectedDepositAmount, AMOUNT_COLLATERAL);
    }

    function testCollateralDepositEmitsEvent() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectEmit(true, true, true, false, address(dscEngine));
        emit CollateralDeposited(USER, weth, AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    // HOW? line 166
    // function testRevertsIfFailedTransfer() public {
    //     vm.expectRevert(DSCEngine.DSCEngine__FailedTransfer.selector);
    // }
    
    /*//////////////////////////////////////////////////////////////
                 _REVERTIFHEALTHFACTORISVIOLATED TESTS
    //////////////////////////////////////////////////////////////*/

    //     function _revertIfHealthFactorIsViolated(address user) internal view {
    //     uint256 userHealthFactor = _healthFactor(user);
    //     if (userHealthFactor < MIN_HEALTH_FACTOR) {
    //         revert DSCEngine__ViolatedHealthFactor();
    //     }
    // }

    /*//////////////////////////////////////////////////////////////
                             MINTDSC TESTS
    //////////////////////////////////////////////////////////////*/

    //     function mintDSC(uint256 amountDSCToMint) public moreThanZero(amountDSCToMint) nonReentrant {
    //     s_mintedDSC[msg.sender] += amountDSCToMint;
    //     _revertIfHealthFactorIsViolated(msg.sender);
    //     bool minted = i_dsc.mint(msg.sender, amountDSCToMint);
    //     if (!minted) {
    //         revert DSCEngine__FailedMint();
    //     }
    // }

    /*//////////////////////////////////////////////////////////////
                   DEPOSITCOLLATERALANDMINTDSC TESTS
    //////////////////////////////////////////////////////////////*/

    // function depositCollateralAndMintDSC(
    //     address tokenCollateralAddress,
    //     uint256 amountCollateral,
    //     uint256 amountDSCToMint
    // ) external {
    //     depositCollateral(tokenCollateralAddress, amountCollateral);
    //     mintDSC(amountDSCToMint);
    // }
    
    // function testIfDepositAndMintWorks() public {
    //     vm.prank(USER);
    //     dscEngine.depositCollateralAndMintDSC(weth, 10, 1);
    // }

    /*//////////////////////////////////////////////////////////////
                        _REDEEMCOLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    //     function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to)
    //     private
    // {
    //     s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
    //     emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);

    //     bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
    //     if (!success) {
    //         revert DSCEngine__FailedTransfer();
    //     }
    // }

    /*//////////////////////////////////////////////////////////////
                 _REVERTIFHEALTHFACTORISVIOLATED TESTS
    //////////////////////////////////////////////////////////////*/

    //     function _revertIfHealthFactorIsViolated(address user) internal view {
    //     uint256 userHealthFactor = _healthFactor(user);
    //     if (userHealthFactor < MIN_HEALTH_FACTOR) {
    //         revert DSCEngine__ViolatedHealthFactor();
    //     }
    // }

    /*//////////////////////////////////////////////////////////////
                      REDEEMCOLLATERALFORDSC TESTS
    //////////////////////////////////////////////////////////////*/

    
//     function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
//         public
//         moreThanZero(amountCollateral)
//         nonReentrant
//     {

//         _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
//         _revertIfHealthFactorIsViolated(msg.sender);
//     }
// }
