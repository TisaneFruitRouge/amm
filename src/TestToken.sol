// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract TestToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint public totalSupply = 9 * 10 ** decimals;

    constructor(string memory _name, string memory _symbol) IERC20() {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address account) external view returns (uint256) {
        return 0;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint) {
        return 0;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        return true;
    }
}
