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
        bool exists; // IMPORTANT: track if account exists
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
        // TODO:
        // - set contract owner
        // - initialize interest rates and funds to 0
    }

    // -------------------------
    // Modifiers
    // -------------------------
    modifier onlyOwner() {
        // TODO: allow only owner
        _;
    }

    modifier notOwner() {
        // TODO: restrict owner from calling
        _;
    }

    modifier hasAccount() {
        // TODO: ensure sender has an account
        _;
    }

    // -------------------------
    // Account Management
    // -------------------------
    function openAccount(string memory firstName, string memory lastName) public {
        // TODO:
        // - prevent owner from opening account
        // - ensure account doesn't already exist
        // - create account
        // - push address to addressList
    }

    function getDetails() public view returns (
        uint balance,
        string memory first_name,
        string memory last_name,
        uint principal,
        uint interest
    ) {
        // TODO:
        // - ensure account exists
        // - return account fields
    }

    function closeAccount() public {
        // TODO:
        // - prevent owner
        // - ensure account exists
        // - ensure no loan due
        // - ensure balance is zero
        // - delete account
    }

    // -------------------------
    // Deposits & Withdrawals
    // -------------------------
    function depositAmount() public payable {
        // TODO:
        // - ensure account exists
        // - enforce minimum deposit (>= 1 ether)
        // - update balance
    }

    function withDraw(uint withdrawalAmount) public {
        // TODO:
        // - prevent owner
        // - ensure account exists
        // - check sufficient balance
        // - deduct and transfer ETH
    }

    function TransferEth(address recipient, uint transferAmount) public {
        // TODO:
        // - prevent owner
        // - ensure sender account exists
        // - ensure recipient exists
        // - check balance
        // - transfer internally
    }

    // -------------------------
    // Loan Management
    // -------------------------
    function depositTopUp() public payable {
        // TODO:
        // - only owner
        // - increase loan funds
    }

    function depositOperationalFunds() public payable {
        // TODO:
        // - only owner
        // - increase operational funds
    }

    function TakeLoan(uint loanAmount) public {
        // TODO:
        // - prevent owner
        // - ensure account exists
        // - check loan funds availability
        // - enforce loan limit (based on balance)
        // - update principal loan
        // - transfer ETH
    }

    function InquireLoan() public view returns (
        uint principal,
        uint interest,
        uint total
    ) {
        // TODO:
        // - ensure account exists
        // - return loan info
    }

    function returnLoan() public payable {
        // TODO:
        // - ensure account exists
        // - ensure loan exists
        // - prevent overpayment
        // - pay interest first, then principal
        // - update operational_funds and loan_funds
    }

    // -------------------------
    // Interest Handling
    // -------------------------
    function setInterestRates(uint dep_interest_rate, uint loan_interest_rate) public {
        // TODO:
        // - only owner
        // - set depositInterestRate and loanInterestRate
    }

    function addDepositInterest() public {
        // TODO:
        // - only owner
        // - calculate total interest required
        // - ensure enough operational funds
        // - distribute interest to all users
        // - deduct from operational funds
    }

    function addLoanInterest() public {
        // TODO:
        // - only owner
        // - loop through users
        // - add interest on principal loans
    }

    // -------------------------
    // Bank Info
    // -------------------------
    function AmountInBank() public view returns(uint) {
        // TODO:
        // return contract ETH balance
    }

    function DepositInterestRate() public view returns(uint) {
        // TODO:
        // return deposit interest rate
    }

    function LoanInterestRate() public view returns(uint) {
        // TODO:
        // return loan interest rate
    }

    function LoanFunds() public view returns(uint) {
        // TODO:
        // return loan funds
    }

    function OperationalFunds() public view returns(uint) {
        // TODO:
        // return operational funds
    }
}