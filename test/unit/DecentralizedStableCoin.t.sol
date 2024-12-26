// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2, Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "./DSCEngineTest.t.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinTest is Test {
    DeployDSC deployer;
    DSCEngine dscE;
    DecentralizedStableCoin dsc;

    address public owner;
    address NEW_OWNER = makeAddr("newOnwner");
    address MINTER = makeAddr("minter");

    function setUp() public {
        owner = address(this);

        deployer = new DeployDSC();
        (dsc, dscE,) = deployer.run();

        // dsc = new DecentralizedStableCoin();
    }

    function testOwnership() public view {
        console2.log("Actual DSC Owner:     ", dsc.owner());
        console2.log("Local owner variable: ", owner);
        console2.log("Test contract addr:   ", address(this));
    }

    //     function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
    //         if (_to == address(0)) {
    //             revert DecentralizedStableCoin__CannotMintToZeroAddress();
    //         }
    //         if (_amount <= 0) {
    //             revert DecentralizedStableCoin__CannotMintZero();
    //         }
    //         _mint(_to, _amount);
    //         return true;
    //     }
    // }

    function testCantMintToZeroAddress() public {
        vm.prank(dsc.owner());
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__CannotMintToZeroAddress.selector);
        dsc.mint(address(0), 1);
    }

    function testMustMintMoreThanZero() public {
        vm.prank(dsc.owner());
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__CannotMintZero.selector);
        dsc.mint(msg.sender, 0);
    }

    // function burn(uint256 _amount) public override onlyOwner {
    //     uint256 balance = balanceOf(msg.sender);
    //     if (_amount <= 0) {
    //         revert DecentralizedStableCoin__CannotBurnZeroTokens();
    //     }
    //     if (balance <= _amount) {
    //         revert DecentralizedStableCoin__BalanceLowerThanBurnAmount();
    //     }
    //     super.burn(_amount); // super uses burn function from parent contract;
    // }

    function testMustBurnMoreThanZero() public {}

    function testCantBurnMoreThanOwned() public {}
}
