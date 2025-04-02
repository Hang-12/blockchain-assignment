// const AccountVerification = artifacts.require("AccountVerification");
// const SupplyChainManager = artifacts.require("SupplyChainManager");

// module.exports = function (deployer) {
//   deployer.deploy(AccountVerification);
//   deployer.deploy(SupplyChainManager);
// };


const AccountVerification = artifacts.require("AccountVerification");
const SupplyChainManager = artifacts.require("SupplyChainManager");

module.exports = async function (deployer) {
  await deployer.deploy(AccountVerification);
  const accountVerification = await AccountVerification.deployed();
  
  await deployer.deploy(SupplyChainManager, accountVerification.address);
};