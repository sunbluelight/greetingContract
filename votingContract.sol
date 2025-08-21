// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract simpleVotingContract{
    bool votingActive = true; 
    address public owner; 

    constructor(){
        owner = msg.sender;
    }
    
    struct Candidate{
        string name;
        uint32 votes;
    }
    address candidateWithHighestVotes;
    uint32 highestVotes= 0;

    mapping (address => Candidate) public candidates; 
    mapping (address => bool) public voted;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "You must be the owner to perform this action.");
        _;
    }
    
    uint32 public startTime;
    uint32 public endTime;
    
    event votedFor(bytes32 indexed user, string candidate);
    event candidatesUpdate(string candidate, string update);
    event votingState(string state);

    function addCandidate(address _address, string memory _name) external onlyOwner{
        require(bytes(candidates[_address].name).length == 0, "you can't add the same candidate twice"); 
        candidates[_address].name = _name;
        candidates[_address].votes = 0;
        emit candidatesUpdate(_name , " has been added.");
    }

    function removeCandidate(address _address) external onlyOwner{
        require(bytes(candidates[_address].name).length != 0, "you can't remove a candidate that doesn't exist"); 
        emit candidatesUpdate(candidates[_address].name , " has been removed.");
        candidates[_address].name = "";
        candidates[_address].votes = 0;
    }

    function vote(address _address) external {
        require(startTime < block.timestamp && endTime > block.timestamp, "The voting phase has ended");
        require(votingActive, "The voting was paused");
        require(!voted[msg.sender], "You can only vote once!");
        require(bytes(candidates[_address].name).length != 0, "The user you want to vote for is not a candidate!");
        
        candidates[_address].votes += 1;
        
        if(candidates[_address].votes > highestVotes){
            candidateWithHighestVotes = _address;
            highestVotes = candidates[_address].votes;
        }
        
        voted[msg.sender] = true;
        bytes32 hashedVoter = keccak256(abi.encodePacked(msg.sender));
        emit votedFor(hashedVoter, candidates[_address].name);
    }

    function setTimeStamp(uint32 _startTime, uint32 _endTime) public onlyOwner{
        require(_startTime < _endTime);
        startTime = _startTime;
        endTime = _endTime;
    }
    
    function pauseVoting() public onlyOwner{
        votingActive = false;
        emit votingState("Voting has been paused!");
    }

    function continueVoting() public onlyOwner{
        votingActive = true;
        emit votingState("Voting has been continued!");

    }
    
    function announceWinner() external onlyOwner returns (string memory) {
        require(endTime <= block.timestamp, "The voting is still going");
        require(highestVotes > 0, "No votes cast yet");
        emit votingState("Voting has ended!");
        return string.concat(candidates[candidateWithHighestVotes].name, " IS THE WINNER!");

    }
}
