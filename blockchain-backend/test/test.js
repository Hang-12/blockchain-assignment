const AccountVerification = artifacts.require("AccountVerification");
const SupplyChainManager = artifacts.require("SupplyChainManager");

contract("SupplyChainManager", (accounts) => {
  it("should deploy the contracts successfully", async () => {
    const accountVerification = await AccountVerification.deployed();
    const supplyChainManager = await SupplyChainManager.deployed();

    assert(accountVerification.address, "AccountVerification contract was not deployed");
    assert(supplyChainManager.address, "SupplyChainManager contract was not deployed");
  });
});