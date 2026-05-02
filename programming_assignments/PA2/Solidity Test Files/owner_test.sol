// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.

import "../contracts/banking_xxxxx_contract.sol";          // replace xxxxx with your ERP.
import "remix_accounts.sol";

contract OwnerTest
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

    /// #sender: account-0 (sender is account at index '0')
    // This function is to test if the owner is prohibited to create an account & if it gives the right error     
    uint public errorCount = 0;
    function testOwnerAccountOpening() public  
    {
        try TestSystem.openAccount("Amaan","Ahmed") 
        {
            // Here the owner is calling this function, IF he is able to make an account than case fails.
            errorCount = 1;      
        }  
        catch Error(string memory reason)
        {
            // If the owner is unable to create an account, it comes here & the reason should be caught.
            // if the owner is unable to create an account, it will return the string reason which should be as in manual.
            Assert.equal(reason,string("Error, Owner Prohibited"),"Owner not giving the right error");
        }
        Assert.equal(errorCount, 0,"Error - Owner Can Also Create An Account");      
    } 

    uint gotIt = 0;
    /// #sender: account-0 (sender is account at index '0')
    function testOwnerAskingForDetails() public {
        
        try TestSystem.getDetails()
        {
            gotIt = 1;
        } 
        catch Error(string memory reason)
        {
            Assert.equal(reason, string("No Account"), "Owner can get his account details! :( ");
        }
        Assert.equal(gotIt, 0, "Owner can get his account details! :( ");

    }

    /// #sender: account-0 (sender is account at index '0')
    // This function is to test if the owner is prohibited to create an account & if it gives the right error     
    uint public Ec = 0;
    function testOwnerAskingForLoan() public  
    {
        try TestSystem.TakeLoan(1000000000000000000)   
        {
            // Here the owner is calling this function, IF he is able to make an account than case fails.
            Ec = 1;      
        }  
        catch Error(string memory reason)
        {
            // If the owner is unable to create an account, it comes here & the reason should be caught.
            // if the owner is unable to create an account, it will return the string reason which should be as in manual.
            Assert.equal(reason,string("Error, Owner Prohibited"),"Owner not giving the right error in taking a loan");
        }
        Assert.equal(Ec, 0,"Error - Owner Can Also Take A Loan");
    }

    /// #sender: account-0 (sender is account at index '0')
    function testOwnerTransfer() public 
    {
        address payable userP2 = payable(user2);
        try TestSystem.TransferEth(userP2,5000000000000000000)
        {
            // Here the owner is calling this function, IF he is able to make an account than case fails.
            Ec = 1;      
        }  
        catch Error(string memory reason)
        {
            // If the owner is unable to create an account, it comes here & the reason should be caught.
            // if the owner is unable to create an account, it will return the string reason which should be as in manual.
            Assert.equal(reason,string("Error, Owner Prohibited"),"Owner not giving the right error in ether transfer!");
        }
        Assert.equal(Ec, 0,"Error - Owner Cannot Transfer Money");
    }

    /// #sender: account-0 (sender is account at index '0')
    function testOwnerForWithdrawal() public  
    {
        try TestSystem.withDraw(1000000000000000000)
        {
            // Here the owner is calling this function, IF he is able to make an account than case fails.
            Ec = 1;      
        }  
        catch Error(string memory reason)
        {
            // If the owner is unable to create an account, it comes here & the reason should be caught.
            // if the owner is unable to create an account, it will return the string reason which should be as in manual.
            Assert.equal(reason,string("Error, Owner Prohibited"),"Owner not giving the right error in withdrawal function.");
        }
        Assert.equal(Ec, 0,"Error - Owner Cannot Withdraw Money");
    }


    uint public flag_C = 0;
    /// #sender: account-0 (sender is account at index '0')
    function testAccountClosureOwner() public 
    {
        try TestSystem.closeAccount() 
        {
            flag_C = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("Error, Owner does not own an account"), "Owner cannot close an account.");
        }
        Assert.equal(flag_C, 0, "Should not close an account.");
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

    uint to = 0;
    /// #value: 20000000000000000000
    /// #sender: account-1 (sender is account at index '1')
    function nonOwnerAddTopUp() public payable {
        
        try TestSystem.depositTopUp{value:20000000000000000000}() 
        {
            to = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("Only Owner can call this function"), "Non owner can deposit topup!!");
        }
        Assert.equal(to, 0, "Non owner can deposit topup!!");
    }

    uint a = 0;
    /// #sender: account-1 (sender is account at index '1')
    function nonOwnerSetInterestRates() public {
        
        try TestSystem.setInterestRates(5, 10) 
        {
            a = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("Only the owner can set interest rates"), "Non owner can set interest rates!");
        }
        Assert.equal(a, 0, "Non owner can set interest rates!");
    }
    
    uint b = 0;
    /// #sender: account-1 (sender is account at index '1')
    function nonOwnerAddDepositInterest() public {
        
        try TestSystem.addDepositInterest() 
        {
            b = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("Only the owner can add interest to deposits"), "Non owner can add deposit interests");
        }
        Assert.equal(b, 0, "Non owner can add deposit interests");
    }

    uint c = 0;
    /// #sender: account-1 (sender is account at index '1')
    function nonOwnerAddLoanInterest() public {
        
        try TestSystem.addLoanInterest() 
        {
            c = 1;
        } 
        catch Error(string memory reason) 
        {
            Assert.equal(reason, string("Only the owner can add interest to loans"), "Non owner can add loan interests");
        }
        Assert.equal(c, 0, "Non owner can add loan interests");
    }

}