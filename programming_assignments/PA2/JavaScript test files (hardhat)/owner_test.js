const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");

describe("Owner Rights", function () {
  let BankingSystem, banking, owner, user1, user2, user3;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    BankingSystem = await ethers.getContractFactory("BankingSystem");
    banking = await BankingSystem.deploy();
  });

  // This function is to test if the owner is prohibited to create an account & if it gives the right error
  it("1_Test", async function () {
    await expect(
      banking.connect(owner).openAccount("Amaan", "Ahmed")
    ).to.be.revertedWith("Error, Owner Prohibited");
  });

  // Check owner getDetails
  it("2_Test", async function () {
    await expect(banking.connect(owner).getDetails()).to.be.revertedWith(
      "No Account"
    );
  });

  // This function is to test if the owner is prohibited to take a loan & if it gives the right error
  it("3_Test", async function () {
    await expect(
      banking.connect(owner).TakeLoan(ethers.parseEther("1"))
    ).to.be.revertedWith("Error, Owner Prohibited");
  });

  // This function is to test if the owner is prohibited to transfer ETH & if it gives the right error
  it("4_Test", async function () {
    await expect(
      banking.connect(owner).TransferEth(user2.address, ethers.parseEther("5"))
    ).to.be.revertedWith("Error, Owner Prohibited");
  });

  // This function is to test if the owner is prohibited to withdraw & if it gives the right error
  it("5_Test", async function () {
    await expect(
      banking.connect(owner).withDraw(ethers.parseEther("1"))
    ).to.be.revertedWith("Error, Owner Prohibited");
  });

  // Owner cannot close account
  it("6_Test", async function () {
    await expect(banking.connect(owner).closeAccount()).to.be.revertedWith(
      "Error, Owner does not own an account"
    );
  });

  // Only the owner can depositTopUp
  it("7_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await expect(
      banking.connect(user1).depositTopUp({ value: ethers.parseEther("5") })
    ).to.be.revertedWith("Only Owner can call this function");
  });

  // Only the owner can set interest rates
  it("8_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await expect(
      banking.connect(user1).setInterestRates(5, 10)
    ).to.be.revertedWith("Only the owner can set interest rates");
  });

  // Only the owner can add deposit interest
  it("9_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await expect(
      banking.connect(user1).addDepositInterest()
    ).to.be.revertedWith("Only the owner can add interest to deposits");
  });

  // Only the owner can add loan interest
  it("10_Test", async function () {
    await banking.connect(user1).openAccount("Amaan", "Ahmed");
    await expect(
      banking.connect(user1).addLoanInterest()
    ).to.be.revertedWith("Only the owner can add interest to loans");
  });


});
