// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

contract Auction is Ownable, ReentrancyGuard{
    uint256 public currentAuction = 0 ; 
    uint256 public itemCount = 0;
    uint256 public firstItemIndex = 0;
    string[] public itemNames;
    mapping (string itemName => Item item) public items;
    mapping (address bidder => mapping (string itemName => uint256 amount)) public previousBids;
    struct Item {
        uint256 index;
        uint256 highestBid;
        address highestBidder;
        bool auctionClosed;
        uint256 endOfAuction;

    }

    event auctionState(string text, uint256 indexed auctionIndex);
    event newBid(uint256 indexed index, string itemName, uint256 amount);
    
    /// @dev start the auction
    function startAuction() public onlyOwner{
        currentAuction +=1;
        firstItemIndex = itemCount;
        emit auctionState("new auction have started!", currentAuction);
    }

    /// @dev add item to the auction, and set item informations 
    function addItem(string calldata _itemName, uint256 _endOfAuction, uint256 startingBid)public onlyOwner{
        require(startingBid <= 1 ether);
        require(_endOfAuction > block.timestamp);
        items[_itemName].endOfAuction = _endOfAuction;
        items[_itemName].index = itemCount;
        items[_itemName].highestBid = startingBid;
        items[_itemName].highestBidder = owner;
        items[_itemName].auctionClosed = false;
        itemCount += 1;
        // put all the item names into an array 
        itemNames.push(_itemName); 
    }

    /// @dev bid for an item
    function bid(string calldata _itemName) public payable{
        require(items[_itemName].index < itemCount , "Item does not exist");
        require(items[_itemName].auctionClosed == false, "Auction was closed");
        require(msg.value >= items[_itemName].highestBid, "Bid too low");
        /// @dev update the bidder information
        if(items[_itemName].highestBidder != owner){
            previousBids[items[_itemName].highestBidder][_itemName] += items[_itemName].highestBid;
        }
        items[_itemName].highestBidder = msg.sender;
        items[_itemName].highestBid = msg.value;
    
        emit newBid(currentAuction, _itemName, msg.value);
    }
    event (address bidder, string itemName, uint256 amount)haveWithdrawn;
    function withdraw(string calldata _itemName) public nonReentrant{
        uint256 temp = previousBids[msg.sender][_itemName];
        require(temp > 0, "No funds to withdraw");
        previousBids[msg.sender][_itemName] = 0;
        payable(msg.sender).transfer(temp);
        emit haveWithdrawn(msg.sender, _itemName, temp);
    } 
    
    /// @dev shows the current highest bidder for a certain item
    function currentHighest(string calldata _itemName)public view returns(uint256){
        return items[_itemName].highestBid;       
    } 

    /// @dev this function ends the auction and announces the last bids for all the items   
    function endAuction(string calldata _itemName) public onlyOwner {
        require(items[_itemName].auctionClosed == false, string.concat("Auction for ", _itemName ,"has already ended"));
        require(block.timestamp > items[_itemName].endOfAuction, string.concat("Auction for", _itemName, "hasn't ended yet"));
        items[_itemName].auctionClosed = true;
        emit auctionState(string.concat("the Auction for ", _itemName," has ended"), currentAuction);
    }

    function highestBidForItem(string calldata _itemName) public view returns(address, uint256){
        return (items[_itemName].highestBidder, items[_itemName].highestBid);
    }
}
