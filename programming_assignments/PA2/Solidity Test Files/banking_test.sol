// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.

import "../contracts/banking_xxxxx_contract.sol";          // replace xxxxx this with your ERP.
import "remix_accounts.sol";

contract BankingTest
{
    address owner;
    address user1;
    address user2;
    address user3;

    address sc;

    BankingSystem TestSystem;

    function beforeAll() public 
    {
        owner = TestsAccounts.getAccount(0);
        user1 = TestsAccounts.getAccount(1);
        user2 = TestsAccounts.getAccount(2);         
        user3 = TestsAccounts.getAccount(3);
        TestSystem = new BankingSystem();
    }

    /// #sender: account-1 (sender is account at index '1')
    function checkUser1Creation() public 
    {
        TestSystem.openAccount("Amaan","Ahmed");
        (uint balance2, string memory first_name2, string memory last_name2, uint loanPrincipal, uint loanInterest) = TestSystem.getDetails(); 
         Assert.equal(balance2, uint(0), "Wrong Balance Assigned Initially");
        Assert.equal(first_name2, string("Amaan"), "Wrong First Name");
        Assert.equal(last_name2, string("Ahmed"), "Wrong Last Name");   
        Assert.equal(loanPrincipal,0,"Wrong Loan Amount");
    }

    /// #sender: account-2 (sender is account at index '2')
    function checkUser2Creation() public 
    {
        TestSystem.openAccount("Zain","Imran");
        (uint balance2, string memory first_name2, string memory last_name2, uint loanPrincipal, uint loanInterest) = TestSystem.getDetails(); 
         Assert.equal(balance2, uint(0), "Wrong Balance Assigned Initially");
        Assert.equal(first_name2, string("Zain"), "Wrong First Name");
        Assert.equal(last_name2, string("Imran"), "Wrong Last Name");   
        Assert.equal(loanPrincipal,0,"Wrong Loan Amount");
    }
        
    // Depositing 10 ether in account 1
    /// #value: 10000000000000000000
    /// #sender: account-1 (sender is account at index '1')
    function checkUser1Deposit() public payable 
    {
        uint BankSystemBalance_start = TestSystem.AmountInBank();
        (uint balance1_start, string memory first_name1_start, string memory last_name1_start, uint loanPrincipal1_start, uint loanInterest1_start) = TestSystem.getDetails(); 

        TestSystem.depositAmount{value:10000000000000000000}();

        (uint balance1_end, string memory first_name1_end, string memory last_name1_end, uint loanPrincipal1_end, uint loanInterest1_end) = TestSystem.getDetails();
        uint BankSystemBalance_end = TestSystem.AmountInBank();

        Assert.equal(BankSystemBalance_start + 10000000000000000000, BankSystemBalance_end, "Contract's balance incorrect");
        Assert.equal(balance1_start + 10000000000000000000, balance1_end, "Wrong Balance");
        Assert.equal(first_name1_start, first_name1_end, "Wrong First Name");
        Assert.equal(last_name1_start, last_name1_end, "Wrong Last Name");
        Assert.equal(loanPrincipal1_start, loanPrincipal1_end, "Wrong Loan Amount");

    } 

    uint balance2_start; uint loanAmount2_start;
    /// #sender: account-2
    function PreTransferETH() public {
        // getDetails returns 5 values; receive all then assign the ones you need
        (uint _balance2_start,  , , uint _loanAmount2_start, ) = TestSystem.getDetails();
        balance2_start = _balance2_start;
        loanAmount2_start = _loanAmount2_start;
    }
        
    /// #sender: account-1 (sender is account at index '1')
    function TransferETH() public 
    {
        address payable userP2 = payable(user2);
        
        uint BankSystemBalance_start = TestSystem.AmountInBank();
        (uint balance1_start,  , , uint loanAmount1_start, ) = TestSystem.getDetails();

        TestSystem.TransferEth(userP2,500000000000000000);

        uint BankSystemBalance_end = TestSystem.AmountInBank();
        (uint balance1_end,  , , uint loanAmount1_end, ) = TestSystem.getDetails();

        Assert.equal(BankSystemBalance_start, BankSystemBalance_end, "Contract's balance incorrect");
        Assert.equal(balance1_start - 500000000000000000, balance1_end, "Wrong Balance of User 1");
        Assert.equal(loanAmount1_start, loanAmount1_end, "Wrong Loan Amount of User 1");
       
    }

    uint balance2_end; uint loanAmount2_end;
    /// #sender: account-2
    function PostTransferETH() public {
        (uint _balance2_end,  , , uint _loanAmount2_end, ) = TestSystem.getDetails();
        balance2_end = _balance2_end;
        loanAmount2_end = _loanAmount2_end;

        Assert.equal(balance2_start + 500000000000000000, balance2_end, "Wrong Balance of User 2");
        Assert.equal(loanAmount2_start, loanAmount2_end, "Wrong Loan Amount of User 2");
    }


    // We try to withdrawl 1 ether from smart contract to wallet of user 1
    /// #sender: account-1 (sender is account at index '1')
    function checkWithDrawalFromUser() public 
    {
        uint BankSystemBalance_start = TestSystem.AmountInBank();
        uint user1WalletBalance_start = user1.balance;
        (uint balance1_start,  , , uint loanAmount1_start, ) = TestSystem.getDetails();

        TestSystem.withDraw(200000000000000000); 

        uint BankSystemBalance_end = TestSystem.AmountInBank();
        uint user1WalletBalance_end = user1.balance;
        (uint balance1_end,  , , uint loanAmount1_end, ) = TestSystem.getDetails();

        Assert.equal(BankSystemBalance_start - 200000000000000000, BankSystemBalance_end, "Contract's balance incorrect");
        Assert.equal(user1WalletBalance_start + 200000000000000000, user1WalletBalance_end, "User's balance incorrect");
        Assert.equal(balance1_start - 200000000000000000, balance1_end, "Wrong Balance");
        Assert.equal(loanAmount1_start, loanAmount1_end, "Wrong Loan Amount");
        
    }

    /// #value: 10000000000000000000
    /// #sender: account-0 (sender is account at index '0')
    function checkLoanFund() public payable 
    {
        uint BankSystemBalance_start = TestSystem.AmountInBank();
        uint loanFunds_start = TestSystem.LoanFunds();

        TestSystem.depositTopUp{value:10000000000000000000}();        

        uint BankSystemBalance_end = TestSystem.AmountInBank();
        uint loanFunds_end = TestSystem.LoanFunds();

        Assert.equal(BankSystemBalance_start + 10000000000000000000, BankSystemBalance_end, "Contract's balance incorrect");
        Assert.equal(loanFunds_start + 10000000000000000000, loanFunds_end, "Loan Funds Not Updated Correctly");
    }

    /// #sender: account-1 (sender is account at index '1')
    function CheckingLoanTransferred() public 
    {
        uint BankSystemBalance_start = TestSystem.AmountInBank(); 
        (uint balance1_start,  , , uint loanAmount1_start, ) = TestSystem.getDetails();
        uint loanFunds_start = TestSystem.LoanFunds();

        TestSystem.TakeLoan(1000000000000000000);

        uint BankSystemBalance_end = TestSystem.AmountInBank();
        (uint balance1_end,  , , uint loanAmount1_end, ) = TestSystem.getDetails();
        uint loanFunds_end = TestSystem.LoanFunds();
        (uint principal, uint interest, uint total) = TestSystem.InquireLoan();


        Assert.equal(principal, uint(1000000000000000000), "Wrong Loan Record");
        Assert.equal(BankSystemBalance_start - 1000000000000000000, BankSystemBalance_end, "Contract's balance incorrect");
        Assert.equal(balance1_start, balance1_end, "Wrong Balance");
        Assert.equal(loanAmount1_start + 1000000000000000000, loanAmount1_end, "Wrong Loan Amount");
        Assert.equal(loanFunds_start - 1000000000000000000, loanFunds_end, "Loan Funds Not Updated Correctly");
    }

    /// #value: 1000000000000000000
    /// #sender: account-1 (sender is account at index '1')
    function checkReturnLoan() public payable 
    {
        uint BankSystemBalance_start = TestSystem.AmountInBank();
        (uint balance1_start,  , , uint loanAmount1_start, ) = TestSystem.getDetails();
        uint loanFunds_start = TestSystem.LoanFunds();

        TestSystem.returnLoan{value:1000000000000000000}();
        uint BankSystemBalance_end = TestSystem.AmountInBank();
        (uint balance1_end,  , , uint loanAmount1_end, ) = TestSystem.getDetails();
        uint loanFunds_end = TestSystem.LoanFunds();
        (uint principal, uint interest, uint total) = TestSystem.InquireLoan();

        Assert.equal(principal, uint(0), "Wrong Loan Record");
        Assert.equal(BankSystemBalance_start + 1000000000000000000, BankSystemBalance_end, "Contract's balance incorrect");
        Assert.equal(balance1_start, balance1_end, "Wrong Balance");
        Assert.equal(loanAmount1_start - 1000000000000000000, loanAmount1_end, "Wrong Loan Amount");
        Assert.equal(loanFunds_start + 1000000000000000000, loanFunds_end, "Loan Funds Not Updated Correctly");
    }

    uint chek = 0;
    /// #sender: account-1 
    function closingAccount() public {
        (uint balance1_start,  , , uint loanAmount1_start, ) = TestSystem.getDetails();
        TestSystem.withDraw(balance1_start);
        TestSystem.closeAccount();
        try TestSystem.getDetails() 
        {
            chek = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("No Account"), "Account not closed properly");
        }
        Assert.equal(chek, 0, "Account not closed properly");

    }

}
