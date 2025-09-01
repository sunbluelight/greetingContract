// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract MultiSigWallet is ReentrancyGuard{
    address contractOwner;

    address[] public owners;
    transaction[] public transactions;
    
    mapping (address => bool) public isOwner;
    mapping (address => mapping(uint256 => bool))alreadyConfirmed;
    mapping ( address => uint256)admissions;
    mapping ( address => mapping(address => bool)) public agreedToAddOwner;

    event ownerAdded(address newOwner);
    event transactionCreated(uint256 transactionId);
    event transactionConfirmed(uint256 transactionId, address owner);
    event transactionRevoked(uint256 transactionId, address owner);
    event transactionExecuted(uint256 transactionId);

    struct transaction{
        address to;
        uint256 value;
        bytes data;
        uint256 numConfirmations;
        uint256 N;
        bool executed;
    }

    modifier onlyContractOwner{
        require(msg.sender == contractOwner, "you are not the owner");
        _;
    }
    modifier onlyOwner{
        require(isOwner[msg.sender], "Not owner");
        _;
    }
    
    constructor(address[] memory _owners){
        contractOwner = msg.sender;
        for(uint256 i = 0; i < _owners.length; i++){
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
    }


    function addNewOwner(address _newOwner) public onlyOwner nonReentrant{
        require(!agreedToAddOwner[msg.sender][_newOwner]);
        require(!isOwner[_newOwner]);
        require(_newOwner != address(0));
        admissions[_newOwner]++;
        if(admissions[_newOwner] == owners.length) {
            owners.push(_newOwner);
            isOwner[_newOwner] = true;
            emit ownerAdded(_newOwner);
        }
        agreedToAddOwner[msg.sender][_newOwner] = true;
    }   
    

    function submitTransaction(address _to, uint256 _value, bytes calldata _data, uint256 _N) public onlyOwner nonReentrant{
        require(_N > 0 && _N <= owners.length, "Invalid N");
        require(_to != address(0));
        transactions.push(transaction(_to, _value, _data, 0,_N, false));
        emit transactionCreated(transactions.length-1);
    }

    function changeN(uint256 _transactionId, uint256 _N)public onlyContractOwner nonReentrant{
        require(_N > 0 && _N <= owners.length, "Invalid N");
        transactions[_transactionId].N = _N;
    }

    function confirmTransaction(uint256 _transactionId) public onlyOwner nonReentrant{
        require(!transactions[_transactionId].executed, "Transaction already executed");
        require(!alreadyConfirmed[msg.sender][_transactionId], "Already confirmed");
        transactions[_transactionId].numConfirmations++;
        alreadyConfirmed[msg.sender][_transactionId] = true;
        emit transactionConfirmed(_transactionId, msg.sender);
    }

    function revokeConfirmation(uint256 _transactionId) public onlyOwner nonReentrant{
        require(!transactions[_transactionId].executed, "Transaction already executed");
        require(alreadyConfirmed[msg.sender][_transactionId], "Haven't confirmed");
        transactions[_transactionId].numConfirmations--;
        alreadyConfirmed[msg.sender][_transactionId] = false;
        emit transactionRevoked(_transactionId, msg.sender);
    }

    function execute(uint256 _transactionId) public onlyContractOwner nonReentrant{
        require(transactions[_transactionId].executed == false, "Transaction already executed");
        require(transactions[_transactionId].numConfirmations >= transactions[_transactionId].N, "Not enough confirmations");
        transactions[_transactionId].executed = true;
        (bool success, ) = (transactions[_transactionId].to).call{value: transactions[_transactionId].value}(transactions[_transactionId].data);
        require(success, "Transaction failed");
        transactions[_transactionId].numConfirmations = 0;
        emit transactionExecuted(_transactionId);
    }

    // getter functions 
    function getOwners() public view returns(address[] memory){
        return owners;
    }

    function getTransaction(uint256 _transactionId) public view returns(address, uint256, bytes memory, uint256, uint256, bool){
        transaction memory t = transactions[_transactionId];
        return (t.to, t.value, t.data, t.numConfirmations, t.N, t.executed);
    }

    function getTransactionCount() public view returns(uint256){
        return transactions.length;
    }

    receive() external payable {
        payable(contractOwner).transfer(msg.value);
     }
    fallback() external payable {
        require(isOwner[msg.sender]);
        payable(contractOwner).transfer(address(this).balance);
    }
}
