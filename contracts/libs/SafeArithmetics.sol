// SPDX-License-Identifier: MIT
/**
 * @title SafeArithmetics
 * @notice A library with safe arithmetics operations to avoid overflows and underflows
 */
pragma solidity ^0.8.0;

library SafeArithmetics {
    enum Operation {
        ADD,
        SUB,
        MUL,
        DIV,
        POW
    }

    /**
     * @notice A function to perform Operations when three parameters are received
     * @param a Value to operate
     * @param b Value to operate
     * @param op operation to execute
     * @return it returns a
     */
    function safe(
        uint256 a,
        Operation op,
        uint256 b
    ) internal pure returns (uint256) {
        if (op == Operation.ADD) {
            a += b;
            require(a >= b);
        } else if (op == Operation.SUB) {
            uint256 c = a;
            a -= b;
            require(safe(a, Operation.ADD, b) == c);
        } else if (op == Operation.MUL) {
            uint256 c = a;
            a *= b;
            require(safe(a, Operation.DIV, b) == c);
        } else if (op == Operation.DIV) {
            require(b != 0);
            a /= b;
        } else if (op == Operation.POW) {
            uint256 c = a;
            a**b;
            require(a >= c || a == 1);
        }

        return a;
    }
}
