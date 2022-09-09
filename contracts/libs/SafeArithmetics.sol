// SPDX-License-Identifier: MIT

/**
 * @title SafeArithmetics
 * @notice A library with safe arithmetics operations to avoid overflows and underflows
 */

pragma solidity ^0.8.0;

library SafeArithmetics {
    ///////////////////////
    // GLOBAL VARIABLES //
    /////////////////////
    /**
     * @notice The arithmetics operations to perform
     */
    enum Operation {
        ADD,
        SUB,
        MUL,
        DIV,
        POW
    }

    /////////////////////
    // MAIN FUNCTIONS //
    ///////////////////

    /**
     * @notice A function to perform Operations when two parameters are received
     * @param a Value to operate
     * @param op operation to execute
     * @return the result of the operation
     * @dev It calls another function with the same name, but this last one receive three
     * parameters
     */
    function safe(uint256 a, Operation op) internal pure returns (uint256) {
        return safe(a, op, a);
    }

    /**
     * @notice A function to perform Operations when three parameters are received
     * @param a Value to operate
     * @param b Value to operate
     * @param op operation to execute
     * @return it returns a
     * @dev It is called by another function with the same name, but this last one receive two
     * parameters
     * @dev For ADDING "a" must be the greater
     * @dev For SUBSTRACTION "b" must be the greater
     * @dev For DIVIDING "b" must be different than zero
     * @dev The operations SUBSTRACTION is wrong
     * @dev It always return a after the operations
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
            a -= b;
            require(a <= b);
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
