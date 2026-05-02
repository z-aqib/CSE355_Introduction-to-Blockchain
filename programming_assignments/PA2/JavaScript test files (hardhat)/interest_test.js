const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Interest Banking", function () {
  let BankingSystem, banking, owner, user1, user2, user3;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    BankingSystem = await ethers.getContractFactory("BankingSystem");
    banking = await BankingSystem.deploy();
  });

  // Owner should set interest rates successfully
  it("1_Test", async function () {
    await banking.connect(owner).setInterestRates(5, 10);

    expect(await banking.DepositInterestRate()).to.equal(5);
    expect(await banking.LoanInterestRate()).to.equal(10);
  });

  // Correct addition of interest to deposit balance (paid from operational funds)
  it("2_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await banking.connect(user2).openAccount("Zain", "Imran");
    await banking.connect(user3).openAccount("Rohaim", "Imran");

    await banking.connect(user1).depositAmount({ value: ethers.parseEther("20") });
    await banking.connect(user2).depositAmount({ value: ethers.parseEther("20") });
    await banking.connect(user3).depositAmount({ value: ethers.parseEther("20") });

    // Add operational funds so deposit interest can be paid
    await banking.connect(owner).depositOperationalFunds({ value: ethers.parseEther("10") });

    await banking.connect(owner).setInterestRates(10, 10); // 10% interest
    await banking.connect(owner).addDepositInterest();

    const details_1 = await banking.connect(user1).getDetails();
    const details_2 = await banking.connect(user2).getDetails();
    const details_3 = await banking.connect(user3).getDetails();

    expect(details_1[0]).to.equal(ethers.parseEther("22"));
    expect(details_2[0]).to.equal(ethers.parseEther("22"));
    expect(details_3[0]).to.equal(ethers.parseEther("22"));

    // Operational funds should decrease by total interest paid (6 ETH)
    expect(await banking.OperationalFunds()).to.equal(ethers.parseEther("4"));
  });

  // Correct addition of loan interest (goes into interestLoan)
  it("3_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await banking.connect(user2).openAccount("Zain", "Imran");
    await banking.connect(user3).openAccount("Rohaim", "Imran");

    await banking.connect(user1).depositAmount({ value: ethers.parseEther("20") });
    await banking.connect(user2).depositAmount({ value: ethers.parseEther("20") });
    await banking.connect(user3).depositAmount({ value: ethers.parseEther("20") });

    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("50") });

    await banking.connect(user1).TakeLoan(ethers.parseEther("10"));
    await banking.connect(user2).TakeLoan(ethers.parseEther("10"));
    await banking.connect(user3).TakeLoan(ethers.parseEther("10"));

    await banking.connect(owner).setInterestRates(10, 10); // 10% loan interest
    await banking.connect(owner).addLoanInterest();

    const details_1 = await banking.connect(user1).getDetails();
    const details_2 = await banking.connect(user2).getDetails();
    const details_3 = await banking.connect(user3).getDetails();

    // principal stays 10, interest should become 1
    expect(details_1[3]).to.equal(ethers.parseEther("10")); 
    expect(details_1[4]).to.equal(ethers.parseEther("1"));  

    expect(details_2[3]).to.equal(ethers.parseEther("10"));
    expect(details_2[4]).to.equal(ethers.parseEther("1"));

    expect(details_3[3]).to.equal(ethers.parseEther("10"));
    expect(details_3[4]).to.equal(ethers.parseEther("1"));
  });

  // Cannot close account with unpaid loan
  it("4_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("20") });
    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("20") });
    await banking.connect(user1).TakeLoan(ethers.parseEther("10"));

    await expect(
      banking.connect(user1).closeAccount()
    ).to.be.revertedWith("Dues remaining, cannot close account before repayment");
  });

  // Can close account if loan (principal + interest) is repaid
  it("5_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("20") });
    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("20") });
    await banking.connect(user1).TakeLoan(ethers.parseEther("10"));

    await banking.connect(owner).setInterestRates(0, 10);
    await banking.connect(owner).addLoanInterest(); // adds 1 ETH interest

    // repay 11 ETH (10 principal + 1 interest)
    await banking.connect(user1).returnLoan({ value: ethers.parseEther("11") });

    // get details of user1 and withdraw the remaining balance
    const details = await banking.connect(user1).getDetails();    
    await banking.connect(user1).withDraw(details[0]); // withdraw remaining balance to make it zero
    await banking.connect(user1).closeAccount();

    await expect(
      banking.connect(user1).getDetails()
    ).to.be.revertedWith("No Account");
  });

  // Cannot close account with balance
  it("6_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("20") });

    await expect(
      banking.connect(user1).closeAccount()
    ).to.be.revertedWith("Outstanding balance, withdraw it to close your account");
  });

  // Closing already closed account
  it("7_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await banking.connect(user1).closeAccount();

    await expect(
      banking.connect(user1).closeAccount()
    ).to.be.revertedWith("No Account Exists");
  });

  // Repayment priority: interest first then principal
  it("8_Test", async function () {
    await banking.connect(user1).openAccount("Ali", "Test");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("20") });
    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("50") });

    await banking.connect(user1).TakeLoan(ethers.parseEther("10"));
    await banking.connect(owner).setInterestRates(0, 10); 
    await banking.connect(owner).addLoanInterest(); // adds 1 ETH interest

    // repay 5 ETH (should reduce interest first, then principal)
    await banking.connect(user1).returnLoan({ value: ethers.parseEther("5") });

    const details = await banking.connect(user1).getDetails();

    expect(details[3]).to.equal(ethers.parseEther("6"));  // principal reduced to 6
    expect(details[4]).to.equal(0);                       // interest fully cleared
    expect(await banking.OperationalFunds()).to.equal(ethers.parseEther("1")); // 1 ETH interest collected
    expect(await banking.LoanFunds()).to.equal(ethers.parseEther("44"));        // 4 ETH principal repaid
  });

});
