// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2, Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";

contract DecentralizedStableCoinTest is Test {
    DeployDSC deployer;
    address MINTER = makeAddr("minter");

    function setUp() public {
        deployer = new DeployDSC();
    }

    function testMintWorks() external {}
}
