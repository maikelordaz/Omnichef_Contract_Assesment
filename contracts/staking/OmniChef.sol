// SPDX-License-Identifier: MIT
/**
 * @title OmniChef
 * @notice A staking contract
 */
pragma solidity ^0.8.0;

// CONTRACTS IMPORTED
import "@openzeppelin/contracts/access/Ownable.sol";
import "../strategies/OmniCompoundStrategy.sol";
import "../token/Omni.sol";

// LIBRARIES IMPORTED
import "../libs/SafeArithmetics.sol";

// INTERFACES IMPORTED
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OmniChef is OmniCompoundStrategy, Ownable {
    using SafeArithmetics for uint256;

    ///////////////////////
    // GLOBAL VARIABLES //
    /////////////////////

    uint256 public totalStakes; // Total stakes on the contract

    // CEth token address
    /// @dev Finding [H02]
    address public constant CEth = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    /**
     * @notice Omni is a reward token distributed by this contract
     */
    Omni public omni = new Omni("Omniscia Test Token", "OMNI", address(this));

    ///////////////
    // MAPPINGS //
    /////////////

    // User ---> Time when user puts the asset on stake
    mapping(address => uint256) public times;
    // User ---> amount of assets on stake by user
    mapping(address => uint256) public stakes;

    ///////////////
    // MODIFIER //
    /////////////

    /**
     * @notice Modifier to refund any excess ether sent to the contract
     * @param value the value given to the function stake
     * @dev It first run the function and then the modifier
     */
    modifier refund(uint256 value) {
        _;

        // If it is send to the function more than the value to stake
        if (msg.value > value)
            // It calculates the exess and sebd it to the caller
            // A function from OmniCompoundStrategy
            _send(payable(msg.sender), msg.value.safe(SafeArithmetics.Operation.SUB, value));
    }

    //////////////////
    // CONSTRUCTOR //
    ////////////////

    /**
     * @notice main contract constructor
     * @dev it calls the Ownable and OmniCompoundStrategy constructor
     * @dev it sets the ICEth interface with the correct address
     */
    constructor() Ownable() OmniCompoundStrategy(CEth) {}

    /////////////////////////
    // RECEIVE / FALLBACK //
    ///////////////////////

    /**
     * @notice receive function
     * @dev It calls a public function named stake
     * @dev If the return value of this stake function is 0 The receive function reverts
     */
    receive() external payable {
        require(stake(msg.value) != 0, "STAKING_MALFUNCTION");
    }

    /////////////////////////////////////////
    // MAIN FUNCTIONS - STAKING MECHANISM //
    ///////////////////////////////////////

    /**
     * @notice A function to stake
     * @return the amount of asset to stake by the caller
     * @dev It is called by others contracts
     * @dev It calls another function with the same name
     * @dev It does not receive any parameters, but calls another function with the same name,
     * and this last one receives a parameter in this case, the entire msg.value
     */
    function stake() external payable returns (uint256) {
        return stake(msg.value);
    }

    /**
     * @notice A function to stake
     * @param value the amount to stake
     * @return the amount of asset to stake by the caller
     * @dev It is called by the receive function
     * @dev It is called by another function with the same name, and receive as parameter the
     * entire msg.value of that function
     * @dev It can be called by anyone
     * @dev anyone can call it and give any value as a parameter, regarding the msg.value
     */
    function stake(uint256 value) public payable refund(value) returns (uint256) {
        // It updates the user´s staking balance
        stakes[msg.sender] = stakes[msg.sender].safe(SafeArithmetics.Operation.ADD, value);
        // It sets the time when the asset is put on stake
        times[msg.sender] = block.timestamp;
        // It updates the contract´s staking balance
        totalStakes = totalStakes.safe(SafeArithmetics.Operation.ADD, value);

        // return the amount of asset on stake by the user
        return stakes[msg.sender];
        // It performs the modifier refund
    }

    ////////////////////////////////////////
    // MAIN FUNCTIONS - REWARD MECHANISM //
    //////////////////////////////////////

    /**
     * @notice A function to calculate linear time based rewards
     * @param stake user´s staking balance
     * @dev it gives Omni tokens as rewards
     * @dev it updates user´s stats after the transfers, should be before
     */
    function _reward(uint256 stake) internal {
        // It calculates the rewards for the caller
        uint256 reward = stake * (block.timestamp - times[msg.sender]);

        // If the reward is bigger than the contract´s balance. it set the reward as the total balance
        if (reward > omni.balanceOf(address(this))) reward = omni.balanceOf(address(this));

        // If there is some rewards it is transfer to the caller
        /// @dev Finding [H03]
        if (reward != 0) omni.transfer(msg.sender, reward);

        // It updates the user´s value for times
        /// @dev Finding [M01]
        times[msg.sender] = 0;
    }

    //////////////////////////////////////////
    // MAIN FUNCTIONS - WITHDRAW MECHANISM //
    ////////////////////////////////////////

    /**
     * @notice A function to withdraw
     * @param value value to withdraw
     */
    function withdraw(uint256 value) external returns (uint256 amount) {
        // Verify if the user has enough balance on staking
        require(stakes[msg.sender] >= value, "INSUFFICIENT_STAKE");

        // balance() is from OmniCompoundStrategy
        amount = stakes[msg.sender].safe(SafeArithmetics.Operation.MUL, balance()).safe(
            SafeArithmetics.Operation.DIV,
            totalStakes
        );

        // It updates the user´s staking balance
        stakes[msg.sender] = stakes[msg.sender].safe(SafeArithmetics.Operation.SUB, value);
        // It updates the contract´s staking balance
        totalStakes = totalStakes.safe(SafeArithmetics.Operation.SUB, value);

        // function from OmniCompoundStrategy
        _unlock(amount);
        // It calculates the rewards
        _reward(value);
    }

    /////////////////////////////////
    // MAIN FUNCTIONS - OWNERSHIP //
    ///////////////////////////////

    /**
     * @notice A method to prevent Renouncation to ownership of contract
     * @dev it overrides a function on the Ownable contract
     */
    function renounceOwnership() public override {
        revert("NO_OP");
    }

    /**
     * @notice A method to prevent Transfer of Ownership
     * @dev it overrides a function on the Ownable contract
     */
    function transferOwnership(address newOwner) public override {
        revert("NO_OP");
    }
}
