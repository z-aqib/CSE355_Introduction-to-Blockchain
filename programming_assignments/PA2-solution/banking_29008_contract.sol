// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract BankingSystem {

    // -------------------------
    // Data Structures
    // -------------------------
    struct Account {
        string firstName;
        string lastName;
        uint principalLoan;
        uint interestLoan;
        uint balance;
        bool exists;
    }

    address private owner;
    uint private loan_funds;
    uint private depositInterestRate;
    uint private loanInterestRate;
    uint private operational_funds;

    address[] public addressList;
    mapping(address => Account) public userAccounts;

    // -------------------------
    // Constructor
    // -------------------------
    constructor() {
        owner = tx.origin;
        depositInterestRate = 0;
        loanInterestRate = 0;
        loan_funds = 0;
        operational_funds = 0;
    }

    // -------------------------
    // Modifiers
    // -------------------------
    modifier onlyOwner() {
        require(tx.origin == owner, "Only Owner can call this function");
        _;
    }

    modifier notOwner() {
        require(tx.origin != owner, "Error, Owner Prohibited");
        _;
    }

    modifier hasAccount() {
        require(userAccounts[tx.origin].exists, "No Account");
        _;
    }

    // -------------------------
    // Account Management
    // -------------------------
    function openAccount(string memory firstName, string memory lastName) public {
        require(tx.origin != owner, "Error, Owner Prohibited");
        require(!userAccounts[tx.origin].exists, "Account already exists");

        userAccounts[tx.origin] = Account(firstName, lastName, 0, 0, 0, true);
        addressList.push(tx.origin);
    }

    function getDetails() public view returns (
        uint balance,
        string memory first_name,
        string memory last_name,
        uint principal,
        uint interest
    ) {
        require(userAccounts[tx.origin].exists, "No Account");

        Account memory acc = userAccounts[tx.origin];
        return (acc.balance, acc.firstName, acc.lastName, acc.principalLoan, acc.interestLoan);
    }

    function closeAccount() public {
        require(tx.origin != owner, "Error, Owner does not own an account");
        require(userAccounts[tx.origin].exists, "No Account Exists");

        Account storage acc = userAccounts[tx.origin];

        require(acc.principalLoan == 0 && acc.interestLoan == 0,
            "Dues remaining, cannot close account before repayment");

        require(acc.balance == 0,
            "Outstanding balance, withdraw it to close your account");

        delete userAccounts[tx.origin];
    }

    // -------------------------
    // Deposits & Withdrawals
    // -------------------------
    function depositAmount() public payable hasAccount {
        require(msg.value >= 1 ether, "Low Deposit");
        userAccounts[tx.origin].balance += msg.value;
    }

    function withDraw(uint withdrawalAmount) public notOwner hasAccount {
        Account storage acc = userAccounts[tx.origin];

        require(acc.balance >= withdrawalAmount, "Insufficient Funds");

        acc.balance -= withdrawalAmount;
        payable(tx.origin).transfer(withdrawalAmount);
    }

    function TransferEth(address recipient, uint transferAmount) public notOwner hasAccount {
        require(userAccounts[recipient].exists, "Recipient account does not exist");

        Account storage sender = userAccounts[tx.origin];

        require(sender.balance >= transferAmount, "Insufficient Funds");

        sender.balance -= transferAmount;
        userAccounts[recipient].balance += transferAmount;
    }

    // -------------------------
    // Loan Management
    // -------------------------
    function depositTopUp() public payable onlyOwner {
        loan_funds += msg.value;
    }

    function depositOperationalFunds() public payable onlyOwner {
        operational_funds += msg.value;
    }

    function TakeLoan(uint loanAmount) public notOwner hasAccount {
        require(loanAmount <= loan_funds, "Insufficient Loan Funds");

        Account storage acc = userAccounts[tx.origin];
        require(loanAmount <= acc.balance * 2, "Loan Limit Exceeded");

        loan_funds -= loanAmount;
        acc.principalLoan += loanAmount;

        payable(tx.origin).transfer(loanAmount);
    }

    function InquireLoan() public view hasAccount returns (
        uint principal,
        uint interest,
        uint total
    ) {
        Account memory acc = userAccounts[tx.origin];
        return (acc.principalLoan, acc.interestLoan, acc.principalLoan + acc.interestLoan);
    }

    function returnLoan() public payable hasAccount {
        Account storage acc = userAccounts[tx.origin];

        uint total = acc.principalLoan + acc.interestLoan;

        require(total > 0, "No Loan");
        require(msg.value <= total, "Owed Amount Exceeded");

        uint payment = msg.value;

        if (payment <= acc.interestLoan) {
            acc.interestLoan -= payment;
            operational_funds += payment;
        } else {
            uint remaining = payment - acc.interestLoan;

            operational_funds += acc.interestLoan;
            acc.interestLoan = 0;

            acc.principalLoan -= remaining;
            loan_funds += remaining;
        }
    }

    // -------------------------
    // Interest Handling
    // -------------------------
    function setInterestRates(uint dep_interest_rate, uint loan_interest_rate) public {
        require(tx.origin == owner, "Only the owner can set interest rates");

        depositInterestRate = dep_interest_rate;
        loanInterestRate = loan_interest_rate;
    }

    function addDepositInterest() public {
        require(tx.origin == owner, "Only the owner can add interest to deposits");

        uint totalInterest = 0;

        for (uint i = 0; i < addressList.length; i++) {
            address user = addressList[i];
            if (userAccounts[user].exists) {
                uint interest = (userAccounts[user].balance * depositInterestRate) / 100;
                totalInterest += interest;
            }
        }

        require(totalInterest <= operational_funds,
            "Not enough operational funds to pay interest");

        for (uint i = 0; i < addressList.length; i++) {
            address user = addressList[i];
            if (userAccounts[user].exists) {
                uint interest = (userAccounts[user].balance * depositInterestRate) / 100;
                userAccounts[user].balance += interest;
            }
        }

        operational_funds -= totalInterest;
    }

    function addLoanInterest() public {
        require(tx.origin == owner, "Only the owner can add interest to loans");

        for (uint i = 0; i < addressList.length; i++) {
            address user = addressList[i];
            if (userAccounts[user].exists) {
                uint interest = (userAccounts[user].principalLoan * loanInterestRate) / 100;
                userAccounts[user].interestLoan += interest;
            }
        }
    }

    // -------------------------
    // Bank Info
    // -------------------------
    function AmountInBank() public view returns(uint) {
        return address(this).balance;
    }

    function DepositInterestRate() public view returns(uint) {
        return depositInterestRate;
    }

    function LoanInterestRate() public view returns(uint) {
        return loanInterestRate;
    }

    function LoanFunds() public view returns(uint) {
        return loan_funds;
    }

    function OperationalFunds() public view returns(uint) {
        return operational_funds;
    }
}