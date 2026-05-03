// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract BankingSystem {

    // -------------------------
    // Data Structures
    // -------------------------

    // Account struct stores all relevant banking information for each customer,
    // including their name, balance, loan details, and existence flag.
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
        owner = msg.sender;
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

        userAccounts[tx.origin] = Account({
            firstName: firstName,
            lastName: lastName,
            balance: 0,
            principalLoan: 0,
            interestLoan: 0,
            exists: true
        });

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
        Account storage acc = userAccounts[tx.origin];
        return (acc.balance, acc.firstName, acc.lastName, acc.principalLoan, acc.interestLoan);
    }

    function closeAccount() public {
        require(tx.origin != owner, "Error, Owner does not own an account");
        require(userAccounts[tx.origin].exists, "No Account Exists");
        require(
            userAccounts[tx.origin].principalLoan == 0 && userAccounts[tx.origin].interestLoan == 0,
            "Dues remaining, cannot close account before repayment"
        );
        require(userAccounts[tx.origin].balance == 0, "Outstanding balance, withdraw it to close your account");

        delete userAccounts[tx.origin];
    }

    // -------------------------
    // Deposits & Withdrawals
    // -------------------------
    function depositAmount() public payable {
        require(userAccounts[tx.origin].exists, "No Account");
        require(msg.value >= 1 ether, "Low Deposit");

        userAccounts[tx.origin].balance += msg.value;
    }

    function withDraw(uint withdrawalAmount) public {
        require(tx.origin != owner, "Error, Owner Prohibited");
        require(userAccounts[tx.origin].exists, "No Account");
        require(userAccounts[tx.origin].balance >= withdrawalAmount, "Insufficient Funds");

        userAccounts[tx.origin].balance -= withdrawalAmount;
        (bool success, ) = payable(tx.origin).call{value: withdrawalAmount}("");
        require(success, "Transfer failed");
    }

    function TransferEth(address recipient, uint transferAmount) public {
        require(tx.origin != owner, "Error, Owner Prohibited");
        require(userAccounts[tx.origin].exists, "No Account");
        require(userAccounts[recipient].exists, "Recipient account does not exist");
        require(userAccounts[tx.origin].balance >= transferAmount, "Insufficient Funds");

        userAccounts[tx.origin].balance -= transferAmount;
        userAccounts[recipient].balance += transferAmount;
    }

    // -------------------------
    // Loan Management
    // -------------------------
    function depositTopUp() public payable {
        require(tx.origin == owner, "Only Owner can call this function");
        loan_funds += msg.value;
    }

    function depositOperationalFunds() public payable {
        require(tx.origin == owner, "Only Owner can call this function");
        operational_funds += msg.value;
    }

    function TakeLoan(uint loanAmount) public {
        require(tx.origin != owner, "Error, Owner Prohibited");
        require(userAccounts[tx.origin].exists, "No Account");
        require(loan_funds >= loanAmount, "Insufficient Loan Funds");
        require(loanAmount <= userAccounts[tx.origin].balance * 2, "Loan Limit Exceeded");

        loan_funds -= loanAmount;
        userAccounts[tx.origin].principalLoan += loanAmount;

        (bool success, ) = payable(tx.origin).call{value: loanAmount}("");
        require(success, "Transfer failed");
    }

    function InquireLoan() public view returns (
        uint principal,
        uint interest,
        uint total
    ) {
        require(userAccounts[tx.origin].exists, "No Account");
        Account storage acc = userAccounts[tx.origin];
        return (acc.principalLoan, acc.interestLoan, acc.principalLoan + acc.interestLoan);
    }

    function returnLoan() public payable {
        require(userAccounts[tx.origin].exists, "No Account");
        require(
            userAccounts[tx.origin].principalLoan > 0 || userAccounts[tx.origin].interestLoan > 0,
            "No Loan"
        );
        require(
            msg.value <= userAccounts[tx.origin].principalLoan + userAccounts[tx.origin].interestLoan,
            "Owed Amount Exceeded"
        );

        uint payment = msg.value;

        // Pay interest first
        if (payment <= userAccounts[tx.origin].interestLoan) {
            userAccounts[tx.origin].interestLoan -= payment;
            operational_funds += payment;
        } else {
            // Clear interest first, then apply remainder to principal
            uint interestPaid = userAccounts[tx.origin].interestLoan;
            operational_funds += interestPaid;
            payment -= interestPaid;
            userAccounts[tx.origin].interestLoan = 0;

            userAccounts[tx.origin].principalLoan -= payment;
            loan_funds += payment;
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

        // Calculate total interest to be paid out
        uint totalInterest = 0;
        for (uint i = 0; i < addressList.length; i++) {
            address addr = addressList[i];
            if (userAccounts[addr].exists) {
                totalInterest += userAccounts[addr].balance * depositInterestRate / 100;
            }
        }

        require(operational_funds >= totalInterest, "Not enough operational funds to pay interest");

        // Distribute interest
        for (uint i = 0; i < addressList.length; i++) {
            address addr = addressList[i];
            if (userAccounts[addr].exists) {
                uint interest = userAccounts[addr].balance * depositInterestRate / 100;
                userAccounts[addr].balance += interest;
                operational_funds -= interest;
            }
        }
    }

    function addLoanInterest() public {
        require(tx.origin == owner, "Only the owner can add interest to loans");

        for (uint i = 0; i < addressList.length; i++) {
            address addr = addressList[i];
            if (userAccounts[addr].exists && userAccounts[addr].principalLoan > 0) {
                uint interest = userAccounts[addr].principalLoan * loanInterestRate / 100;
                userAccounts[addr].interestLoan += interest;
            }
        }
    }

    // -------------------------
    // Bank Info (view functions)
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
