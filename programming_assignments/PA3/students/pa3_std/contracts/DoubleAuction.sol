// SPDX-License-Identifier: HF
pragma solidity ^0.8.1;

/*
    CSE-355 Programming Assignment 3
    Double Auction Smart Contract

    Main idea:
    - Buyers submit bids: quantity + price they are willing to pay.
    - Sellers submit bids: quantity + price they are willing to accept.
    - Sellers are sorted from lowest price to highest price.
    - Buyers are sorted from highest price to lowest price.
    - The auction finds the largest index k where buyerPrice >= sellerPrice.
    - All pairs up to k trade.
    - The clearing price is calculated using the breakeven pair:
        clearingPrice = (buyer[k].price + seller[k].price) / 2
    - Quantity traded for each pair is:
        min(buyer.quantity, seller.quantity)
*/

contract DoubleAuction 
{
    uint constant private maxSize = 20;          // Maximum number of buyers/sellers allowed
    uint constant private AuctionInterval = 30;  // Minimum time gap between two auctions, in seconds

    /*
        A Bid stores one buyer/seller bid.

        bidder:
            The Ethereum address that submitted the bid.

        quantity:
            Number of units the bidder wants to buy/sell.

        price:
            Price at which the bidder is willing to buy/sell.
    */
    struct Bid {
        address bidder;
        uint quantity;
        uint price;
    }

    /*
        A Result stores one successful matched trade after the auction runs.

        seller:
            Seller address in the matched pair.

        buyer:
            Buyer address in the matched pair.

        clearingPrice:
            Final market clearing price used for this trade.

        quantity:
            Quantity traded between this buyer and seller.
    */
    struct Result {
        address seller;
        address buyer;
        uint clearingPrice;
        uint quantity;
    }

    // -----------------------------
    // Bid storage
    // -----------------------------

    Bid[] private buyers;
    Bid[] private sellers;

    // -----------------------------
    // Final auction results
    // -----------------------------

    Result[] private results;

    // -----------------------------
    // Duplicate bid prevention
    // -----------------------------
    // If an address has already submitted a bid in the current auction interval,
    // it cannot submit again until a successful auction resets this mapping.
    mapping(address => bool) private hasBidInCurrentInterval;

    // We also keep all bidder addresses so that we can reset the mapping after auction.
    address[] private currentIntervalBidders;

    // -----------------------------
    // Auction timing
    // -----------------------------

    uint private lastAuctionTime;
    bool private hasAuctionRun;

    /*
        Constructor

        deployDoubleAuction.js passes one constructor argument.
        We do not actually need that value for the assignment logic,
        but we keep the constructor parameter so deployment works cleanly.
    */
    constructor(uint ignoredValue) {
        ignoredValue; // Keeps compiler happy without changing logic.
        lastAuctionTime = 0;
        hasAuctionRun = false;
    }

    /*
        addBuyer

        Adds a buyer bid to the auction.

        Rules:
        - Quantity must be greater than 0.
        - Price must be greater than 0.
        - Maximum buyer list size is maxSize.
        - Same address cannot submit multiple bids in the current auction interval.
    */
    function addBuyer(uint quantity, uint price) public
    {
        require(quantity > 0, "Quantity must be positive");
        require(price > 0, "Price must be positive");
        require(buyers.length < maxSize, "Too many buyers");
        require(!hasBidInCurrentInterval[msg.sender], "Already bid in this interval");

        buyers.push(Bid({
            bidder: msg.sender,
            quantity: quantity,
            price: price
        }));

        hasBidInCurrentInterval[msg.sender] = true;
        currentIntervalBidders.push(msg.sender);
    } 
   
    /*
        addSeller

        Adds a seller bid to the auction.

        Rules:
        - Quantity must be greater than 0.
        - Price must be greater than 0.
        - Maximum seller list size is maxSize.
        - Same address cannot submit multiple bids in the current auction interval.
    */
    function addSeller(uint quantity, uint price) public
    {
        require(quantity > 0, "Quantity must be positive");
        require(price > 0, "Price must be positive");
        require(sellers.length < maxSize, "Too many sellers");
        require(!hasBidInCurrentInterval[msg.sender], "Already bid in this interval");

        sellers.push(Bid({
            bidder: msg.sender,
            quantity: quantity,
            price: price
        }));

        hasBidInCurrentInterval[msg.sender] = true;
        currentIntervalBidders.push(msg.sender);
    } 
    
    /*
        doubleAuction

        Runs the auction.

        Steps:
        1. Make sure enough time has passed since the previous successful auction.
        2. Clear old result rows.
        3. Sort sellers in ascending order of price.
        4. Sort buyers in descending order of price.
        5. Find the breakeven count.
        6. Calculate one market clearing price using the breakeven pair.
        7. Match all pairs up to breakeven count.
        8. Clear bids and reset duplicate-bid tracking.
    */
    function doubleAuction() public 
    {
        // The first auction is allowed immediately.
        // After that, at least 30 seconds must pass.
        require(
            !hasAuctionRun || block.timestamp >= lastAuctionTime + AuctionInterval,
            "Auction interval not reached"
        );

        // Remove old auction results before calculating new ones.
        delete results;

        // Sort the bids according to the double auction algorithm.
        sortSellersAscending();
        sortBuyersDescending();

        // Find how many pairs can trade.
        uint matchCount = getMatchCount();

        // If there is no possible trade, still update auction time and clear bids.
        // getResults will then return empty arrays.
        if (matchCount > 0) {
            uint breakevenIndex = matchCount - 1;

            // Single market clearing price from the breakeven pair.
            uint clearingPrice = (
                buyers[breakevenIndex].price + sellers[breakevenIndex].price
            ) / 2;

            // Store each successful matched pair.
            for (uint i = 0; i < matchCount; i++) {
                uint tradedQuantity = min(buyers[i].quantity, sellers[i].quantity);

                results.push(Result({
                    seller: sellers[i].bidder,
                    buyer: buyers[i].bidder,
                    clearingPrice: clearingPrice,
                    quantity: tradedQuantity
                }));
            }
        }

        // Mark auction as successfully run.
        lastAuctionTime = block.timestamp;
        hasAuctionRun = true;

        // Reset bid arrays and duplicate-bid mapping for the next interval.
        clearCurrentBids();
    }

    /*
        getResults

        Returns all final result columns as separate arrays because this is easier
        to read from Web3.js.

        JavaScript will print these arrays in this format:
        index sellAddresses buyAddresses C Q
    */
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
        uint length = results.length;

        sellAddresses = new address[](length);
        buyAddresses = new address[](length);
        clearingPrices = new uint[](length);
        quantities = new uint[](length);

        for (uint i = 0; i < length; i++) {
            sellAddresses[i] = results[i].seller;
            buyAddresses[i] = results[i].buyer;
            clearingPrices[i] = results[i].clearingPrice;
            quantities[i] = results[i].quantity;
        }

        return (sellAddresses, buyAddresses, clearingPrices, quantities);
    }    

    // -----------------------------
    // Internal helper functions
    // -----------------------------

    /*
        sortSellersAscending

        Sorts seller bids from lowest price to highest price.
        Example:
        1, 2, 3, 5, 40
    */
    function sortSellersAscending() internal {
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

    /*
        sortBuyersDescending

        Sorts buyer bids from highest price to lowest price.
        Example:
        10, 9, 8, 7, 6
    */
    function sortBuyersDescending() internal {
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

    /*
        getMatchCount

        Counts how many sorted buyer/seller pairs can trade.

        A pair can trade if:
            buyer price >= seller price

        The loop stops at the first failed pair because prices are sorted.
    */
    function getMatchCount() internal view returns (uint) {
        uint smallerLength = min(buyers.length, sellers.length);
        uint count = 0;

        for (uint i = 0; i < smallerLength; i++) {
            if (buyers[i].price >= sellers[i].price) {
                count++;
            } else {
                break;
            }
        }

        return count;
    }

    /*
        clearCurrentBids

        Clears buyers and sellers after an auction.
        Also resets hasBidInCurrentInterval for all addresses that submitted bids.
    */
    function clearCurrentBids() internal {
        delete buyers;
        delete sellers;

        for (uint i = 0; i < currentIntervalBidders.length; i++) {
            hasBidInCurrentInterval[currentIntervalBidders[i]] = false;
        }

        delete currentIntervalBidders;
    }

    /*
        min

        Returns the smaller of two unsigned integers.
        Used for traded quantity and array length comparison.
    */
    function min(uint a, uint b) internal pure returns (uint) {
        if (a < b) {
            return a;
        }

        return b;
    }
}