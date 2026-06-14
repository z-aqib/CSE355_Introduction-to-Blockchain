const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");

describe("Exceptional Cases", function () {
  let BankingSystem, banking, owner, user1, user2, user3;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    BankingSystem = await ethers.getContractFactory("BankingSystem");
    banking = await BankingSystem.deploy();
  });

  // Should not allow depositing less than 1 ether
  it("1_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await expect(
      banking.connect(user1).depositAmount({ value: ethers.parseEther("0.00000000000005") })
    ).to.be.revertedWith("Low Deposit");
  });

  // Should not allow deposit without account
  it("2_Test", async function () {
    await expect(
      banking.connect(user3).depositAmount({ value: ethers.parseEther("5") })
    ).to.be.revertedWith("No Account");
  });

  // Should not allow withdrawing more than balance
  it("3_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    banking.connect(user3).depositAmount({ value: ethers.parseEther("0.5") })
    await expect(
      banking.connect(user1).withDraw(ethers.parseEther("1"))
    ).to.be.revertedWith("Insufficient Funds");
  });


  // Should not allow transfer more than balance
  it("4_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user2).openAccount("A", "Block");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("2") });
    await expect(
      banking.connect(user1).TransferEth(user2, ethers.parseEther("4"))
    ).to.be.revertedWith("Insufficient Funds");
  });

  // Should not allow transferring to non-existing account
    it("5_Test", async function () {
        await banking.connect(user1).openAccount("Zain", "Imran");
        await banking.connect(user1).depositAmount({ value: ethers.parseEther("2") });
        await expect(
        banking.connect(user1).TransferEth(user3, ethers.parseEther("1"))
        ).to.be.revertedWith("Recipient account does not exist");
    });

  // Should not allow loan with no funds
  it("6_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await expect(
      banking.connect(user1).TakeLoan(ethers.parseEther("1"))
    ).to.be.revertedWith("Insufficient Loan Funds");
  });

  // Loan limit exceeded
  it("7_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("2") });

    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("10") });

    await expect(
      banking.connect(user1).TakeLoan(ethers.parseEther("5"))
    ).to.be.revertedWith("Loan Limit Exceeded");
  });

  // Should not return loan if user has none
  it("8_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await expect(
      banking.connect(user1).returnLoan({ value: ethers.parseEther("5") })
    ).to.be.revertedWith("No Loan");
  });

  // Should not allow paying more than owed
  it("9_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("2") });
    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("10") });
    await banking.connect(user1).TakeLoan(ethers.parseEther("1"));

    await expect(
      banking.connect(user1).returnLoan({ value: ethers.parseEther("5") })
    ).to.be.revertedWith("Owed Amount Exceeded");
  });

  // Should allow paying back partial loan
  it("10_Test", async function () {
    await banking.connect(user1).openAccount("Zain", "Imran");
    await banking.connect(user1).depositAmount({ value: ethers.parseEther("2") });
    await banking.connect(owner).depositTopUp({ value: ethers.parseEther("10") });
    await banking.connect(user1).TakeLoan(ethers.parseEther("1"));

    await banking.connect(user1).returnLoan({ value: ethers.parseEther("0.5") });

    expect((await banking.connect(user1).InquireLoan())[0]).to.equal(ethers.parseEther("0.5"));
  });

  // User with no account asking for his details
  it("11._Test", async function () {
    await expect(
      banking.connect(user3).getDetails()
    ).to.be.revertedWith("No Account");
  });

  // Existing user opening account again
    it("12._Test", async function () {
        await banking.connect(user1).openAccount("Zain", "Imran");
        await expect(
        banking.connect(user1).openAccount("Zain", "Imran")
        ).to.be.revertedWith("Account already exists");
    });

    // User with no account depositing
    it("13._Test", async function () {
        await expect(
        banking.connect(user3).depositAmount({ value: ethers.parseEther("5") })
        ).to.be.revertedWith("No Account");
    });

    // User with no account withdrawing
    it("14._Test", async function () {
        await expect(
        banking.connect(user3).withDraw(ethers.parseEther("1"))
        ).to.be.revertedWith("No Account");
    });

    // User with no account returning loan
    it("15._Test", async function () {
        await expect(
        banking.connect(user3).returnLoan({ value: ethers.parseEther("10") })
        ).to.be.revertedWith("No Account");
    });

    // User with no account taking loan
    it("16._Test", async function () {
        await expect(
        banking.connect(user3).TakeLoan(ethers.parseEther("1"))
        ).to.be.revertedWith("No Account");
    });
});
