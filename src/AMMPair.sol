// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestToken} from "./TestToken.sol";

contract AMMPair {
    TestToken public token1;
    TestToken public token2;

    uint private reserve1;
    uint private reserve2;

    constructor() {
        token1 = new TestToken("TestToken1", "TT1");
        token2 = new TestToken("TestToken2", "TT2");
    }

    function swap(uint amountToken1, uint amountToken2) public {
        require(
            !(amountToken1 > 0 && amountToken2 > 0),
            "Cannot swap two tokens at the same time"
        );

        if (amountToken1 > 0) {
            uint amountInWithFee = (amountToken1 * 997) / 1000;
            uint fees = amountToken1 - amountInWithFee;
            uint invariant = reserve1 * reserve2;

            // invariant = (reserve1 - amountInWithFee) * (reserve2 + amountOut);
            // invariant / ((reserve1 - amountInWithFee)) = reserve2 + amountOut
            // invariant / ((reserve1 - amountInWithFee)) - reserve2 = amountOut
            uint amountOut = invariant /
                ((reserve1 - amountInWithFee)) -
                reserve2;

            reserve1 += amountInWithFee;
            reserve1 += fees;

            reserve2 -= amountOut;

            token1.transferFrom(msg.sender, address(this), amountInWithFee);
            token2.transfer(msg.sender, amountOut);
        } else {
            uint amountInWithFee = (amountToken2 * 997) / 1000;
            uint fees = amountToken2 - amountInWithFee;
            uint invariant = reserve1 * reserve2;

            // invariant = (reserve2 - amountInWithFee) * (reserve1 + amountOut);
            // invariant / ((reserve2 - amountInWithFee)) = reserve1 + amountOut
            // invariant / ((reserve2 - amountInWithFee)) - reserve1 = amountOut
            uint amountOut = invariant /
                ((reserve2 - amountInWithFee)) -
                reserve1;

            reserve2 += amountInWithFee;
            reserve2 += fees;

            reserve1 -= amountOut;

            token1.transferFrom(msg.sender, address(this), amountInWithFee);
            token2.transfer(msg.sender, amountOut);
        }
    }

    function mint() public {}

    function burn() public {}
}
