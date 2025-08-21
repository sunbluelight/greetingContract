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
        uint256 votes;
    }
    address candidateWithHighestVotes;
    uint256 highestVotes= 0;

    mapping (address => Candidate) public candidates; 
    mapping (address => bool) public voted;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "You must be the owner to perform this action.");
        _;
    }
    event VotedFor(address indexed user, string candidate);

    function addCandidate(address _address, string memory _name) public onlyOwner{
        require(bytes(candidates[_address].name).length == 0, "you can't add the same candidate twice"); 
        candidates[_address].name = _name;
        candidates[_address].votes = 0;
    }

    function vote(address _address) public {
        require(votingActive, "The voting was paused");
        require(!voted[msg.sender], "You can only vote once!");
        require(bytes(candidates[_address].name).length != 0, "The user you want to vote for is not a candidate!");
        
        candidates[_address].votes += 1;
        
        if(candidates[_address].votes > highestVotes){
            candidateWithHighestVotes = _address;
            highestVotes = candidates[_address].votes;
        }
        
        voted[msg.sender] = true;
        
        emit VotedFor(msg.sender, candidates[_address].name);
    }

    
    function pauseVoting() public onlyOwner{
        votingActive = false;
    }

    function continueVoting() public onlyOwner{
        votingActive = true;
    }
    
    function announceWinner() public view onlyOwner returns (string memory) {
        require(highestVotes > 0, "No votes cast yet");
        return string.concat(candidates[candidateWithHighestVotes].name, " IS THE WINNER!");
    }
}
