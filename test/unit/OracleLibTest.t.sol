// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2, Test} from "forge-std/Test.sol";
import {AggregatorV3Interface, OracleLib} from "../../src/libraries/OracleLib.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract OrableLibTest is Test {
    using OracleLib for AggregatorV3Interface;

    MockV3Aggregator public aggregator;

    uint8 private constant DECIMALS = 8;
    int256 private constant INITIAL_PRICE = 4000 ether;

    function setUp() public {
        aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    }

    function testGetTimeout() public pure {
        uint256 expectedTimeout = 3 hours;
        console2.log(expectedTimeout);
        console2.log(OracleLib.getTimeout());
        assertEq(expectedTimeout, OracleLib.getTimeout());
    }

    function testOraclePriceRevertsWhenStale() public {
        vm.warp(block.timestamp + 3 hours + 1 seconds);
        vm.roll(block.number + 1);

        vm.expectRevert(OracleLib.OracleLib__StalePrice.selector);
        OracleLib.staleCheckLatestRoundData(AggregatorV3Interface(address(aggregator)));
        // AggregatorV3Interface(address(aggregator)).staleCheckLatestRoundData(); // same?
    }

    function testOraclePriceRevertsWhenBadDataIsSentInARound() public {
        uint80 _roundId = 0;
        int256 _answer = 0;
        uint256 _timestamp = 0;
        uint256 _startedAt = 0;
        aggregator.updateRoundData(_roundId, _answer, _timestamp, _startedAt);

        vm.expectRevert(OracleLib.OracleLib__StalePrice.selector);
        AggregatorV3Interface(address(aggregator)).staleCheckLatestRoundData();
    }
}
