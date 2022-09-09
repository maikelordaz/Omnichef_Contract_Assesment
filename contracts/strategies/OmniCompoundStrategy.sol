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

    /**
     * It sets the ICEth interface according to the call of OmniChef
     */
    constructor(address _CEth) {
        CEth = ICEth(_CEth);
    }

    // Deposit funds into the Compound ERC20 token
    // It is public so anybody can call it and deposit all the contract balance at any time
    function deposit() public {
        _send(payable(address(CEth)), address(this).balance);
    }

    // Compound funds acquired from interest on Compound
    function compound() external {
        // Calculates the interes
        CEth.accrueInterest();
        // Call the unlock function on this same contract
        OmniCompoundStrategy(address(this)).unlock();
        // calls deposit
        deposit();
    }

    // Allow invocation only by self for compounding
    function unlock() external {
        // verify the caller
        require(msg.sender == address(this), "INSUFFICIENT_PRIVILEGES");
        // It calls the function _unlock on this contract
        _unlock(balance());
    }

    // Calculate total balance
    function balance() public view returns (uint256) {
        // contract´s balance + contracts CEth balance of underlying
        return address(this).balance + CEth.balanceOfUnderlying(address(this));
    }

    // Public or internal????
    function _unlock(uint256 amount) public {
        // If the amount is bigger than the contract´s balance redeem the needed
        if (amount > address(this).balance)
            CEth.redeem(
                // (amount - contract´s balance) * contract´s CEth balance / contract´s CEth balance of underlying
                (amount - address(this).balance)
                    .safe(SafeArithmetics.Operation.MUL, CEth.balanceOf(address(this)))
                    .safe(SafeArithmetics.Operation.DIV, CEth.balanceOfUnderlying(address(this)))
            );

        // transfer the caller the amount
        _send(payable(msg.sender), amount);
    }

    function _send(address payable target, uint256 amount) internal {
        target.transfer(amount);
    }
}
