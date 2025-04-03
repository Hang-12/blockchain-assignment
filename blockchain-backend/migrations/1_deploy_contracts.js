const AccountVerification = artifacts.require("AccountVerification");
const SupplyChainManager = artifacts.require("SupplyChainManager");

module.exports = async function (deployer) {
  // deployer.deploy(AccountVerification);
  // deployer.deploy(SupplyChainManager);

  await deployer.deploy(AccountVerification);
    const accountVerifierInstance = await AccountVerification.deployed();

    // Deploy SupplyChainManager with the address of AccountVerification
    await deployer.deploy(SupplyChainManager, accountVerifierInstance.address);
};