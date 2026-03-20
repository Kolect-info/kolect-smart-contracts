// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract KolectSentimentFeed {
    // ===== Project Metadata (Constant Information) =====

    string public constant PROJECT_NAME = "Kolect";
    string public constant MODULE_NAME = "Kolect Sentiment Feed";
    string public constant MODULE_DESCRIPTION =
        "On-chain sentiment oracle for Kolect that records and serves normalized market sentiment data for supported symbols and time windows.";
    string public constant PROJECT_WEBSITE = "https://kolect.info";
    string public constant PROJECT_TWITTER = "https://x.com/kolect_info";
    string public constant MODULE_VERSION = "v1.0.0";

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOwner();
    error NotPublisher();
    error UnsupportedSymbol();
    error UnsupportedTimeWindow();
    error PendingRequestExists();
    error FeedStillFresh();
    error InvalidRequestStatus();
    error InvalidBpsSum();
    error InvalidTimestamp();
    error ZeroAddress();
    error InsufficientRequestFee();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PublisherUpdated(address indexed oldPublisher, address indexed newPublisher);
    event RequestFeeUpdated(uint256 oldFee, uint256 newFee);
    event SupportedSymbolUpdated(bytes32 indexed symbolHash, string symbol, bool allowed);
    event SupportedTimeWindowUpdated(bytes32 indexed windowHash, string timeWindow, bool allowed);
    event UpdateIntervalUpdated(bytes32 indexed windowHash, string timeWindow, uint256 updateInterval);

    event UpdateRequested(
        uint256 indexed requestId,
        bytes32 indexed key,
        address indexed requester,
        string symbol,
        string timeWindow,
        uint256 requestFeePaid
    );

    event RequestFulfilled(
        uint256 indexed requestId,
        bytes32 indexed key,
        uint32 negativeBps,
        uint32 neutralBps,
        uint32 positiveBps,
        uint64 dataTimestamp,
        uint64 updatedAt
    );

    event RequestFailed(uint256 indexed requestId, bytes32 indexed key, uint8 errorCode);
    event FeesWithdrawn(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                  ENUM
    //////////////////////////////////////////////////////////////*/

    enum RequestStatus {
        None,
        Pending,
        Fulfilled,
        Failed
    }

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct SentimentData {
        uint32 negativeBps;
        uint32 neutralBps;
        uint32 positiveBps;
        uint64 dataTimestamp;
        uint64 updatedAt;
        bool exists;
    }

    struct UpdateRequest {
        bytes32 key;
        address requester;
        uint64 requestedAt;
        uint64 fulfilledAt;
        uint256 requestFeePaid;
        RequestStatus status;
        uint8 errorCode;
    }

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public publisher;
    uint256 public requestFee;
    uint256 public nextRequestId = 1;

    // feed key => latest sentiment data
    mapping(bytes32 => SentimentData) private latestFeeds;

    // requestId => request details
    mapping(uint256 => UpdateRequest) public requests;

    // feed key => current pending requestId
    mapping(bytes32 => uint256) public pendingRequestByKey;

    // symbol hash => allowed
    mapping(bytes32 => bool) public supportedSymbols;

    // time window hash => allowed
    mapping(bytes32 => bool) public supportedTimeWindows;

    // time window hash => update interval in seconds
    mapping(bytes32 => uint256) public updateIntervalByWindow;

    // Enumerable lists for frontend use
    string[] private supportedSymbolList;
    string[] private supportedTimeWindowList;

    mapping(bytes32 => bool) private symbolEverAdded;
    mapping(bytes32 => bool) private timeWindowEverAdded;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyPublisher() {
        if (msg.sender != publisher) revert NotPublisher();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _publisher, uint256 _requestFee) {
        if (_publisher == address(0)) revert ZeroAddress();

        owner = msg.sender;
        publisher = _publisher;
        requestFee = _requestFee;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _symbolHash(string memory symbol) internal pure returns (bytes32) {
        return keccak256(bytes(symbol));
    }

    function _windowHash(string memory timeWindow) internal pure returns (bytes32) {
        return keccak256(bytes(timeWindow));
    }

    function _feedKey(string memory symbol, string memory timeWindow) internal pure returns (bytes32) {
        bytes32 symbolHash = _symbolHash(symbol);
        bytes32 windowHash = _windowHash(timeWindow);
        return keccak256(abi.encodePacked(symbolHash, windowHash));
    }

    function _isFreshInternal(string memory symbol, string memory timeWindow) internal view returns (bool) {
        bytes32 key = _feedKey(symbol, timeWindow);
        SentimentData memory s = latestFeeds[key];

        if (!s.exists) {
            return false;
        }

        bytes32 windowHash = _windowHash(timeWindow);
        uint256 updateInterval = updateIntervalByWindow[windowHash];

        if (updateInterval == 0) {
            return false;
        }

        return block.timestamp <= uint256(s.dataTimestamp) + updateInterval;
    }

    /*//////////////////////////////////////////////////////////////
                           OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setPublisher(address newPublisher) external onlyOwner {
        if (newPublisher == address(0)) revert ZeroAddress();

        address oldPublisher = publisher;
        publisher = newPublisher;

        emit PublisherUpdated(oldPublisher, newPublisher);
    }

    function setRequestFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = requestFee;
        requestFee = newFee;

        emit RequestFeeUpdated(oldFee, newFee);
    }

    function setSupportedSymbol(string calldata symbol, bool allowed) external onlyOwner {
        bytes32 h = _symbolHash(symbol);
        supportedSymbols[h] = allowed;

        if (!symbolEverAdded[h]) {
            supportedSymbolList.push(symbol);
            symbolEverAdded[h] = true;
        }

        emit SupportedSymbolUpdated(h, symbol, allowed);
    }

    function setSupportedTimeWindow(string calldata timeWindow, bool allowed) external onlyOwner {
        bytes32 h = _windowHash(timeWindow);
        supportedTimeWindows[h] = allowed;

        if (!timeWindowEverAdded[h]) {
            supportedTimeWindowList.push(timeWindow);
            timeWindowEverAdded[h] = true;
        }

        emit SupportedTimeWindowUpdated(h, timeWindow, allowed);
    }

    function setUpdateInterval(string calldata timeWindow, uint256 updateInterval) external onlyOwner {
        bytes32 h = _windowHash(timeWindow);
        updateIntervalByWindow[h] = updateInterval;

        emit UpdateIntervalUpdated(h, timeWindow, updateInterval);
    }

    function withdrawFees(address payable to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        require(amount <= address(this).balance, "insufficient balance");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "withdraw failed");

        emit FeesWithdrawn(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isSupportedSymbol(string calldata symbol) external view returns (bool) {
        return supportedSymbols[_symbolHash(symbol)];
    }

    function isSupportedTimeWindow(string calldata timeWindow) external view returns (bool) {
        return supportedTimeWindows[_windowHash(timeWindow)];
    }

    function getUpdateInterval(string calldata timeWindow) external view returns (uint256) {
        return updateIntervalByWindow[_windowHash(timeWindow)];
    }

    function getSupportedSymbols() external view returns (string[] memory) {
        return supportedSymbolList;
    }

    function getSupportedTimeWindows() external view returns (string[] memory) {
        return supportedTimeWindowList;
    }

    function getActiveSupportedSymbols() external view returns (string[] memory) {
        uint256 len = supportedSymbolList.length;
        uint256 count = 0;

        for (uint256 i = 0; i < len; i++) {
            if (supportedSymbols[_symbolHash(supportedSymbolList[i])]) {
                count++;
            }
        }

        string[] memory result = new string[](count);
        uint256 idx = 0;

        for (uint256 i = 0; i < len; i++) {
            if (supportedSymbols[_symbolHash(supportedSymbolList[i])]) {
                result[idx] = supportedSymbolList[i];
                idx++;
            }
        }

        return result;
    }

    function getActiveSupportedTimeWindows() external view returns (string[] memory) {
        uint256 len = supportedTimeWindowList.length;
        uint256 count = 0;

        for (uint256 i = 0; i < len; i++) {
            if (supportedTimeWindows[_windowHash(supportedTimeWindowList[i])]) {
                count++;
            }
        }

        string[] memory result = new string[](count);
        uint256 idx = 0;

        for (uint256 i = 0; i < len; i++) {
            if (supportedTimeWindows[_windowHash(supportedTimeWindowList[i])]) {
                result[idx] = supportedTimeWindowList[i];
                idx++;
            }
        }

        return result;
    }

    function isFresh(string calldata symbol, string calldata timeWindow) external view returns (bool) {
        return _isFreshInternal(symbol, timeWindow);
    }

    function hasPendingRequest(string calldata symbol, string calldata timeWindow) external view returns (bool) {
        bytes32 key = _feedKey(symbol, timeWindow);
        return pendingRequestByKey[key] != 0;
    }

    function getLatest(
        string calldata symbol,
        string calldata timeWindow
    )
        external
        view
        returns (
            uint32 negativeBps,
            uint32 neutralBps,
            uint32 positiveBps,
            uint64 dataTimestamp,
            uint64 updatedAt,
            bool exists,
            bool fresh,
            uint256 pendingRequestId,
            uint256 updateInterval
        )
    {
        bytes32 key = _feedKey(symbol, timeWindow);
        SentimentData memory s = latestFeeds[key];
        bytes32 windowHash = _windowHash(timeWindow);

        return (
            s.negativeBps,
            s.neutralBps,
            s.positiveBps,
            s.dataTimestamp,
            s.updatedAt,
            s.exists,
            _isFreshInternal(symbol, timeWindow),
            pendingRequestByKey[key],
            updateIntervalByWindow[windowHash]
        );
    }

    function getRequest(
        uint256 requestId
    )
        external
        view
        returns (
            bytes32 key,
            address requester,
            uint64 requestedAt,
            uint64 fulfilledAt,
            uint256 requestFeePaid,
            RequestStatus status,
            uint8 errorCode
        )
    {
        UpdateRequest memory r = requests[requestId];
        return (
            r.key,
            r.requester,
            r.requestedAt,
            r.fulfilledAt,
            r.requestFeePaid,
            r.status,
            r.errorCode
        );
    }

    /*//////////////////////////////////////////////////////////////
                           USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function requestUpdate(
        string calldata symbol,
        string calldata timeWindow
    ) external payable returns (uint256 requestId) {
        if (msg.value < requestFee) revert InsufficientRequestFee();

        bytes32 symbolHash = _symbolHash(symbol);
        if (!supportedSymbols[symbolHash]) revert UnsupportedSymbol();

        bytes32 windowHash = _windowHash(timeWindow);
        if (!supportedTimeWindows[windowHash]) revert UnsupportedTimeWindow();

        if (_isFreshInternal(symbol, timeWindow)) revert FeedStillFresh();

        bytes32 key = _feedKey(symbol, timeWindow);

        if (pendingRequestByKey[key] != 0) revert PendingRequestExists();

        requestId = nextRequestId;
        nextRequestId++;

        requests[requestId] = UpdateRequest({
            key: key,
            requester: msg.sender,
            requestedAt: uint64(block.timestamp),
            fulfilledAt: 0,
            requestFeePaid: msg.value,
            status: RequestStatus.Pending,
            errorCode: 0
        });

        pendingRequestByKey[key] = requestId;

        emit UpdateRequested(requestId, key, msg.sender, symbol, timeWindow, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                        PUBLISHER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function fulfillRequest(
        uint256 requestId,
        uint32 negativeBps,
        uint32 neutralBps,
        uint32 positiveBps,
        uint64 dataTimestamp
    ) external onlyPublisher {
        UpdateRequest storage r = requests[requestId];

        if (r.status != RequestStatus.Pending) revert InvalidRequestStatus();

        if (uint256(negativeBps) + uint256(neutralBps) + uint256(positiveBps) != 10000) {
            revert InvalidBpsSum();
        }

        if (dataTimestamp == 0) revert InvalidTimestamp();

        if (dataTimestamp > block.timestamp + 10 minutes) revert InvalidTimestamp();

        latestFeeds[r.key] = SentimentData({
            negativeBps: negativeBps,
            neutralBps: neutralBps,
            positiveBps: positiveBps,
            dataTimestamp: dataTimestamp,
            updatedAt: uint64(block.timestamp),
            exists: true
        });

        r.status = RequestStatus.Fulfilled;
        r.fulfilledAt = uint64(block.timestamp);
        r.errorCode = 0;

        pendingRequestByKey[r.key] = 0;

        emit RequestFulfilled(
            requestId,
            r.key,
            negativeBps,
            neutralBps,
            positiveBps,
            dataTimestamp,
            uint64(block.timestamp)
        );
    }

    function failRequest(uint256 requestId, uint8 errorCode) external onlyPublisher {
        UpdateRequest storage r = requests[requestId];

        if (r.status != RequestStatus.Pending) revert InvalidRequestStatus();

        r.status = RequestStatus.Failed;
        r.fulfilledAt = uint64(block.timestamp);
        r.errorCode = errorCode;

        pendingRequestByKey[r.key] = 0;

        emit RequestFailed(requestId, r.key, errorCode);
    }

    /*//////////////////////////////////////////////////////////////
                           RECEIVE / FALLBACK
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}
}