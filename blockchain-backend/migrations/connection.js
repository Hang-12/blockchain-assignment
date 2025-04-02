// Setup: npm install alchemy-sdk
const { Network, Alchemy } = require("alchemy-sdk");

// Optional config object, but defaults to demo api-key and eth-mainnet.
const settings = {
  apiKey: "488C1sUM1UQGfO8tX20nU0l1kDpt99Og", // Your Alchemy API Key
  network: Network.ETH_SEPOLIA, // Sepolia testnet
};

const alchemy = new Alchemy(settings);

// Define your addresses
const ADDRESSES = {
  deployer: "0xba02612f5EB353431022C4A0003d94728a573140",
  supplier: "0xDe17E1D510203113f166C063d41B0Eed090CE715",
  manufacturer: "0x48A370735770F7D56F42DA82Ca8a89639ef8b59D",
  retailer: "0xB1D96bB0C14D7CBE98a90D2be1fb088b29b5fE9D"
};

// Get balance for a specific role
async function getBalanceForRole(role) {
  if (!ADDRESSES[role]) {
    throw new Error(`Unknown role: ${role}`);
  }
  return getBalance(ADDRESSES[role]);
}

// Example: Get account balance
async function getBalance(address) {
  try {
    const balance = await alchemy.core.getBalance(address);
    console.log(`Balance for ${address}: ${balance}`);
    return balance;
  } catch (error) {
    console.error("Error fetching balance:", error);
    throw error;
  }
}

// Check balances for all roles
async function checkAllBalances() {
  console.log("Checking balances for all roles...");
  for (const [role, address] of Object.entries(ADDRESSES)) {
    const balance = await alchemy.core.getBalance(address);
    const balanceInEth = alchemy.core.utils.formatEther(balance);
    console.log(`${role.padEnd(12)}: ${address} - ${balanceInEth} ETH`);
  }
}

// Example: Get a block
async function getBlockInfo() {
  try {
    const blockInfo = await alchemy.core.getBlock("latest");
    console.log("Latest block info:", blockInfo);
    return blockInfo;
  } catch (error) {
    console.error("Error fetching block:", error);
    throw error;
  }
}

module.exports = {
  alchemy,
  ADDRESSES,
  getBlockInfo,
  getBalance,
  getBalanceForRole,
  checkAllBalances
};