import Web3 from "web3";
import RetailerABI from "../../../blockchain-backend/build/contracts/Retailer.json";

let web3: Web3 | null = null;
if (typeof window !== "undefined" && window.ethereum) {
  web3 = new Web3(window.ethereum);
} else {
  console.error("MetaMask not detected!");
}

const contractAddress = "0x54DC373F9a6e667BB53AF9e9f8B45539212B2Ca5";
const retailerContract = web3 ? new web3.eth.Contract(RetailerABI.abi, contractAddress) : null;

export { web3, retailerContract };