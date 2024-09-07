// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract EventPassFactory is AccessControl, ReentrancyGuard {
    
    event EventCreated(uint256 indexed eventId, string indexed eventName, address indexed organizer);
    event EventRescheduled(uint256 indexed eventId, uint256 date, uint256 startTime, uint256 endTime,
        bool virtualEvent, bool privateEvent);
    event EventCancelled(uint256 indexed eventId);
    event AddOrganizer(uint256 indexed eventId, address indexed newOrganizer);
    event RemoveOrganizer(uint256 indexed eventId, address indexed removedOrganizer);

    struct EventDetails {
        string eventName;
        string description;
        string eventAddress;
        uint256 date;
        uint256 startTime;
        uint256 endTime;
        bool virtualEvent;
        bool privateEvent;
        address organizer;
    }

    uint256 public eventId;
    mapping(uint256 => EventDetails) public eventMapping;

    function createNewEvent(
        string memory _eventName,
        string memory _description,
        string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent,
        bool _privateEvent
    ) external {
        eventId++;
        EventDetails memory newEvent = EventDetails({
            eventName: _eventName,
            description: _description,
            eventAddress: _eventAddress,
            date: _date,
            startTime: _startTime,
            endTime: _endTime,
            virtualEvent: _virtualEvent,
            privateEvent: _privateEvent,
            organizer: msg.sender
        });

        eventMapping[eventId] = newEvent;

        // Grant roles
        bytes32 defaultEventIdRole = keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", eventId));
        bytes32 eventIdRole = keccak256(abi.encodePacked("EVENT_ORGANIZER", eventId));
        _grantRole(defaultEventIdRole, msg.sender);
        _grantRole(eventIdRole, msg.sender);

        emit EventCreated(eventId, _eventName, msg.sender);
    }

    function addEventOrganizer(uint256 _eventId, address _newOrganizer) external onlyRole(
        keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", _eventId))
    ) {
        bytes32 eventIdRole = keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId));
        _grantRole(eventIdRole, _newOrganizer);

        emit AddOrganizer(_eventId, _newOrganizer);
    }

    function removeOrganizer(uint256 _eventId, address _removedOrganizer) external onlyRole(
        keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", _eventId))
    ) {
        bytes32 eventIdRole = keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId));
        _revokeRole(eventIdRole, _removedOrganizer);

        emit RemoveOrganizer(_eventId, _removedOrganizer);
    }

    function updateEvent(
        uint256 _eventId,
        string memory _eventName,
        string memory _description,
        string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent,
        bool _privateEvent
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        // Ensure event exists
        require(eventMapping[_eventId].organizer != address(0), "Event does not exist");

        // Check if the event is in the future
        require(block.timestamp < _startTime, "Event must be in the future");

        // Update event details
        EventDetails storage eventDetails = eventMapping[_eventId];
        eventDetails.eventName = _eventName;
        eventDetails.description = _description;
        eventDetails.eventAddress = _eventAddress;
        eventDetails.date = _date;
        eventDetails.startTime = _startTime;
        eventDetails.endTime = _endTime;
        eventDetails.virtualEvent = _virtualEvent;
        eventDetails.privateEvent = _privateEvent;

        emit EventRescheduled(
            _eventId,
            _date,
            _startTime,
            _endTime,
            _virtualEvent,
            _privateEvent
        );
    }

    function cancelEvent(uint256 _eventId)
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        require(eventMapping[_eventId].organizer != address(0), "Event does not exist");

        delete eventMapping[_eventId];

        emit EventCancelled(_eventId);
    }

    function getEventDetails(uint256 _eventId) external view returns (EventDetails memory) {
        return eventMapping[_eventId];
    }

    // Other functions like createEventTicket, buyTicket, balanceOfTickets, etc., would also be modified to use this struct
}
