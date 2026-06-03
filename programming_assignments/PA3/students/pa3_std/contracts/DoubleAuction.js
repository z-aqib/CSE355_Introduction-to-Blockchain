// ------------------------------------------------------------
// DoubleAuction.js
// ------------------------------------------------------------
// Purpose:
// This script calls the doubleAuction() function on the deployed
// DoubleAuction smart contract.
//
// Important for grader:
// It must print exactly one of these:
// Double Auction Successful
// Double Auction not Successful
// ------------------------------------------------------------

const net = require("net");
const path = require("path");
const fs = require("fs-extra");
const Web3 = require("web3");

// ------------------------------------------------------------
// Load Web3 connection details
// ------------------------------------------------------------

const web3dataJson = JSON.parse(fs.readFileSync("web3data.json", "utf-8"));
const location = web3dataJson.location;
const password = web3dataJson.password;

const web3 = new Web3(new Web3.providers.IpcProvider(location, net));

// ------------------------------------------------------------
// Load compiled contract ABI
// ------------------------------------------------------------

const contractJsonPath = path.resolve(__dirname, "DoubleAuction.json");
const contractJson = JSON.parse(fs.readFileSync(contractJsonPath));
const contractAbi = contractJson.abi;

// ------------------------------------------------------------
// Load deployed contract address
// ------------------------------------------------------------

const data = fs.readFileSync("contAddressDoubleAuction.json", "utf-8");
const contAddress = JSON.parse(data.toString()).address;

// This object lets us call Solidity functions from JavaScript.
const contractInstance = new web3.eth.Contract(contractAbi, contAddress);

// ------------------------------------------------------------
// Run double auction
// ------------------------------------------------------------

async function runDoubleAuction(fromAddress) {
  try {
    // doubleAuction changes blockchain state, so we use .send()
    await contractInstance.methods.doubleAuction().send({
      from: fromAddress,
      gasLimit: "0xe00000",
    });

    // Exact string expected by testResults.sh
    console.log("Double Auction Successful");
  } catch (error) {
    // If the auction interval has not passed, Solidity reverts.
    // Exact string expected by testResults.sh
    console.log("Double Auction not Successful");
  }
}

// ------------------------------------------------------------
// Main function
// ------------------------------------------------------------

async function main() {
  const accounts = await web3.eth.getAccounts();
  const myAccount = accounts[0];

  // Unlock account so it can send the auction transaction.
  await web3.eth.personal.unlockAccount(myAccount, password, 60);

  await runDoubleAuction(myAccount);
}

main().then(() => process.exit(0));
