// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract AMMPair is IERC20 {
    constructor() {}

    //ERC20 Functions for LP Token

    uint constant MINIMUM_LIQUIDITY = 1000;

    uint private LPTokenTotalSupply;
    string public name = "AMMPairLPToken";
    string public symbol = "LP";
    uint8 public decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    function totalSupply() external view returns (uint256) {
        return LPTokenTotalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[from] >= amount, "Insufficient balance");
        require(
            allowances[from][msg.sender] >= amount,
            "Insufficient allowance"
        );

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    // Pair Functions

    IERC20 public token1;
    IERC20 public token2;

    uint private reserve1;
    uint private reserve2;

    function initialize(address _token1, address _token2) public {
        require(address(token1) == address(0), "Already initialized");
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
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

            token1.transferFrom(msg.sender, address(this), amountInWithFee);
            token2.transfer(msg.sender, amountOut);

            reserve1 += amountInWithFee;
            reserve1 += fees;

            reserve2 -= amountOut;
        } else {
            uint amountInWithFee = (amountToken2 * 997) / 1000;
            uint fees = amountToken2 - amountInWithFee;
            uint invariant = reserve1 * reserve2;

            // invariant = (reserve2 - amountInWithFee) * (reserve1 + amountOut);
            // invariant / ((reserve2 - amountInWithFee)) = reserve1 + amountOut
            // invariant / ((reserve2 - amountInWithFee)) - reserve1 = amountOut
            uint amountOut = invariant /
                ((reserve1 - amountInWithFee)) -
                reserve2;

            token2.transferFrom(msg.sender, address(this), amountInWithFee);
            token1.transfer(msg.sender, amountOut);

            reserve2 += amountInWithFee;
            reserve2 += fees;

            reserve1 -= amountOut;
        }
    }

    function getReserves() public view returns (uint, uint) {
        return (reserve1, reserve2);
    }

    function mint(address to) public {
        uint amount1 = token1.balanceOf(address(this)) - reserve1;
        uint amount2 = token2.balanceOf(address(this)) - reserve2;
        if (LPTokenTotalSupply == 0) {
            uint liquidity = Math.sqrt(amount1 * amount2);
            LPTokenTotalSupply = liquidity + MINIMUM_LIQUIDITY;
            balances[address(0)] = MINIMUM_LIQUIDITY;
            balances[to] = liquidity;
            emit Transfer(address(0), to, liquidity);
        } else {
            uint liquidity = Math.min(
                (amount1 * LPTokenTotalSupply) / reserve1,
                (amount2 * LPTokenTotalSupply) / reserve2
            );
            LPTokenTotalSupply += liquidity;
            balances[to] += liquidity;
            emit Transfer(address(0), to, liquidity);
        }
        reserve1 += amount1;
        reserve2 += amount2;
    }

    function burn(address to) public {
        uint UserLPAmount = balances[address(this)]; // the LP tokens have been transfered to the Pair itself by the router
        require(UserLPAmount > 0, "AMMPair: INSUFFICIENT_LIQUIDITY_BURNED");

        uint amount1 = (reserve1 * UserLPAmount) / LPTokenTotalSupply;
        uint amount2 = (reserve2 * UserLPAmount) / LPTokenTotalSupply;
        token1.transfer(to, amount1);
        token2.transfer(to, amount2);

        balances[address(this)] -= UserLPAmount;
        LPTokenTotalSupply -= UserLPAmount;
        emit Transfer(msg.sender, address(0), UserLPAmount);

        reserve1 -= amount1;
        reserve2 -= amount2;
    }
}
