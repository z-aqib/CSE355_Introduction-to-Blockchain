// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.

import "../contracts/banking_xxxxx_contract.sol";          // replace xxxxx with your ERP.
import "remix_accounts.sol";


contract InterestTests 
{
    BankingSystem TestSystem;
    address owner;
    address user1;
    address user2;
    address user3;
    address user4;

    function beforeAll() public 
    {
        owner = TestsAccounts.getAccount(0);
        user1 = TestsAccounts.getAccount(1);
        user2 = TestsAccounts.getAccount(2);
        user3 = TestsAccounts.getAccount(3);
        user4 = TestsAccounts.getAccount(4);
        TestSystem = new BankingSystem();
    }

    uint public flag = 0;

    /// #sender: account-0
    function testInterestRateSettingOwner() public 
    {
        flag = 0;

        try TestSystem.setInterestRates(50, 70) 
        {
            flag = 1;
        } 
        catch Error(string memory reason)
        {
            Assert.equal(reason, string("Only the owner can set interest rates"), "Not Owner.");
        }

        Assert.equal(flag, 1, "Did not set interest rates."); 
        Assert.equal(TestSystem.DepositInterestRate(), 50, "Did not set deposit rate correctly.");
        Assert.equal(TestSystem.LoanInterestRate(), 70, "Did not set loan rate correctly.");  
    }

    /// #value: 20000000000000000000
    /// #sender: account-0
    function checkTopUp() public payable {
        uint initialLoanFunds = TestSystem.LoanFunds();
        TestSystem.depositTopUp{value: 20000000000000000000}();
        uint finalLoanFunds = TestSystem.LoanFunds();
        Assert.equal(finalLoanFunds, initialLoanFunds + 20000000000000000000, "Top up failed.");
    }

    /// #sender: account-1 (sender is account at index '1')
    function checkUser1Creation() public 
    {
        TestSystem.openAccount("Jack","Mama");
        (uint balance2, string memory first_name2, string memory last_name2, uint loanAmount, ) = TestSystem.getDetails(); 
        Assert.equal(balance2, uint(0), "Wrong Balance Assigned Initially");
        Assert.equal(first_name2, string("Jack"), "Wrong First Name");
        Assert.equal(last_name2, string("Mama"), "Wrong Last Name");   
        Assert.equal(loanAmount,0,"Wrong Loan Amount");
    }
   
    /// #sender: account-2 (sender is account at index '2')
    function checkUser2Creation() public 
    {
        TestSystem.openAccount("Steve","Jobless");
        (uint balance2, string memory first_name2, string memory last_name2, uint loanAmount, ) = TestSystem.getDetails(); 
        Assert.equal(balance2, uint(0), "Wrong Balance Assigned Initially");
        Assert.equal(first_name2, string("Steve"), "Wrong First Name");
        Assert.equal(last_name2, string("Jobless"), "Wrong Last Name");   
        Assert.equal(loanAmount,0,"Wrong Loan Amount");
    }

    /// #sender: account-3 (sender is account at index '3')
    function checkUser3Creation() public {
        TestSystem.openAccount("Elon","Musk");
        (uint balance3, string memory first_name3, string memory last_name3, uint loanAmount3, ) = TestSystem.getDetails();
        Assert.equal(balance3, uint(0), "Wrong Balance Assigned Initially");
        Assert.equal(first_name3, string("Elon"), "Wrong First Name");
        Assert.equal(last_name3, string("Musk"), "Wrong Last Name");
        Assert.equal(loanAmount3, 0, "Wrong Loan Amount");
    }

    // Depositing 10 ether in account 1
    /// #value: 1000000000000000000
    /// #sender: account-1 (sender is account at index '1')
    function checkUser1Deposit() public payable 
    {
        TestSystem.depositAmount{value:1000000000000000000}();
        (uint balance2, string memory first_name2, string memory last_name2, uint loanAmount, ) = TestSystem.getDetails(); 
        Assert.equal(balance2, 1000000000000000000, "Wrong Balance");
        Assert.equal(first_name2, string("Jack"), "Wrong First Name");
        Assert.equal(last_name2, string("Mama"), "Wrong Last Name");            
        Assert.equal(loanAmount,0,"Wrong Loan Amount");
    } 

    /// #sender: account-1
    function checkUser1Loan() public {
        TestSystem.TakeLoan(2000000000000000000);
        (uint principal, uint interest, uint total) = TestSystem.InquireLoan();
        Assert.equal(principal, 2000000000000000000, "Wrong Loan Taken");
    }

    // Depositing 5 ether in account 2
    /// #value: 5000000000000000000
    /// #sender: account-2 (sender is account at index '2')
    function checkUser2Deposit() public payable 
    {
        TestSystem.depositAmount{value:5000000000000000000}();
        (uint balance2, string memory first_name2, string memory last_name2, uint loanAmount, ) = TestSystem.getDetails(); 
        Assert.equal(balance2, 5000000000000000000, "Wrong Balance");
        Assert.equal(first_name2, string("Steve"), "Wrong First Name");
        Assert.equal(last_name2, string("Jobless"), "Wrong Last Name");            
        Assert.equal(loanAmount,0,"Wrong Loan Amount");
    } 

    /// #sender: account-2
    function checkUser2Loan() public {
        TestSystem.TakeLoan(2000000000000000000);
        (uint principal, uint interest, uint total) = TestSystem.InquireLoan();
        Assert.equal(principal, 2000000000000000000, "Wrong Loan Taken");
    }

    /// #value: 2000000000000000000
    /// #sender: account-3 (sender is account at index '3')
    function checkUser3Deposit() public payable 
    {
        TestSystem.depositAmount{value:2000000000000000000}();
        (uint balance3, string memory first_name3, string memory last_name3, uint loanAmount3, ) = TestSystem.getDetails();
        Assert.equal(balance3, 2000000000000000000, "Wrong Balance");
        Assert.equal(first_name3, string("Elon"), "Wrong First Name");
        Assert.equal(last_name3, string("Musk"), "Wrong Last Name");
        Assert.equal(loanAmount3, 0, "Wrong Loan Amount");
    }

    /// #sender: account-3
    function checkUser3Loan() public {
        TestSystem.TakeLoan(2000000000000000000);
        (uint principal, uint interest, uint total) = TestSystem.InquireLoan();
        Assert.equal(principal, 2000000000000000000, "Wrong Loan Taken");
    }

    /// #value: 2000000000000000000
    /// #sender: account-0
    function depositOperationalFunds() public payable {
        uint operationalFunds_start = TestSystem.OperationalFunds();
        TestSystem.depositOperationalFunds{value:2000000000000000000}();
        uint operationalFunds_end = TestSystem.OperationalFunds();
        Assert.equal(operationalFunds_end - operationalFunds_start, 2000000000000000000, "Wrong Operational Funds");
    }

    /// #sender: account-0
    function checkInsufficientOperationalFunds() public {
        uint flaa = 1;
        try TestSystem.addDepositInterest() {
            flaa = 0;
        }
        catch Error(string memory reason)  {
            Assert.equal(reason, string("Not enough operational funds to pay interest"), "Wrong reason");
        }
        Assert.equal(flaa, 1, "Contract allowed deposit interest even though operational funds were insufficient");
    }

    /// #value: 50000000000000000000
    /// #sender: account-0
    function depositOperationalFundsAgain() public payable {
        TestSystem.depositOperationalFunds{value:50000000000000000000}();
        uint operationalFunds_end = TestSystem.OperationalFunds();
        Assert.equal(operationalFunds_end, 52000000000000000000, "Wrong Operational Funds");
    }

    uint operationalFundsStart;
    uint operationalFundsEnd;
    uint[3] balance_start;
    uint[3] balance_end;
    uint[3] loanAmount_start;
    uint[3] loanAmount_end;
    uint[3] interestAmount_start;
    uint[3] interestAmount_end;

    /// #sender: account-1
    function preTest1A() public {(balance_start[0], , , loanAmount_start[0], ) = TestSystem.getDetails();}

    /// #sender: account-2
    function preTest2A() public {(balance_start[1], , , loanAmount_start[1], ) = TestSystem.getDetails();}

    /// #sender: account-3
    function preTest3A() public {(balance_start[2], , , loanAmount_start[2], ) = TestSystem.getDetails();}

    /// #sender: account-0
    function GiveDepositInterest() public {
        operationalFundsStart = TestSystem.OperationalFunds(); 
        TestSystem.addDepositInterest();
        operationalFundsEnd = TestSystem.OperationalFunds(); 
    }

    /// #sender: account-1
    function postTest1A() public {(balance_end[0], , , loanAmount_end[0], ) = TestSystem.getDetails();}

    /// #sender: account-2
    function postTest2A() public {(balance_end[1], , , loanAmount_end[1], ) = TestSystem.getDetails();}

    /// #sender: account-3
    function postTest3A() public {(balance_end[2], , , loanAmount_end[2], ) = TestSystem.getDetails();}

    /// #sender: account-0
    function testOwnerGiveDepositInterest() public {
        uint depositInterestRate = TestSystem.DepositInterestRate();
        Assert.equal(loanAmount_start[0], loanAmount_end[0], "Loan Amount of User 1 changed after adding deposit interest");
        Assert.equal(loanAmount_start[1], loanAmount_end[1], "Loan Amount of User 2 changed after adding deposit interest");
        Assert.equal(loanAmount_start[2], loanAmount_end[2], "Loan Amount of User 3 changed after adding deposit interest");

        Assert.equal(balance_end[0], balance_start[0]+(balance_start[0]*depositInterestRate)/100, "Balance incorrect");
        Assert.equal(balance_end[1], balance_start[1]+(balance_start[1]*depositInterestRate)/100, "Balance incorrect");
        Assert.equal(balance_end[2], balance_start[2]+(balance_start[2]*depositInterestRate)/100, "Balance incorrect");

        uint totalInterestPaid = (balance_start[0]*depositInterestRate)/100
                                +(balance_start[1]*depositInterestRate)/100
                                +(balance_start[2]*depositInterestRate)/100;    

        Assert.equal(operationalFundsStart - totalInterestPaid, operationalFundsEnd , "Operational Funds not updated correctly");

    }

    

    /// #sender: account-1
    function preTest1B() public {(balance_start[0], , , loanAmount_start[0], interestAmount_start[0]) = TestSystem.getDetails();}

    /// #sender: account-2
    function preTest2B() public {(balance_start[1], , , loanAmount_start[1], interestAmount_start[1]) = TestSystem.getDetails();}

    /// #sender: account-3
    function preTest3B() public {(balance_start[2], , , loanAmount_start[2], interestAmount_start[2]) = TestSystem.getDetails();}

    /// #sender: account-0
    function GiveLoanInterest() public {TestSystem.addLoanInterest();}

    /// #sender: account-1
    function postTest1B() public {(balance_end[0], , , , interestAmount_end[0]) = TestSystem.getDetails();}

    /// #sender: account-2
    function postTest2B() public {(balance_end[1], , , , interestAmount_end[1]) = TestSystem.getDetails();}

    /// #sender: account-3
    function postTest3B() public {(balance_end[2], , , , interestAmount_end[2]) = TestSystem.getDetails();}

    /// #sender: account-0
    function testOwnerGiveLoanInterest() public {
        uint loanInterestRate = TestSystem.LoanInterestRate();

        Assert.equal(balance_start[0], balance_end[0], "Balance of User 1 changed after adding loan interest");
        Assert.equal(balance_start[1], balance_end[1], "Balance of User 2 changed after adding loan interest");
        Assert.equal(balance_start[2], balance_end[2], "Balance of User 3 changed after adding loan interest");

        Assert.equal(interestAmount_end[0], interestAmount_start[0]+(loanAmount_start[0]*loanInterestRate)/100, "Loan Amount incorrect");
        Assert.equal(interestAmount_end[1], interestAmount_start[1]+(loanAmount_start[1]*loanInterestRate)/100, "Loan Amount incorrect");
        Assert.equal(interestAmount_end[2], interestAmount_start[2]+(loanAmount_start[2]*loanInterestRate)/100, "Loan Amount incorrect");

    }

    uint public flag_U = 0;
     /// #sender: account-1
    function testAccountClosureWithLoanUnpaid() public 
    {
        try TestSystem.closeAccount() 
        {
            flag_U = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("Dues remaining, cannot close account before repayment"), "Cannot close account without repaying loan.");
        }
        Assert.equal(flag_U, 0, "Should not close the account.");
    }

    /// #value: 1000000000000000000
    /// #sender: account-1
    function TestRepayPartialLoanUpdates1() public payable {
        uint operationalStart = TestSystem.OperationalFunds();
        (, uint interest_start,) = TestSystem.InquireLoan();

        TestSystem.returnLoan{value:1000000000000000000}();

        (, uint interest_end, ) = TestSystem.InquireLoan();
        uint operationalEnd = TestSystem.OperationalFunds();

        Assert.equal(operationalStart+1000000000000000000, operationalEnd, "Operational Funds updated incorrectly");
        Assert.equal(interest_start-1000000000000000000, interest_end, "Interest updated incorrectly");
    }

    /// #value: 1000000000000000000
    /// #sender: account-1
    function TestRepayPartialLoanUpdates2() public payable {
        uint operationalStart = TestSystem.OperationalFunds();
        uint loanFunds_start = TestSystem.LoanFunds();
        (uint principal_start, uint interest_start, ) = TestSystem.InquireLoan();

        TestSystem.returnLoan{value:1000000000000000000}();

        uint operationalEnd = TestSystem.OperationalFunds();
        uint loanFunds_end = TestSystem.LoanFunds();
        (uint principal_end, uint interest_end, ) = TestSystem.InquireLoan();

        Assert.equal(operationalStart+400000000000000000, operationalEnd, "Operational funds updated incorrectly");
        Assert.equal(loanFunds_start+600000000000000000, loanFunds_end, "Loan funds updated incorrectly");
        Assert.equal(principal_start-600000000000000000, principal_end, "Principal updated incorrectly");
        Assert.equal(interest_start-400000000000000000, interest_end, "Interest updated incorrectly");
    }


    /// #value: 10000000000000000000
    /// #sender: account-4
    function testAccount4TakeLoan() public payable {

        TestSystem.openAccount("Random","Person");
        TestSystem.depositAmount{value:10000000000000000000}();
        TestSystem.TakeLoan(3000000000000000000);
    }

    /// #value: 3000000000000000000
    /// #sender: account-4
    function testRepayAccount4Loan() public payable {
        TestSystem.returnLoan{value:3000000000000000000}();
    }


    uint public flag_R = 0;
    /// #sender: account-4 (sender is account at index '1')
    function testAccountClosureWithLoanRepaid() public 
    {
        // get details
        (uint balance, , , , ) = TestSystem.getDetails();
        TestSystem.withDraw(balance);
        try TestSystem.closeAccount() 
        {
            flag_R = 1;
        } 
        catch Error(string memory reason) 
        {
            // do nothing, should not be reverted.
        }
        Assert.equal(flag_R, 1, "Should close the account.");
    }
    

    uint public flag_M = 0;
    /// #sender: account-4 (sender is account at index '1')
    function testAccountClosureAlreadyClosed() public 
    {
        try TestSystem.closeAccount() 
        {
            flag_M = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("No Account Exists"), "Account is already closed.");
        }
        Assert.equal(flag_M, 0, "Should not close the account.");
    }
}