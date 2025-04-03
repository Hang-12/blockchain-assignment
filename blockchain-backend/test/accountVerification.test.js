const AccountVerification = artifacts.require("AccountVerification");

contract("AccountVerification", (accounts) => {
  const admin = accounts[0];
  const supplier = accounts[1];
  const manufacturer = accounts[2];
  const retailer = accounts[3];

  let instance;

  before(async () => {
    instance = await AccountVerification.deployed();
  });

  it("should deploy the contract correctly", async () => {
    assert(instance.address !== undefined, "Contract not deployed correctly");
  });

  it("should register a new user", async () => {
    const tx = await instance.registerUser(supplier, 0, { from: admin });
    
    assert.equal(tx.logs[0].event, "UserRegistered", "UserRegistered event not emitted");
    
    const user = await instance.getUser(supplier);
    assert(user[0].eq(web3.utils.toBN(0)), "User role mismatch");
    assert.equal(user[1], false, "User should not be verified upon registration");
  });

  it("should verify a user", async () => {
    await instance.registerUser(manufacturer, 1, { from: admin });
    const tx = await instance.verifyUser(manufacturer, { from: admin });

    assert.equal(tx.logs[0].event, "UserVerified", "UserVerified event not emitted");

    const user = await instance.getUser(manufacturer);
    assert(user[0].eq(web3.utils.toBN(1)), "User role mismatch");
    assert.equal(user[1], true, "User should be verified");
  });

  it("should revoke a user's verification", async () => {
    await instance.registerUser(retailer, 2, { from: admin });
    await instance.verifyUser(retailer, { from: admin });
    
    const tx = await instance.revokeUser(retailer, { from: admin });

    assert.equal(tx.logs[0].event, "UserRevoked", "UserRevoked event not emitted");

    const user = await instance.getUser(retailer);
    assert(user[0].eq(web3.utils.toBN(2)), "User role mismatch");
    assert.equal(user[1], false, "User should not be verified after revocation");
  });

  it("should revert when non-admin tries to register a user", async () => {
    try {
      await instance.registerUser(accounts[4], 0, { from: accounts[1] });
      assert.fail("Expected revert not received");
    } catch (error) {
      assert(error.message.includes("Only admin can perform this action"), "Error message mismatch");
    }
  });

  it("should revert when trying to verify an unregistered user", async () => {
    try {
      await instance.verifyUser(accounts[5], { from: admin });
      assert.fail("Expected revert not received");
    } catch (error) {
      assert(error.message.includes("User not registered"), "Error message mismatch");
    }
  });

  it("should revert when trying to verify an already verified user", async () => {
    await instance.registerUser(accounts[6], 0, { from: admin });
    await instance.verifyUser(accounts[6], { from: admin });

    try {
      await instance.verifyUser(accounts[6], { from: admin });
      assert.fail("Expected revert not received");
    } catch (error) {
      assert(error.message.includes("User already verified"), "Error message mismatch");
    }
  });

  it("should revert when trying to revoke an unverified user", async () => {
    await instance.registerUser(accounts[7], 1, { from: admin });

    try {
      await instance.revokeUser(accounts[7], { from: admin });
      assert.fail("Expected revert not received");
    } catch (error) {
      assert(error.message.includes("User is not verified"), "Error message mismatch");
    }
  });

  it("should allow a revoked user to be re-verified", async () => {
    await instance.registerUser(accounts[8], 2, { from: admin });
    await instance.verifyUser(accounts[8], { from: admin });
    await instance.revokeUser(accounts[8], { from: admin });

    const tx = await instance.verifyUser(accounts[8], { from: admin });
    assert.equal(tx.logs[0].event, "UserVerified", "User should be re-verified");

    const user = await instance.getUser(accounts[8]);
    assert.equal(user[1], true, "User should be verified again");
  });

  it("should return correct verification status", async () => {
    await instance.registerUser(accounts[9], 1, { from: admin });

    let isVerified = await instance.isUserVerified(accounts[9]);
    assert.equal(isVerified, false, "User should not be verified initially");

    await instance.verifyUser(accounts[9], { from: admin });
    
    isVerified = await instance.isUserVerified(accounts[9]);
    assert.equal(isVerified, true, "User should be verified");
  });
});
