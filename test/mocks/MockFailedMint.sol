// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockFailedMint is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__CannotBurnZeroTokens();
    error DecentralizedStableCoin__BalanceLowerThanBurnAmount();
    error DecentralizedStableCoin__CannotMintToZeroAddress();
    error DecentralizedStableCoin__CannotMintZero();

    /*
    In future versions of OpenZeppelin contracts package, Ownable must be declared with an address of the contract owner
    as a parameter.
    For example:
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) {}
    Related code changes can be viewed in this commit:
    https://github.com/OpenZeppelin/openzeppelin-contracts/commit/13d5e0466a9855e9305119ed383e54fc913fdc60
    */
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__CannotBurnZeroTokens();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin__BalanceLowerThanBurnAmount();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__CannotMintToZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__CannotMintZero();
        }
        _mint(_to, _amount);
        return false;
    }
}
