// SPDX-License-Identifier: HF
pragma solidity ^0.8.1;

/*
Feel free to create your own functions and interact with them in JavaScript
DO NOT CHANGE THE FUNCTION DEFINITIONS OF ANY OF THE FUNCTIONS ALREADY DEFINED BELOW

THE ONLY FUNCTION YOU ARE ALLOWED THE CHANGE THE DEFINITION OF IS getResults().
You will probably need to change that.
*/

contract DoubleAuction 
{
    uint constant private maxSize = 20; //maximum number of bids
    uint constant private AuctionInterval = 30; //time in seconds. Contract shouldn't be called faster than this

    struct Bid {
        address addr;
        uint quantity;
        uint price;
    }

    Bid[] public buyers;
    Bid[] public sellers;
    uint public lastAuctionTime;

    // Arrays to store the results of the latest successful auction
    address[] public resBuyers;
    address[] public resSellers;
    uint[] public resQuantities;
    uint public resClearingPrice;

    // Helper to check if an address has already placed a bid in this interval
    function hasBid(address _addr) private view returns (bool) {
        for(uint i = 0; i < buyers.length; i++) {
            if(buyers[i].addr == _addr) return true;
        }
        for(uint i = 0; i < sellers.length; i++) {
            if(sellers[i].addr == _addr) return true;
        }
        return false;
    }

    function addBuyer(uint quantity, uint price) public
    {
        require(!hasBid(msg.sender), "You have already placed a bid in this interval");
        require(buyers.length < maxSize, "Maximum number of buyers reached");
        require(msg.sender.balance >= quantity * price, "Insufficient balance to cover this bid");
        
        buyers.push(Bid(msg.sender, quantity, price));
    } 
   
    function addSeller(uint quantity, uint price) public
    {
        require(!hasBid(msg.sender), "You have already placed a bid in this interval");
        require(sellers.length < maxSize, "Maximum number of sellers reached");

        sellers.push(Bid(msg.sender, quantity, price));
    } 
    
    // Helper to sort the arrays: Buyers (Descending), Sellers (Ascending)
    function sortBids() private {
        for(uint i = 0; i < buyers.length; i++) {
            for(uint j = i + 1; j < buyers.length; j++) {
                if(buyers[j].price > buyers[i].price) {
                    Bid memory temp = buyers[i];
                    buyers[i] = buyers[j];
                    buyers[j] = temp;
                }
            }
        }
        for(uint i = 0; i < sellers.length; i++) {
            for(uint j = i + 1; j < sellers.length; j++) {
                if(sellers[j].price < sellers[i].price) {
                    Bid memory temp = sellers[i];
                    sellers[i] = sellers[j];
                    sellers[j] = temp;
                }
            }
        }
    }

    function doubleAuction() public 
    {
        require(block.timestamp >= lastAuctionTime + AuctionInterval, "Auction interval has not passed yet");
        lastAuctionTime = block.timestamp;

        sortBids();

        uint minLen = buyers.length < sellers.length ? buyers.length : sellers.length;
        bool matchFound = false;
        uint k = 0;

        // Find the breakeven index k where bk >= sk
        for(uint i = 0; i < minLen; i++) {
            if(buyers[i].price >= sellers[i].price) {
                matchFound = true;
                k = i;
            } else {
                break;
            }
        }

        // Clear previous results
        delete resBuyers;
        delete resSellers;
        delete resQuantities;
        resClearingPrice = 0;

        // If a match is found, record the transactions
        if(matchFound) {
            resClearingPrice = (buyers[k].price + sellers[k].price) / 2;
            for(uint i = 0; i <= k; i++) {
                resBuyers.push(buyers[i].addr);
                resSellers.push(sellers[i].addr);
                
                // Keep the quantity as the minimum of the buyer’s and seller’s quantity
                uint q = buyers[i].quantity < sellers[i].quantity ? buyers[i].quantity : sellers[i].quantity;
                resQuantities.push(q);
            }
        }

        // Clear the current bids for the next interval
        delete buyers;
        delete sellers;
    }

    // Changed the definition strictly according to instructions to return the latest results
    function getResults() public view returns(address[] memory, address[] memory, uint[] memory, uint)
    {
        return (resBuyers, resSellers, resQuantities, resClearingPrice);
    }    
}