// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Ownable{
    address owner;

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner, "you are not the owner");
        _;
    }
}


contract Storage is Ownable {
    string public name;
    string private temp;

    /// @notice strings cant be indexed because they are arrays 
    event changed(string from, string to, uint256 indexed at);
    
    function setStorage(string calldata _name) public payable onlyOwner{
        require(msg.value > 1 ether, "incefficient Ether");
        name = _name;
        emit changed("none", name, block.timestamp);
    } 
    
    
    /// @notice calldata is used because we dont need to change _name inside the function
    function changeStorage(string calldata _name) public onlyOwner returns(string memory prevValue){
        temp = name;
        name = _name;
        emit changed(temp, name, block.timestamp);

        /// @dev frontend developers might need previous name 
        return temp;
    }

    function viewStorage() public view returns(string memory){
        return name;
    } 
 
}
