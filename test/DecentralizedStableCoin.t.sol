// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2, Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DeployDecentralizedStableCoin} from "../script/DeployDecentralizedStableCoin.s.sol";

contract DecentralizedStableCoinTest is Test {
    DeployDecentralizedStableCoin deployer;
    address MINTER = makeAddr("minter");

    function setUp() public {
        deployer = new DeployDecentralizedStableCoin();
    }

    function testMintWorks() external {}
}
