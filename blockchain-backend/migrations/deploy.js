const AccountVerification = artifacts.require("AccountVerification");
const SupplyChainManager = artifacts.require("SupplyChainManager");

module.exports = function (deployer) {
  deployer.deploy(AccountVerification);
  deployer.deploy(SupplyChainManager);
};

