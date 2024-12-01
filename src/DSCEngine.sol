// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

/**
 * @title DSCEngine
 * @author yawarasuuna
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == USD 1 peg.
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI as if it had no governance, no fees, and only backed by WETH and WBTC.
 *
 * DSC System should always be overcollaterized. The dollar backed value of all DSC should NOT be, at any point, greater or equal than the sum of all collateral in the protocol.
 *
 * @notice This contract is the core of DSC System. It handles all the logic for minting and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is very loosely based on the MakerDao DSS (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error DSCEngine__MustToBeGreaterThanZero();
    error DSCEngine__LengthMustBeEqualForTokenAddressesAndPriceFeedAddresses();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // mapping(address => bool) private s_tokenToAllowed; // if we were to do it manually, but we'll use price feeds
    mapping(address token => address priceFeed) private s_priceFeed; // new convention, used to be s_tokenToPriceFeed
    mapping(address depositors => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DecentralizedStableCoin private immutable i_dsc;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event CollateralDeposited(address indexed user, address indexed tokenCollateral, uint256 indexed mountDeposited);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__MustToBeGreaterThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeed[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        // USD Price Feed
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__LengthMustBeEqualForTokenAddressesAndPriceFeedAddresses();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeed[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function depositCollateralAndMintDSC(address tokenCollateralAddress, uint256 amount)
        external
        moreThanZero(amount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {}

    /*
     * @notice follows CEI
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        // updates state, so we should emit an event
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool sucess = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!sucess) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDSC(uint256 amount) external moreThanZero(amount) nonReentrant {}

    function redeemCollateral(address tokenCollateralAddress, uint256 amount)
        external
        moreThanZero(amount)
        nonReentrant
    {}

    function mintDSC(uint256 amount) external moreThanZero(amount) nonReentrant {}

    function burnDSC(uint256 amount) external moreThanZero(amount) {}

    function liquidate(uint256 amount) external moreThanZero(amount) {}

    function getHealthFactor() external view {}
}
