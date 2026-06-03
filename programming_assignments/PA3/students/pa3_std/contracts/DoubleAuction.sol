// SPDX-License-Identifier: HF
pragma solidity ^0.8.1;

contract DoubleAuction 
{
    uint private constant MAX_SIZE = 20;
    uint private constant AUCTION_INTERVAL = 30;

    struct Bid {
        address bidder;
        uint quantity;
        uint price;
    }

    Bid[] private buyers;
    Bid[] private sellers;

    address[] private resultSellers;
    address[] private resultBuyers;
    uint[] private resultPrices;
    uint[] private resultQuantities;

    mapping(address => bool) private alreadyBid;
    address[] private intervalBidders;

    uint private lastAuctionTime;
    bool private auctionHasRun;

    constructor(uint initVal) {
        initVal;
    }

    function addBuyer(uint quantity, uint price) public {
        require(quantity > 0);
        require(price > 0);
        require(buyers.length < MAX_SIZE);
        require(!alreadyBid[msg.sender]);

        buyers.push(Bid(msg.sender, quantity, price));
        alreadyBid[msg.sender] = true;
        intervalBidders.push(msg.sender);
    }

    function addSeller(uint quantity, uint price) public {
        require(quantity > 0);
        require(price > 0);
        require(sellers.length < MAX_SIZE);
        require(!alreadyBid[msg.sender]);

        sellers.push(Bid(msg.sender, quantity, price));
        alreadyBid[msg.sender] = true;
        intervalBidders.push(msg.sender);
    }

    function doubleAuction() public {
        require(!auctionHasRun || block.timestamp >= lastAuctionTime + AUCTION_INTERVAL);

        delete resultSellers;
        delete resultBuyers;
        delete resultPrices;
        delete resultQuantities;

        sortSellers();
        sortBuyers();

        uint len = buyers.length < sellers.length ? buyers.length : sellers.length;
        uint matchCount = 0;

        for (uint i = 0; i < len; i++) {
            if (buyers[i].price >= sellers[i].price) {
                matchCount++;
            } else {
                break;
            }
        }

        if (matchCount > 0) {
            uint k = matchCount - 1;
            uint clearingPrice = (buyers[k].price + sellers[k].price) / 2;

            for (uint i = 0; i < matchCount; i++) {
                resultSellers.push(sellers[i].bidder);
                resultBuyers.push(buyers[i].bidder);
                resultPrices.push(clearingPrice);

                if (buyers[i].quantity < sellers[i].quantity) {
                    resultQuantities.push(buyers[i].quantity);
                } else {
                    resultQuantities.push(sellers[i].quantity);
                }
            }
        }

        lastAuctionTime = block.timestamp;
        auctionHasRun = true;

        clearBids();
    }

    function getResults()
        public
        view
        returns (
            address[] memory sellAddresses,
            address[] memory buyAddresses,
            uint[] memory clearingPrices,
            uint[] memory quantities
        )
    {
        return (resultSellers, resultBuyers, resultPrices, resultQuantities);
    }

    function sortSellers() private {
        for (uint i = 0; i < sellers.length; i++) {
            for (uint j = i + 1; j < sellers.length; j++) {
                if (sellers[j].price < sellers[i].price) {
                    Bid memory temp = sellers[i];
                    sellers[i] = sellers[j];
                    sellers[j] = temp;
                }
            }
        }
    }

    function sortBuyers() private {
        for (uint i = 0; i < buyers.length; i++) {
            for (uint j = i + 1; j < buyers.length; j++) {
                if (buyers[j].price > buyers[i].price) {
                    Bid memory temp = buyers[i];
                    buyers[i] = buyers[j];
                    buyers[j] = temp;
                }
            }
        }
    }

    function clearBids() private {
        delete buyers;
        delete sellers;

        for (uint i = 0; i < intervalBidders.length; i++) {
            alreadyBid[intervalBidders[i]] = false;
        }

        delete intervalBidders;
    }
}