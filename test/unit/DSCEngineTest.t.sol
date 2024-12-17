// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2, Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {MockFailedMint} from "../mocks/MockFailedMint.sol";
import {MockFailedTransfer} from "../mocks/MockFailedTransfer.sol";
import {MockFailedTransferFrom} from "../mocks/MockFailedTransferFrom.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscE;
    HelperConfig helperConfig;
    address ethUSDPriceFeed;
    address weth;
    address btcUSDPriceFeed;
    address wbtc;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant AMOUNT_TO_MINT = 100 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    event CollateralDeposited(address indexed user, address indexed tokenCollateral, uint256 indexed amountDeposited);

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscE, helperConfig) = deployer.run();
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
        uint256 actualWETH = dscE.getTokenAmountFromUSD(weth, usdAmount);
        assertEq(expectedWETH, actualWETH);
    }

    function testGetUSDValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUSDValue = 60000e18;
        uint256 actualUSDValue = dscE.getUSDValue(weth, ethAmount);
        assertEq(expectedUSDValue, actualUSDValue);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSITCOLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__MustBeGreaterThanZero.selector);

        dscE.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsIfNotAllowedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("ran", "ran", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscE.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testDepositCollateralIsNonReentrant() public {}

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);
        dscE.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralWithoutMinting() public depositCollateral {
        (uint256 actualDSCMinted,) = dscE.getAccountInformation(USER);
        // uint256 userBalance = dsc.balanceOf(USER);
        uint256 expectedDSCMinted = 0;

        assertEq(expectedDSCMinted, actualDSCMinted);
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = dscE.getAccountInformation(USER);

        uint256 expectedTotalDSCMinted = 0;
        uint256 expectedDepositAmount = dscE.getTokenAmountFromUSD(weth, collateralValueInUSD);

        assertEq(expectedTotalDSCMinted, totalDSCMinted);
        assertEq(expectedDepositAmount, AMOUNT_COLLATERAL);
    }

    function testCollateralDepositEmitsEvent() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);

        vm.expectEmit(true, true, true, false, address(dscE));
        emit CollateralDeposited(USER, weth, AMOUNT_COLLATERAL);

        dscE.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testRevertsIfFailedTransfer() public {
        address owner = msg.sender;
        vm.prank(owner);

        MockFailedTransferFrom mockDSC = new MockFailedTransferFrom();
        ERC20Mock(address(mockDSC)).mint(USER, STARTING_ERC20_BALANCE);
        tokenAddresses = [address(mockDSC)];
        priceFeedAddresses = [ethUSDPriceFeed];

        vm.prank(owner);
        DSCEngine mockDsce = new DSCEngine(tokenAddresses, priceFeedAddresses, address(mockDSC));

        vm.prank(USER);
        mockDSC.mint(USER, AMOUNT_COLLATERAL);

        // vm.prank(owner);
        // mockDSC.transferOwnership(address(mockDsce));

        vm.startPrank(USER);
        ERC20Mock(address(mockDSC)).approve(address(mockDsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__FailedTransfer.selector);
        mockDsce.depositCollateral(address(mockDSC), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

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

    function testRevertIfMintIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__MustBeGreaterThanZero.selector);

        dscE.mintDSC(0);
        vm.stopPrank();
    }

    function testMintDSCIsNonReentrant() public {}

    function testMintRevertIfHealFactorIsViolated() public {}

    function testRevertIfMintFails() public {
        address owner = msg.sender;
        vm.prank(owner);

        MockFailedMint mockDSC = new MockFailedMint();
        ERC20Mock(address(mockDSC)).mint(USER, STARTING_ERC20_BALANCE);
        tokenAddresses = [weth];
        priceFeedAddresses = [ethUSDPriceFeed];

        vm.prank(owner);
        DSCEngine mockDSCE = new DSCEngine(tokenAddresses, priceFeedAddresses, address(mockDSC));
        mockDSC.transferOwnership(address(mockDSCE));

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(mockDSCE), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__FailedMint.selector);
        // mockDSCE.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);
        mockDSCE.depositCollateral(weth, AMOUNT_COLLATERAL);
        mockDSCE.mintDSC(AMOUNT_TO_MINT);
        vm.stopPrank();
    }

    function testCanMintDSC() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);
        dscE.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscE.mintDSC(AMOUNT_TO_MINT);
        vm.stopPrank();
    }

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
}
