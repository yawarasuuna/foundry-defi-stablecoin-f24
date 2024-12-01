// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DeployDecentralizedStableCoin is Script {
    DecentralizedStableCoin decentralizedStableCoin;

    function run() external {
        vm.startBroadcast();
        decentralizedStableCoin = new DecentralizedStableCoin();
        vm.stopBroadcast();
    }
}
