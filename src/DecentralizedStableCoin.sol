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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title DecentralizedStableCoin
 * @author yawarasuuna
 * Collateral: Exogenouse (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is the contract meant to be governed by DSCEngine. This contract is just the ERC20 implementation of our stablecoin system.
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__CannotBurnZeroTokens();
    error DecentralizedStableCoin__BalanceLowerThanBurnAmount();
    error DecentralizedStableCoin__CannotMintToZeroAddress();
    error DecentralizedStableCoin__CannotMintZero();

    constructor() ERC20("Decentralized", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__CannotBurnZeroTokens();
        }
        if (balance <= _amount) {
            revert DecentralizedStableCoin__BalanceLowerThanBurnAmount();
        }
        super.burn(_amount); // super uses burn function from parent contract;
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__CannotMintToZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__CannotMintZero();
        }
        _mint(_to, _amount);
        return true;
    }
}