// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract KolectDailyCheckIn is Ownable, Pausable {
    // ===== Project Metadata (Constant Information) =====

    string public constant PROJECT_NAME = "Kolect";
    string public constant MODULE_NAME = "Kolect Daily Check-In Points";
    string public constant MODULE_DESCRIPTION =
        "On-chain daily check-in system that records non-transferable points for Kolect users.";
    string public constant PROJECT_WEBSITE = "https://kolect.info";
    string public constant PROJECT_TWITTER = "https://x.com/kolect_info";
    string public constant MODULE_VERSION = "v1.0.0";

    // ===== Check-In & Points Storage =====

    // Address => Last check-in timestamp
    mapping(address => uint256) public lastCheckIn;

    // Address => Accumulated non-transferable points
    mapping(address => uint256) public points;

    // Minimum required interval between check-ins (24 hours)
    uint256 public constant CHECKIN_INTERVAL = 1 days;

    // Emitted whenever a user checks in
    event CheckedIn(address indexed user, uint256 timestamp, uint256 totalPoints);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Internal logic for determining whether a user can check in.
     */
    function _canCheckIn(address user, uint256 currentTimestamp)
        internal
        view
        returns (bool)
    {
        uint256 last = lastCheckIn[user];

        if (last == 0) {
            return true; // First-time check-in
        }

        return currentTimestamp >= last + CHECKIN_INTERVAL;
    }

    /**
     * @notice Daily check-in.
     */
    function checkIn() external whenNotPaused {
        require(
            _canCheckIn(msg.sender, block.timestamp),
            "Kolect: can only check in once per day"
        );

        lastCheckIn[msg.sender] = block.timestamp;
        points[msg.sender] += 1;

        emit CheckedIn(msg.sender, block.timestamp, points[msg.sender]);
    }

    /**
     * @notice Whether a user can check in right now.
     */
    function canCheckIn(address user) external view returns (bool) {
        return _canCheckIn(user, block.timestamp);
    }

    /**
     * @notice When the user can check in next time.
     */
    function nextCheckInTime(address user) external view returns (uint256) {
        uint256 last = lastCheckIn[user];

        if (last == 0) {
            return block.timestamp; // First-time check-in
        }

        return last + CHECKIN_INTERVAL;
    }

    /**
     * @notice Get user's point balance.
     */
    function getPoints(address user) external view returns (uint256) {
        return points[user];
    }

    /**
     * @notice Get last check-in timestamp.
     */
    function getLastCheckIn(address user) external view returns (uint256) {
        return lastCheckIn[user];
    }

    /**
     * @notice Pause check-in system.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause check-in system.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Override renounceOwnership to disable it permanently.
     * @dev This prevents accidentally locking the contract with no owner.
     */
    function renounceOwnership() public view override onlyOwner {
        revert("Kolect: renouncing ownership is disabled");
    }
}