// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "./interface/IGovernance.sol";

contract LearningFi is Pausable, ReentrancyGuard, Ownable {
    IERC20 private _nativeToken;
    IPool private _aavePool;
    address public governanceAddress;
    address public admin;
    uint256 public proposalCount;
    uint256 public proposalDeadline;
    uint256 public maxGrant = 1000;
    uint256 public maxLoan = 1000;
    uint256 public Overflow = 0;
    uint256 public ID = 0;

    struct Student {
        uint256 id;
        address student;
        string transcript;
        bool inDept;
    }

    Student[] public students;
    mapping(address => bool) public isStudent;
    mapping(address => bool) public revoked;
    mapping(address => uint256) public studentMap;

    event StudentRegistered(
        address indexed student,
        string indexed imageIPFSHash
    );
    // event Status(uint256 indexed proposalId, ProposalStatus indexed status);
    // event ProposalClosed(uint256 indexed proposalId,ProposalStatus indexed status);
    // event ProposalExecuted(uint256 indexed proposalId,ProposalStatus indexed status);
    event Donation(address indexed donor, uint256 amount, uint256 timestamp);
    event Revoked(address indexed studentAddress, uint256 timestamp);
    event RegistrationError(address indexed student, string reason);
    event RegistrationErrorBytes(address indexed student, bytes lowLevelData);

    modifier validStudent() {
        require(isStudent[msg.sender], "Not a student");
        _;
    }

    modifier notRevoked() {
        require(!revoked[msg.sender], "Revoked");
        _;
    }

    modifier onlyOwnerOrEscrow() {
        require(
            msg.sender == owner() || msg.sender == address(this),
            "Not authorized"
        );
        _;
    }

    constructor(
        address nativeToken,
        address aavePoolAddress
    ) Ownable(msg.sender) {
        _nativeToken = IERC20(nativeToken);
        _aavePool = IPool(aavePoolAddress);
        admin = msg.sender;
    }

    receive() external payable {}

    function registerStudent(
        address _student,
        string memory _imageIPFSHash
    ) external {
        require(!isStudent[_student], "Student is already registered");
        require(
            bytes(_imageIPFSHash).length > 0,
            "Image IPFS hash must not be empty"
        );
        isStudent[_student] = true;
        Student memory student = Student({
            id: ID,
            student: _student,
            transcript: _imageIPFSHash,
            inDept: false
        });
        students.push(student);
        ID++;

        try
            IGovernance(governanceAddress).registerStudent(
                _student,
                _imageIPFSHash
            )
        {
            emit StudentRegistered(_student, _imageIPFSHash);
        } catch Error(string memory reason) {
            // Log the error reason
            emit RegistrationError(_student, reason);
            revert(reason);
        } catch (bytes memory lowLevelData) {
            // Log the low-level error data
            emit RegistrationErrorBytes(_student, lowLevelData);
            revert("Unexpected error in governance contract");
        }
    }

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _amount,
        string memory _imageIPFSHash,
        string memory _institution
    ) external payable validStudent {
        require(!revoked[msg.sender], "You are revoked due to offence");
        require(_amount <= maxGrant, "Amount above budget");
        IGovernance(governanceAddress).requestGrant(
            _title,
            _description,
            _amount,
            _imageIPFSHash,
            _institution,
            msg.sender
        );
        proposalCount++;
    }

    function getStudents() external view returns (Student[] memory) {
        return students;
    }

    function setMaxLoan(uint256 _Amount) external onlyOwner {
        maxLoan = _Amount;
    }

    function setMaxGrant(uint256 _Amount) external onlyOwner {
        maxGrant = _Amount;
    }

    function donate(uint256 _amount, uint256 _grantID) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(
            _nativeToken.balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );
        uint256 tokenAmount = _amount * 10 ** 18;
        // Transfer tokens from the sender to this contract
        require(
            _nativeToken.transferFrom(msg.sender, address(this), tokenAmount),
            "Token transfer failed"
        );

        // Update student's balance
        IGovernance(governanceAddress).donate(_amount, _grantID);
        emit Donation(msg.sender, tokenAmount, block.timestamp);
    }

    function revokeStudent(address _studentId) external onlyOwner {
        require(isStudent[_studentId], "Not a student");
        isStudent[_studentId] = false;

        emit Revoked(_studentId, block.timestamp);
    }

    function toggleRevokedStatus(address _studentAddress) external onlyOwner {
        revoked[_studentAddress] = !revoked[_studentAddress];
        emit Revoked(_studentAddress, block.timestamp);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function rewardNFT(
        address _recipient,
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyOwner {
        //_nftContract.mint(_recipient, _tokenId);
        //_nftContract.setTokenURI(_tokenId, _tokenURI);
    }

    // Aave functions

    function supplyToAave(address asset, uint256 amount) external onlyOwner {
        IERC20(asset).approve(address(_aavePool), amount);
        _aavePool.supply(asset, amount, address(this), 0);
    }

    function borrowFromAave(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external onlyOwner {
        _aavePool.borrow(asset, amount, interestRateMode, 0, address(this));
    }

    function repayAaveLoan(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external onlyOwner {
        IERC20(asset).approve(address(_aavePool), amount);
        _aavePool.repay(asset, amount, interestRateMode, address(this));
    }

    function withdrawFromAave(
        address asset,
        uint256 amount
    ) external onlyOwner {
        _aavePool.withdraw(asset, amount, address(this));
    }

    function setGovernanceAddress(address _governanceAddress) external {
        onlyAdmin();
        addressZeroCheck(_governanceAddress);
        governanceAddress = _governanceAddress;
    }

    function setAdminAddress(address _adminAddress) external onlyOwner {
        addressZeroCheck(_adminAddress);
        admin = _adminAddress;
    }

    /// @dev This is a private function used to allow only an admin call a function
    function onlyAdmin() private view {
        require(msg.sender == admin, "Not admin");
    }

    /// @dev This is a private funcion used to check for address zero
    function addressZeroCheck(address depositAddress) private pure {
        require(depositAddress != address(0));
    }

    /// @notice this is the internal function used to check that address must be greater than zero
    /// @param _amount: this is the amount you want to check
    function amountMustBeGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "Amount must be greater than zero");
    }
}
