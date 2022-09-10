// SPDX-License-Identifier: MIT
/**
 * @title OmniCompoundStrategy and ICEth interface
 * @notice A staking contract
 */
pragma solidity ^0.8.0;

// LIBRARIES IMPORTED
import "../libs/SafeArithmetics.sol";

/**
 * @title OmniCompoundStrategy and ICEth interface
 * @notice A staking contract
 * @dev Minimal CEth interface, see https://etherscan.io/address/0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5#code
 */
interface ICEth {
    function redeem(uint256) external;

    function accrueInterest() external;

    function balanceOfUnderlying(address owner) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

// Manages an ETH native balance to interact with the Compound protocol: https://compound.finance/docs#getting-started
contract OmniCompoundStrategy {
    using SafeArithmetics for uint256;

    ICEth private CEth;

    constructor(address _CEth) {
        CEth = ICEth(_CEth);
    }

    function deposit() internal {
        _send(payable(address(CEth)), address(this).balance);
    }

    // Compound funds acquired from interest on Compound
    function compound() external {
        CEth.accrueInterest();
        deposit();
    }

    // Calculate total balance
    function balance() public view returns (uint256) {
        return address(this).balance + CEth.balanceOfUnderlying(address(this));
    }

    function _unlock(uint256 amount) internal {
        if (amount > address(this).balance)
            CEth.redeem(
                (amount - address(this).balance)
                    .safe(SafeArithmetics.Operation.MUL, CEth.balanceOf(address(this)))
                    .safe(SafeArithmetics.Operation.DIV, CEth.balanceOfUnderlying(address(this)))
            );

        _send(payable(msg.sender), amount);
    }

    function _send(address payable target, uint256 amount) internal {
        target.transfer(amount);
    }
}
