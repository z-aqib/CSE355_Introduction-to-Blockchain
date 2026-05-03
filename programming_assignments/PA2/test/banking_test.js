const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");

describe("Basic Banking", function () {
  let BankingSystem, banking, owner, user1, user2, user3;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    BankingSystem = await ethers.getContractFactory("BankingSystem");
    banking = await BankingSystem.deploy();
  });

  // User1 should create account correctly
  it("1_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    const details = await banking.connect(user1).getDetails();
    expect(details[0]).to.equal(0n); // balance
    expect(details[1]).to.equal("Zain");
    expect(details[2]).to.equal("Imran");
    expect(details[3]).to.equal(0n); // loan
  });

  // User1 deposit should update balance
  it("2_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    const BankSystemBalance_start = await banking.AmountInBank();

    await banking.connect(user1).depositAmount({ value: ethers.parseEther("10") });

    const BankSystemBalance_end = await banking.AmountInBank();
    const details = await banking.connect(user1).getDetails();

    expect(details[0]).to.equal(ethers.parseEther("10"));
    expect(BankSystemBalance_start + ethers.parseEther("10")).to.equal(BankSystemBalance_end);
  });

  // User1 should transfer ETH to user2
  it("3_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user2).openAccount("A", "Block");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("10") });

    const BankSystemBalance_start = await banking.AmountInBank();
    await banking.connect(user1).TransferEth(user2.address, ethers.parseEther("5"));
    const BankSystemBalance_end = await banking.AmountInBank();

    const user1Details = await banking.connect(user1).getDetails();
    expect(user1Details[0]).to.equal(ethers.parseEther("5"));

    const user2Details = await banking.connect(user2).getDetails();
    expect(user2Details[0]).to.equal(ethers.parseEther("5"));

    expect(BankSystemBalance_start).to.equal(BankSystemBalance_end);
  });

  // Check withdrawal from user
  it("4_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("10") });
    
    const user1Details_start = await banking.connect(user1).getDetails();
    const BankSystemBalance_start = await banking.AmountInBank();
    
    await banking.connect(user1).withDraw(ethers.parseEther("0.2"));

    const user1Details_end = await banking.connect(user1).getDetails();
    const BankSystemBalance_end = await banking.AmountInBank();

    expect(BankSystemBalance_start - ethers.parseEther("0.2")).to.equal(BankSystemBalance_end);
    expect(user1Details_start[0] - ethers.parseEther("0.2")).to.equal(user1Details_end[0]);
    expect(user1Details_start[3]).to.equal(user1Details_end[3]); // loan unchanged
  });

  // Check loan fund (depositTopUp)
  it("5_Test", async function () {
    const BankSystemBalance_start = await banking.AmountInBank();
    const loanFunds_start = await banking.LoanFunds();

    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("10") });

    const BankSystemBalance_end = await banking.AmountInBank();
    const loanFunds_end = await banking.LoanFunds();

    expect(BankSystemBalance_start + ethers.parseEther("10")).to.equal(BankSystemBalance_end);
    expect(loanFunds_start + ethers.parseEther("10")).to.equal(loanFunds_end);
  });


  // Check operational_funds deposit
  it("6_Test", async function () {
    const BankSystemBalance_start = await banking.AmountInBank();
    const operational_funds_start = await banking.OperationalFunds();
    
    await banking.connect(owner).depositOperationalFunds({ value: ethers.parseEther("10") });
    
    const BankSystemBalance_end = await banking.AmountInBank();
    const operational_funds_end = await banking.OperationalFunds();

    expect(BankSystemBalance_start + ethers.parseEther("10")).to.equal(BankSystemBalance_end);
    expect(operational_funds_start+ethers.parseEther("10")).to.equal(operational_funds_end);
  })

  // Check loan transfer
  it("7_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("1") });
    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("10") });

    const BankSystemBalance_start = await banking.AmountInBank();
    const loanFunds_start = await banking.LoanFunds();
    const details_start = await banking.connect(user1).getDetails();

    await banking.connect(user1).TakeLoan(ethers.parseEther("1"));

    const BankSystemBalance_end = await banking.AmountInBank();
    const loanFunds_end = await banking.LoanFunds();
    const details_end = await banking.connect(user1).getDetails();

    const loanTaken = (await banking.connect(user1).InquireLoan())[0];

    expect(loanTaken).to.equal(ethers.parseEther("1"));
    expect(BankSystemBalance_start - ethers.parseEther("1")).to.equal(BankSystemBalance_end);
    expect(details_start[0]).to.equal(details_end[0]); // balance unchanged
    expect(details_start[3] + ethers.parseEther("1")).to.equal(details_end[3]);
    expect(loanFunds_start - ethers.parseEther("1")).to.equal(loanFunds_end);
  });

  // Check return loan
  it("8_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("1") });
    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("10") });
    await banking.connect(user1).TakeLoan(ethers.parseEther("1"));
    
    const BankSystemBalance_start = await banking.AmountInBank();
    const details_start = await banking.connect(user1).getDetails();
    const loanFunds_start = await banking.LoanFunds();

    await banking.connect(user1).returnLoan({ value: ethers.parseEther("1") });

    const BankSystemBalance_end = await banking.AmountInBank();
    const details_end = await banking.connect(user1).getDetails();
    const loanFunds_end = await banking.LoanFunds();

    const loanTaken = (await banking.connect(user1).InquireLoan())[0];

    expect(loanTaken).to.equal(0n);
    expect(BankSystemBalance_start + ethers.parseEther("1")).to.equal(BankSystemBalance_end);
    expect(details_start[0]).to.equal(details_end[0]); // balance unchanged
    expect(details_start[3] - ethers.parseEther("1")).to.equal(details_end[3]);
    expect(loanFunds_start + ethers.parseEther("1")).to.equal(loanFunds_end);
  });

  // Closing an account
  it("9_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user1).closeAccount();

    await expect(
        banking.connect(user1).getDetails()
      ).to.be.revertedWith("No Account");
    });

});
