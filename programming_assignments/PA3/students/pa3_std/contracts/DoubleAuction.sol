// SPDX-License-Identifier: HF
pragma solidity ^0.8.1;

contract DoubleAuction {
    struct Bid {
        address user;
        uint q;
        uint v;
    }

    Bid[] buyers;
    Bid[] sellers;

    address[] resultSellers;
    address[] resultBuyers;
    uint[] resultPrices;
    uint[] resultQuantities;

    mapping(address => bool) used;
    address[] usedList;

    uint lastAuctionTime;
    bool auctionRan;

    constructor(uint initVal) {
        initVal;
    }

    function addBuyer(uint quantity, uint value) public {
        require(!used[msg.sender]);
        require(quantity > 0 && value > 0);

        buyers.push(Bid(msg.sender, quantity, value));
        used[msg.sender] = true;
        usedList.push(msg.sender);
    }

    function addSeller(uint quantity, uint value) public {
        require(!used[msg.sender]);
        require(quantity > 0 && value > 0);

        sellers.push(Bid(msg.sender, quantity, value));
        used[msg.sender] = true;
        usedList.push(msg.sender);
    }

    function doubleAuction() public {
        require(!auctionRan || block.timestamp >= lastAuctionTime + 30);

        delete resultSellers;
        delete resultBuyers;
        delete resultPrices;
        delete resultQuantities;

        uint i;
        uint j;

        for (i = 0; i < sellers.length; i++) {
            for (j = i + 1; j < sellers.length; j++) {
                if (sellers[j].v < sellers[i].v) {
                    Bid memory tempS = sellers[i];
                    sellers[i] = sellers[j];
                    sellers[j] = tempS;
                }
            }
        }

        for (i = 0; i < buyers.length; i++) {
            for (j = i + 1; j < buyers.length; j++) {
                if (buyers[j].v > buyers[i].v) {
                    Bid memory tempB = buyers[i];
                    buyers[i] = buyers[j];
                    buyers[j] = tempB;
                }
            }
        }

        uint n = buyers.length;
        if (sellers.length < n) {
            n = sellers.length;
        }

        uint k = 0;

        for (i = 0; i < n; i++) {
            if (buyers[i].v >= sellers[i].v) {
                k++;
            } else {
                break;
            }
        }

        if (k > 0) {
            uint price = (buyers[k - 1].v + sellers[k - 1].v) / 2;

            for (i = 0; i < k; i++) {
                resultSellers.push(sellers[i].user);
                resultBuyers.push(buyers[i].user);
                resultPrices.push(price);

                if (buyers[i].q < sellers[i].q) {
                    resultQuantities.push(buyers[i].q);
                } else {
                    resultQuantities.push(sellers[i].q);
                }
            }
        }

        for (i = 0; i < usedList.length; i++) {
            used[usedList[i]] = false;
        }

        delete usedList;
        delete buyers;
        delete sellers;

        lastAuctionTime = block.timestamp;
        auctionRan = true;
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
}