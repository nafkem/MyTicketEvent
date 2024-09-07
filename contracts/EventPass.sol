// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// imports
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// errors
error NOT_ADMIN();
error INVALID_INPUT();
error INPUT_MISMATCH();
error INSUFFICIENT_AMOUNT();
error UNREGISTERED_USER();

/**
 * @dev EventContract is a contract that represents an event
 */
contract EventPass is ERC1155Supply, ERC1155Holder {
    
    event EventCreated(uint256 indexed eventId,string indexed eventNameE,address indexed organizer);
    event EventRescheduled(uint256 indexed eventId,uint256 date,uint256 startTime,uint256 endTime,
        bool virtualEvent, bool privateEvent);
    event EventCancelled(uint256 indexed eventId);
    event TicketPurchased(address indexed buyer,string eventNameE,uint256 indexed eventId,
        uint256 indexed ticketId);
    event TicketCreated(address indexed to,uint256 indexed id,uint256 quantity,uint256 indexed price);
    event TicketBurned(address indexed from, uint256 indexed ticketId, uint256 indexed amount);
    event TicketTransferred(address indexed from,address indexed to,uint256 indexed ticketId );

    // factoryContract address
    address factoryContract;

    struct EventDetails {
        uint256 eventId;
        address organizer;
        string eventName;
        string description;
        string eventAddress;
        uint256 date;
        uint256 startTime;
        uint256 endTime;
        bool virtualEvent;
        // bool privateEvent;
        uint256 totalTickets;
        uint256 soldTickets;
        bool isCancelled;
    }

    EventDetails public eventDetails;
    mapping(uint256 => uint256) ticketPricePerId;
    mapping(uint256 => uint256) soldTicketsPerId;
    mapping(uint256 => bool) ticketExists;
    uint256[] public createdTicketIds;

    // Mapping to store the amount of each ticket bought by each user
    mapping(address => TicketPurchase[]) public userTickets;
    mapping(address => uint256) public userTicketAmount;

    struct TicketPurchase {
        uint256 ticketId;
        uint256 amount;
    }

    event RefundClaimed(address indexed user, uint256 amount);

    constructor(
        uint256 _eventId,
        address _organizer,
        string memory _eventName,
        string memory _description,
        string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent
        //bool _privateEvent
    ) ERC1155("") {
     factoryContract = msg.sender;

        eventDetails = EventDetails({
            eventId: _eventId,
            organizer: _organizer,
            eventName: _eventName,
            description: _description,
            eventAddress: _eventAddress,
            date: _date,
            startTime: _startTime,
            endTime: _endTime,
            virtualEvent: _virtualEvent,
            //privateEvent: _privateEvent,
            totalTickets: 0,
            soldTickets: 0,
            isCancelled: false
        });

        emit EventCreated(
            eventDetails.eventId,
            eventDetails.eventName,
            eventDetails.organizer
        );

        _setApprovalForAll(address(this), factoryContract, true);
    }

    /**
     * @dev Restricts access to only the factoryContract
     */
    function onlyFactoryContract() private view {
        if (msg.sender != factoryContract) {
            revert NOT_ADMIN();
        }
    }

    function createEventTicket(
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        uint256[] calldata _price
    ) external {
        onlyFactoryContract();

        // mint tickets to the contract
        _mintBatch(address(this), _ticketId, _quantity, "");

        for (uint256 i; i < _ticketId.length; i++) {
            // stores the price of each ticket
            ticketPricePerId[_ticketId[i]] = _price[i];

            // track created tickets
            if (!ticketExists[_ticketId[i]]) {
                ticketExists[_ticketId[i]] = true;
                createdTicketIds.push(_ticketId[i]);
            }

            emit TicketCreated(
                address(this),
                _ticketId[i],
                _quantity[i],
                _price[i]
            );
        }
    }

    /**
     * @dev Returns created tickets
     * @return Array of created ticket IDs
     */
    function getCreatedTickets() external view returns (uint256[] memory) {
        return createdTicketIds;
    }

    /**
     * @dev Returns ticket price per ID
     * @return Ticket ID price
     */
    function getTicketIdPrice(
        uint256 _ticketId
    ) external view returns (uint256) {
        return ticketPricePerId[_ticketId];
    }

    /**
     * @dev Buy event tickets from the contract
     * @param _ticketId The ID of the ticket
     * @param _quantity The quantity of tickets to buy
     * @param _buyer The address of the buyer
     */
    function buyTicket(
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        address _buyer
    ) external {
        onlyFactoryContract();

        // sends event tickets to the buyer
        safeBatchTransferFrom(address(this), _buyer, _ticketId, _quantity, "");

        for (uint256 i = 0; i < _ticketId.length; i++) {
            soldTicketsPerId[_ticketId[i]] += _quantity[i];

            eventDetails.soldTickets += _quantity[i];

            emit TicketPurchased(
                _buyer,
                eventDetails.eventName,
                eventDetails.eventId,
                _ticketId[i]
            );
        }
    }

    function getEventDetails() external view returns (EventDetails memory) {
        return eventDetails;
    }
    function updateEventDetails(string memory _eventName,string memory _description,string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent
        //bool _privateEvent
    ) external {
        onlyFactoryContract();
        eventDetails.eventName = _eventName;
        eventDetails.description = _description;
        eventDetails.eventAddress = _eventAddress;
        eventDetails.date = _date;
        eventDetails.startTime = _startTime;
        eventDetails.endTime = _endTime;
        eventDetails.virtualEvent = _virtualEvent;
        //eventDetails.privateEvent = _privateEvent;
    }

    function cancelEvent() external {onlyFactoryContract();eventDetails.isCancelled = true;
        emit EventCancelled(eventDetails.eventId);
    }
    function setEventURI(string memory newUri_) external {onlyFactoryContract();
        _setURI(newUri_);
    }

    function supportsInterface(bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC1155Holder) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}