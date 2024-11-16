// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Jar
 * @dev A contract that implements a cookie jar mechanism with reputation-based withdrawals.
 */
contract Jar is Ownable, ReentrancyGuard {
    // EAS Interface
    IEAS public eas;
    bytes32 public constant SCHEMA_UID = keccak256("JarPull"); // Schema to register

    // Withdrawal tracking
    struct UserInfo {
        uint256 lastWithdrawalTime;
        uint256 withdrawalLimit; // Percentage x 100 (e.g., 1000 = 10%)
        uint256 likes;
        uint256 dislikes;
    }

    mapping(address => UserInfo) public userInfo;

    // Whitelist mapping
    mapping(address => bool) public isWhitelisted;

    // Constants
    uint256 public constant BASE_WITHDRAWAL_LIMIT = 1000; // 10%
    uint256 public constant MAX_WITHDRAWAL_LIMIT = 2000; // 20%
    uint256 public constant MIN_WITHDRAWAL_LIMIT = 500; // 5%
    uint256 public constant WITHDRAWAL_COOLDOWN = 1 days;

    // Events
    event FundsWithdrawn(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, bool isLike);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    event AddressWhitelisted(address indexed account);
    event WhitelistContractUpdated(address indexed newWhitelist);

    /**
     * @dev Initializes the contract by setting the EAS contract address.
     * Grants the deployer the whitelist privilege.
     * @param _easContract Address of the EAS contract.
     */
    constructor(address _easContract) {
        require(_easContract != address(0), "Invalid EAS address");
        eas = IEAS(_easContract);

        // Automatically whitelist the contract deployer
        isWhitelisted[msg.sender] = true;
        userInfo[msg.sender].withdrawalLimit = BASE_WITHDRAWAL_LIMIT;

        emit AddressWhitelisted(msg.sender);
    }

    // Modifiers
    modifier onlyWhitelistedUser() {
        require(isWhitelisted[msg.sender], "Not whitelisted");
        _;
    }

    modifier canWithdrawToday() {
        require(
            block.timestamp >= userInfo[msg.sender].lastWithdrawalTime + WITHDRAWAL_COOLDOWN,
            "Must wait 24 hours between withdrawals"
        );
        _;
    }

    /**
     * @dev Adds a single address to the whitelist.
     * @param _address The address to whitelist.
     */
    function addToWhitelist(address _address) external onlyOwner {
        require(_address != address(0), "Cannot whitelist zero address");
        require(!isWhitelisted[_address], "Address already whitelisted");

        isWhitelisted[_address] = true;
        userInfo[_address].withdrawalLimit = BASE_WITHDRAWAL_LIMIT;

        emit AddressWhitelisted(_address);
    }

    /**
     * @dev Adds multiple addresses to the whitelist.
     * @param _addresses Array of addresses to whitelist.
     */
    function addBatchToWhitelist(address[] calldata _addresses) external onlyOwner {
        uint256 addedCount = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            address addr = _addresses[i];
            if (addr != address(0) && !isWhitelisted[addr]) {
                isWhitelisted[addr] = true;
                userInfo[addr].withdrawalLimit = BASE_WITHDRAWAL_LIMIT;
                addedCount++;
                emit AddressWhitelisted(addr);
            }
        }
        emit BatchWhitelistAdded(addedCount);
    }

    /**
     * @dev Allows a whitelisted user to withdraw funds based on their withdrawal limit.
     */
    function withdraw() external onlyWhitelistedUser canWithdrawToday nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Jar is empty");

        UserInfo storage user = userInfo[msg.sender];
        uint256 maxWithdrawal = (balance * user.withdrawalLimit) / 10000;
        require(maxWithdrawal > 0, "Withdrawal amount too small");

        user.lastWithdrawalTime = block.timestamp;

        (bool sent, ) = payable(msg.sender).call{value: maxWithdrawal}("");
        require(sent, "Failed to send Ether");

        emit FundsWithdrawn(msg.sender, maxWithdrawal);
    }

    /**
     * @dev Allows the owner to perform an emergency withdrawal of all funds.
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Jar is empty");

        (bool sent, ) = payable(owner()).call{value: balance}("");
        require(sent, "Failed to send Ether");

        emit EmergencyWithdrawal(owner(), balance);
    }

    /**
     * @dev Allows whitelisted users to submit reputational attestations.
     * @param user The user to attest.
     * @param isLike True if it's a like, false if it's a dislike.
     */
    function submitAttestation(address user, bool isLike) external onlyWhitelistedUser {
        require(user != msg.sender, "Cannot rate yourself");
        require(isWhitelisted[user], "Target not whitelisted");

        // Create attestation
        bytes memory data = abi.encode(user, isLike, block.timestamp);
        eas.attest(SCHEMA_UID, user, data);

        // Update reputation
        UserInfo storage userData = userInfo[user];
        if (isLike) {
            userData.likes += 1;
        } else {
            userData.dislikes += 1;
        }

        // Update withdrawal limit based on reputation
        _updateWithdrawalLimit(user);

        emit ReputationUpdated(user, isLike);
    }

    /**
     * @dev Internal function to update a user's withdrawal limit based on reputation.
     * @param user The user whose withdrawal limit is to be updated.
     */
    function _updateWithdrawalLimit(address user) internal {
        UserInfo storage userData = userInfo[user];
        uint256 totalVotes = userData.likes + userData.dislikes;
        if (totalVotes == 0) {
            userData.withdrawalLimit = BASE_WITHDRAWAL_LIMIT;
            return;
        }

        uint256 likeRatio = (userData.likes * 1000) / totalVotes;

        if (likeRatio >= 800) { // 80%+ likes
            userData.withdrawalLimit = MAX_WITHDRAWAL_LIMIT;
        } else if (likeRatio <= 200) { // 20% or less likes
            userData.withdrawalLimit = MIN_WITHDRAWAL_LIMIT;
        } else {
            userData.withdrawalLimit = MIN_WITHDRAWAL_LIMIT + 
                ((likeRatio - 200) * (MAX_WITHDRAWAL_LIMIT - MIN_WITHDRAWAL_LIMIT)) / 600;
        }
    }

    /**
     * @dev Retrieves reputation statistics for a user.
     * @param user The user to query.
     * @return userLikes Number of likes.
     * @return userDislikes Number of dislikes.
     * @return currentWithdrawalLimit Current withdrawal limit.
     */
    function getReputationStats(address user) external view returns (
        uint256 userLikes,
        uint256 userDislikes,
        uint256 currentWithdrawalLimit
    ) {
        UserInfo storage userData = userInfo[user];
        return (userData.likes, userData.dislikes, userData.withdrawalLimit);
    }

    /**
     * @dev Updates the EAS contract reference.
     * @param _newEASContract The new EAS contract address.
     */
    function setEASContract(address _newEASContract) external onlyOwner {
        require(_newEASContract != address(0), "Invalid EAS address");
        eas = IEAS(_newEASContract);
        emit WhitelistContractUpdated(_newEASContract);
    }

    // Receive function to accept ETH
    receive() external payable {}
}

/**
 * @dev Interface for EAS (Ethereum Attestation Service)
 */
interface IEAS {
    function attest(bytes32 schemaUID, address recipient, bytes memory data) external;
}
