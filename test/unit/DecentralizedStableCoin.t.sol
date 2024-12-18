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

    function testMintWorks() external {}

    function testTransferOwnershisp() external {}

    function testTransferOwnership() public view {
        // dsc.transferOwnership(NEW_OWNER);

        // assertEq(dsc.owner(), owner);
        assertEq(dsc.owner(), address(dscE));
        // assertEq(dsc.owner(), NEW_OWNER);
    }
}
