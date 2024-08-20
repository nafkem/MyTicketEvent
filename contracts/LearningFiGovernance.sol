// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LearningFiGovernance {


    // ============================
    // STATE VARIABLE
    // ============================

    uint ID = 1;
    uint public totalDAOMembers;
    uint public totalDAOFund;
    uint public totalVotingPower;
    uint public joinDAOMinimum;
    uint public joinDAOMaximum;
    uint totalGovernanceFee;
    address admin;
    address tokenAddress;
    address learningFiAddress;
    uint256 public Overflow = 0;

    struct GrantRequests {
        uint amountRequested;
        string title;
        string description;
        string institution;
        string imageIPFSHash;
        address student;
        uint requestDate;
        uint grantID;
        GrantStatus status;
        address[] membersvoted;
        uint totalVote;
        bool claimable;
    }


    struct DAOMembers {
        uint Amount;
        uint votePower;
        bool joined;
        uint dateJoined;
        uint newClaim;
        address memberAddress;
        uint percentageLevel;
    }
    enum GrantStatus {
        Pending,
        Approved,
        Denied,
        Closed,
        Executed
    }



    mapping (address => DAOMembers) MemberData;
    mapping(address => uint256) public studentMap;
    
    mapping (address => GrantRequests) public proposalByAddress;
    address[]  MembersOfDAO;
    DAOMembers[] AllMembers;
    mapping (uint => GrantRequests) Grants;
    mapping (address => GrantRequests) GrantsByAddress;
    GrantRequests[] allGrants;
    GrantRequests[] approvedGrants;


    
    // ============================
    // CONSTRUCTOR
    // ============================

    constructor (
        address _tokenAddress, 
        address _learningFiAddress,
        uint _minimumJoinDAO,
        uint _maximumJoinDAO) {
        admin = msg.sender;
        tokenAddress = _tokenAddress;
        learningFiAddress = _learningFiAddress;
        joinDAOMinimum = _minimumJoinDAO;
        joinDAOMaximum = _maximumJoinDAO;
    }


     // =============================
    //            EVENTS
    // ==============================

    event GrantRequested(uint256 indexed grantId,string description,address indexed student);
    event grantClosed(uint256 indexed grantId, GrantStatus indexed status);
    event JoinedDAO (address member, uint amount);


    // ******* //
    
     // WRITE FUNCTIONS
    
     // ******* //


    /// @notice Function is called to join the DAO
    /// @dev This funciton allows users to join DAO while depositing into the contract
    /// @param _joinAmount: This is the amount the user is wiling to useto join the DAO
  
    function joinDAO (
        uint _joinAmount
    ) 
        public 
    {   
        DAOMembers storage members = MemberData[msg.sender];
        require(members.joined == false, "You have already joined DAO");
        require(_joinAmount >= joinDAOMinimum && _joinAmount <= joinDAOMaximum, "You are not within the range of amount");
        bool deposited = deposit(_joinAmount);
        require(deposited == true, "Deposit couldn't join DAO");
        members.Amount += _joinAmount;
        members.joined = true;
        members.memberAddress = msg.sender;
        uint votingPower = votePower(_joinAmount) / 1e6;
        members.votePower = votingPower;
        AllMembers.push(members);
        totalDAOMembers++;  
        totalDAOFund += _joinAmount;
        members.dateJoined = block.timestamp;
        totalVotingPower += votingPower;
        MembersOfDAO.push(msg.sender);
        emit JoinedDAO (msg.sender, _joinAmount);
    }
   
    /// @notice Function is called to donate
    /// @dev This funciton allows users to donate for a grant
    /// @param _amount: This is the amount the user is wiling to donate
  
    function donate (
        uint _amount,
        uint256 _grantID
    ) 
        public 
    { 
        require(Grants[_grantID].claimable, "_grantId is not claimable");
        GrantRequests storage grant = Grants[_grantID];

        // Update student's balance
        studentMap[grant.student] += (98 * grant.amountRequested)/ 100;
        Overflow += (2  * grant.amountRequested) / 100;
        Overflow += _amount - grant.amountRequested; 

        

        if(studentMap[grant.student] >= grant.amountRequested){
            closeGrant(_grantID);
        }       
    }

    /// @notice This function is called by the DAO membes to vote 
    /// @dev This funciton is called there is a grant request by the LearningFi contract and users have to vote
    /// @param _id: This parameter is passed in to check the position of the vote to b voted

    function vote (
        uint _id) 
            public 
    {
        GrantRequests storage grant = Grants[_id];
        DAOMembers memory members = MemberData[msg.sender];
        require(members.joined == true, "You are not a member of the DAO");
        require(block.timestamp <= ( grant.requestDate + 2 days), "Voting time over");
        bool voted = checkIfVoted(msg.sender, _id);
        require(voted != true, "you can't vote twice");
        uint voteCount = members.Amount;
        grant.totalVote += voteCount;
        uint requiredVote = claimRequiredVoting();
        if (grant.totalVote >= requiredVote) {
            grant.claimable = true;
            approvedGrants.push(grant);
        }
    }

    
    /// @notice This function is called by the user to withdraw their claim
    /// @dev This funciton is called by the LearningFi contract for users to withdraw their grants
    /// @param _idGrantRequests: this is the ID of the Grant
    function userWithdrawGrant (
        uint _idGrantRequests) 
        public 
    {   
        onlyLearningFiContract();
        GrantRequests storage grant = Grants[_idGrantRequests];
        uint requiredVote = claimRequiredVoting();
        require(grant.claimable == true || grant.totalVote >= requiredVote, "You can't claim grant");
        uint _withdraw = grant.amountRequested;
        withdraw(grant.student, _withdraw);
        grant.amountRequested = 0;
    }

    /// @notice Function is called from the LearningFi contract when a request for Grant is made
    /// @dev This is funciton that allows the users from the LearningFi contract request for Grants
    /// @param _amount: This is the amount of Grant requested by the user
    /// @param _description: This is the reason given by the user to get their claims.

    function requestGrant (
        string memory _title, string memory _description, uint256 _amount,
        string memory _imageIPFSHash, string memory _institution, address _student)
        public 
    {
        onlyLearningFiContract();
        GrantRequests storage grant = Grants[ID];
        grant.grantID = ID;
        grant.amountRequested = _amount;
        grant.description = _description;
        grant.title = _title;
        grant.imageIPFSHash = _imageIPFSHash;
        grant.institution = _institution;
        grant.requestDate = block.timestamp;
        grant.student = _student;
        allGrants.push(grant);
        ID++;

        emit GrantRequested(grant.grantID, _description, msg.sender);
    }

    /// @notice Function is called by the DAO members to withdraw their funds
    /// @dev This function is called by the members of the DAO to withdraw their funds from the DAO 
    function memberWithdrawFunds
        () 
        public
    {
        DAOMembers storage member = MemberData[msg.sender];
        require(block.timestamp >= (member.dateJoined + 30 days), "You can't wihdraw now");
        uint _withdraw = member.Amount;
        member.Amount = 0;
        member.votePower = 0;
        member.dateJoined = 0;
        bool withdrawn = withdraw(msg.sender, _withdraw);
        require (withdrawn == true, "Couldn't withdraw the fund");
    } 

    /// @notice Function is called by members of the Governance withdraw claims from the Grant Fee as a reward
    /// @dev Only DAO members can cal this function 
    function claimGovernanceFee ()
        public 
    {
        DAOMembers storage member = MemberData[msg.sender];
        require(block.timestamp >= member.newClaim, "You can't claim now");
        uint bal = member.Amount;
        uint feeClaimable= (bal * totalGovernanceFee) / totalDAOFund;
        member.newClaim += block.timestamp + 30 days;
        bool claimed = withdraw(msg.sender, feeClaimable);
        require(claimed == true, "You couldn't claim fee");

    }

    /// @notice Function is called by the LearnFi contract for deposit of the Grant Fee to the DAO
    /// @dev Only the Learning contract can call this funcion  
    function depositGovernanceFee (
        uint _amount
    ) 
        external 
    {
        onlyLearningFiContract();
        bool deposited = deposit(_amount);
        require (deposited == true, "Governance fee not deposited");
        totalGovernanceFee += _amount;
    }

     /// @dev This function is used to set the minmum amount to join the DAO
    function setMinimumToJoinDAO ( uint _minimumJoinDAO) 
        public 
    { 
        onlyAdmin();
        joinDAOMinimum = _minimumJoinDAO;
    }

     /// @dev This function is used to set the maximum to join the DAO and can only be calld by the admin 
    function setMaximumToJoinDAO (uint _maximumJoinDAO)
        public
    {
        onlyAdmin();
        joinDAOMaximum = _maximumJoinDAO;
    }

    function withdrawCustomTokens(
        uint _amount,
        address _tokenAddress,
        address _withDrawTo)
        external
    {
        onlyAdmin();
        IERC20(_tokenAddress).transfer(_withDrawTo, _amount);
    }

   
    // ******* //
    // VIEW FUNCTIONS
    // ******* //

    /// @dev This is an intenal function used to calculate the vote power of the DAO members
    function votePower (uint bal) internal view returns (uint power) {
        power = (bal * 1e6)/joinDAOMinimum;
    }

    function DaoMemberPercentage(uint _amount) internal view returns(uint dmp) {
        uint contractBal = IERC20(tokenAddress).balanceOf(address(this));
        dmp = (_amount)/(contractBal + _amount);
    }

    /// @dev Used to check the if the DAO member has voted for a particular claim
    function checkIfVoted (
        address _member,
        uint _id) 
        internal 
        view
        returns (bool status)
    {
        address[] memory voters = Grants[_id].membersvoted;
        for (uint i = 0; i <  voters.length; i++) {
            if (voters[i] == _member) {
                status = true;
            }
        }
    }

     /// @dev This is a view function that returns the minimum for a vote to pass and a user to get his claim 
     function claimRequiredVoting () public view returns(uint result) {
        result = (60 * totalVotingPower) / 100;
    }

    // @dev this function is to add and register student to the student map
    function registerStudent(address _student, string memory _imageIPFSHash) external {
        GrantRequests storage grant = GrantsByAddress[_student];
        grant.imageIPFSHash = _imageIPFSHash;
        grant.student = _student;
    }

    /// @dev This function is used to view all the clams inthe contarct 
    function viewAllGrantRequests () 
        public 
        view 
        returns
        (GrantRequests[] memory)
    {
        return allGrants;
    }
    
    /// @dev This function is used to view all the clams inthe contarct 
    function viewAllApprovedGrants () 
        public 
        view 
        returns
        (GrantRequests[] memory)
    {
        return approvedGrants;
    }

    function viewGrantStatus(
        uint256 _grantID
    ) external view returns (GrantStatus) {
        require(_grantID < ID - 1, "Invalid grant ID");
        return allGrants[_grantID].status;
    }

    /// @dev This function is used to view all the DAO members 
    function viewAllDAOMembers ()
        public 
        view
        returns
        (DAOMembers[] memory)
    {
        return AllMembers;
    }

    /// @dev Each member of the DAO can call this function to view their data
    function memberViewData 
        (address _memberAddress)
        public 
        view
        returns
        (DAOMembers memory)
    {
        DAOMembers memory member = MemberData[_memberAddress];
        return member;
    }

    /// @dev This function is used to view each claim data
    function viewIndividualClaim
        (uint _grantID) 
        public
        view 
        returns
        (GrantRequests memory)
    {
        GrantRequests memory grant = allGrants[_grantID];
        return grant;
    }


    // ******* //
    // INTERNAL FUNCTIONS
    // ******* //

     /// @notice Function to deposit ERC20 token into the contract 
    /// @dev This is an internal funcion called by different functions to deposit ERC20 token into the contract 
    /// @return sent the return variables of a contract’s function state variable
     function deposit(
        uint _amount) 
         internal 
         returns (bool sent)
    {
        amountMustBeGreaterThanZero(_amount);
        sent = IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw (
        address _to,
        uint _amount)
        private
        returns (bool sent)
    {
        amountMustBeGreaterThanZero(_amount);
        sent = IERC20(tokenAddress).transfer(_to, _amount);
    }

    function closeGrant(uint256 _grantID) internal  {
        onlyLearningFiContract();
        GrantRequests storage grant = Grants[_grantID];

        require(
            grant.status == GrantStatus.Approved ||
                grant.status == GrantStatus.Denied,
            "Invalid grant status"
        );
        grant.status = GrantStatus.Closed;
        emit grantClosed(_grantID, GrantStatus.Closed);
    }


    /// @notice this is the internal function used to check that amount must be greater than zero
    /// @param _amount: this is the amount you want to check
    function amountMustBeGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "Amount must be greater than zero");
    }

    function onlyLearningFiContract () internal view{
        require (msg.sender == learningFiAddress, "Only LearningFi contract can call this function");
    }

    /// @dev This is a private function used to allow only an admin call a function
    function onlyAdmin () 
        private 
        view
    {
        require(msg.sender == admin, "Not admin");
    }
  
 
}