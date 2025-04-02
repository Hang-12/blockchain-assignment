const AccountVerification = artifacts.require("AccountVerification");

contract("AccountVerification", accounts => {
  // Assume the deployer/admin is accounts[0]
  const admin = accounts[0];
  // Use a test account (different from admin) for the user
  const testUser = accounts[1];

  let instance;

  before(async () => {
    instance = await AccountVerification.deployed();
  });

  it("should register a new user", async () => {
    // Using enum index 0 for Supplier (or adjust as needed)
    const userRole = 0; // 0: Supplier, 1: Manufacturer, 2: Retailer
    const tx = await instance.registerUser(testUser, userRole, { from: admin });

    // Check for the UserRegistered event (optional)
    const event = tx.logs.find(log => log.event === "UserRegistered");
    assert(event, "UserRegistered event should be emitted");
    assert.equal(event.args.userAddress, testUser, "Event should contain correct user address");
    assert.equal(event.args.role.toNumber(), userRole, "Event should contain correct user role");

    // Check user details via getUser
    const result = await instance.getUser(testUser);
    const role = result[0].toNumber();
    const isVerified = result[1];
    assert.equal(role, userRole, "User role should be set correctly");
    assert.equal(isVerified, false, "User should not be verified upon registration");
  });

  it("should verify the registered user", async () => {
    // Verify the user
    const tx = await instance.verifyUser(testUser, { from: admin });

    // Check for the UserVerified event (optional)
    const event = tx.logs.find(log => log.event === "UserVerified");
    assert(event, "UserVerified event should be emitted");
    assert.equal(event.args.userAddress, testUser, "Event should contain correct user address");

    // Check verification status using isUserVerified
    const verifiedStatus = await instance.isUserVerified(testUser);
    assert.equal(verifiedStatus, true, "User should be verified after verification");
  });

  it("should revoke the user's verification", async () => {
    // Revoke the user verification
    const tx = await instance.revokeUser(testUser, { from: admin });

    // Check for the UserRevoked event (optional)
    const event = tx.logs.find(log => log.event === "UserRevoked");
    assert(event, "UserRevoked event should be emitted");
    assert.equal(event.args.userAddress, testUser, "Event should contain correct user address");

    // Check that the user is no longer verified
    const verifiedStatus = await instance.isUserVerified(testUser);
    assert.equal(verifiedStatus, false, "User should not be verified after revocation");
  });

  it("should revert when calling getUser on an unregistered user", async () => {
    // Use an account that has not been registered
    try {
      await instance.getUser(accounts[2]);
      assert.fail("Expected getUser to revert for unregistered user");
    } catch (error) {
      assert(
        error.message.includes("User not registered"),
        "Expected revert error for unregistered user"
      );
    }
  });
});
