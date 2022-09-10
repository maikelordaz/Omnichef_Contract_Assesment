// SPDX-License-Identifier: MIT
/**
 * @title OmniChef
 * @notice A staking contract
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../strategies/OmniCompoundStrategy.sol";
import "../token/Omni.sol";
import "../libs/SafeArithmetics.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error OmniChef__StakingMalfunction();
error OmniChef__InsufficientEthSended();
error OmniChef__TransferFailed();
error OmniChef__InsufficientStake();
error OmniChef__NO_OP();

contract OmniChef is OmniCompoundStrategy, Ownable {
    using SafeArithmetics for uint256;

    uint256 public totalStakes; // Total stakes on the contract

    address public constant CEthAddress = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    Omni public omni = new Omni("Omniscia Test Token", "OMNI", address(this));

    mapping(address => uint256) public times;
    mapping(address => uint256) public stakes;

    constructor() Ownable() OmniCompoundStrategy(CEthAddress) {}

    /**
     * @notice receive function
     * @dev It calls a public function named stake
     * @dev If the return value of this stake function is 0 The receive function reverts
     */
    receive() external payable {
        if (_stake(msg.value) == 0) {
            revert OmniChef__StakingMalfunction();
        }
    }

    /**
     * @notice A function to stake
     * @return the amount of asset to stake by the caller
     */

    function stake() external payable returns (uint256) {
        if (msg.value == 0) {
            revert OmniChef__StakingMalfunction();
        }
        return _stake(msg.value);
    }

    /**
     * @notice A function to stake
     * @param value the amount to stake
     * @return the amount of asset to stake by the caller
     */
    function _stake(uint256 value) internal returns (uint256) {
        if (value >= msg.value) {
            revert OmniChef__InsufficientEthSended();
        }
        stakes[msg.sender] = stakes[msg.sender].safe(SafeArithmetics.Operation.ADD, value);
        times[msg.sender] = block.timestamp;
        totalStakes = totalStakes.safe(SafeArithmetics.Operation.ADD, value);

        return stakes[msg.sender];
    }

    /**
     * @notice A function to calculate linear time based rewards
     * @param stakesAmount user´s staking balance
     * @dev it gives Omni tokens as rewards
     */
    function _reward(uint256 stakesAmount) internal {
        uint256 reward = stakesAmount * (block.timestamp - times[msg.sender]);

        if (reward > omni.balanceOf(address(this))) reward = omni.balanceOf(address(this));

        times[msg.sender] = 0;
        if (reward != 0) {
            bool success = omni.transfer(msg.sender, reward);
            if (!success) {
                revert OmniChef__TransferFailed();
            }
        }
    }

    /**
     * @notice A function to withdraw
     * @param value value to withdraw
     */
    function withdraw(uint256 value) external returns (uint256 amount) {
        if (stakes[msg.sender] <= value) {
            revert OmniChef__InsufficientStake();
        }

        amount = stakes[msg.sender].safe(SafeArithmetics.Operation.MUL, balance()).safe(
            SafeArithmetics.Operation.DIV,
            totalStakes
        );

        stakes[msg.sender] = stakes[msg.sender].safe(SafeArithmetics.Operation.SUB, value);

        totalStakes = totalStakes.safe(SafeArithmetics.Operation.SUB, value);

        _reward(value);
        _unlock(amount);
    }

    /**
     * @notice A method to prevent Renouncation to ownership of contract
     * @dev it overrides a function on the Ownable contract
     */
    function renounceOwnership() public pure override {
        revert OmniChef__NO_OP();
    }

    /**
     * @notice A method to prevent Transfer of Ownership
     * @dev it overrides a function on the Ownable contract
     */
    function transferOwnership(
        address /*newOwner*/
    ) public pure override {
        revert OmniChef__NO_OP();
    }
}
