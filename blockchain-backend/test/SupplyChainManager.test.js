const SupplyChainManager = artifacts.require("SupplyChainManager");
const AccountVerification = artifacts.require("AccountVerification");

contract("SupplyChainManager", (accounts) => {
    const [admin, supplier, manufacturer, retailer] = accounts;
    let supplyChainManager, accountVerifier;

    before(async () => {
        accountVerifier = await AccountVerification.new({ from: admin });
        supplyChainManager = await SupplyChainManager.new(accountVerifier.address, { from: admin });

        // Register & verify supplier
        await accountVerifier.registerUser(supplier, 0, { from: admin });
        const isSupplierRegistered = await accountVerifier.getUser(supplier);

        await accountVerifier.verifyUser(supplier, { from: admin });
        const isSupplierVerified = await accountVerifier.isUserVerified(supplier);

        // Register & verify manufacturer
        await accountVerifier.registerUser(manufacturer, 1, { from: admin });
        await accountVerifier.verifyUser(manufacturer, { from: admin });

        // Register & verify retailer
        await accountVerifier.registerUser(retailer, 2, { from: admin });
        await accountVerifier.verifyUser(retailer, { from: admin });
    });

    it("should create a raw material by supplier", async () => {
        await supplyChainManager.createRawMaterial(
            "Iron Ore",
            100,
            web3.utils.toWei("0.001", "ether"),
            manufacturer,
            { from: supplier }
        );

        const rawMaterial = await supplyChainManager.getRawMaterial(1);
        assert.equal(rawMaterial[0], "Iron Ore", "Name mismatch");
        assert.equal(rawMaterial[1].toNumber(), 100, "Quantity mismatch");
    });

    it("should allow payment and supply raw material", async () => {
        await supplyChainManager.depositPayment(1, "rawMaterial", {
            from: manufacturer,
            value: web3.utils.toWei("0.001", "ether")
        });

        await supplyChainManager.supplyRawMaterial(1, { from: supplier });

        const rawMaterial = await supplyChainManager.getRawMaterial(1);
        assert.equal(rawMaterial[5].toNumber(), 1, "Should be Supplied");
    });

    it("should allow manufacturer to receive raw material", async () => {
        await supplyChainManager.receiveRawMaterial(1, { from: manufacturer });

        const rawMaterial = await supplyChainManager.getRawMaterial(1);
        assert.equal(rawMaterial[5].toNumber(), 2, "Should be Received");
    });

    it("should allow manufacturer to add product", async () => {
        await supplyChainManager.addProduct(
            "Steel Beam",
            50,
            web3.utils.toWei("0.001", "ether"),
            retailer,
            { from: manufacturer }
        );

        const product = await supplyChainManager.getProduct(1);
        assert.equal(product[0], "Steel Beam", "Product name mismatch");
        assert.equal(product[1].toNumber(), 50, "Quantity mismatch");
    });

    it("should allow retailer to deposit and manufacturer to ship", async () => {
        await supplyChainManager.depositPayment(1, "product", {
            from: retailer,
            value: web3.utils.toWei("0.001", "ether")
        });

        await supplyChainManager.shipProduct(1, { from: manufacturer });

        const product = await supplyChainManager.getProduct(1);
        assert.equal(product[5].toNumber(), 1, "Should be Shipped");
    });

    it("should allow retailer to receive product", async () => {
        await supplyChainManager.receiveProduct(1, { from: retailer });

        const product = await supplyChainManager.getProduct(1);
        assert.equal(product[5].toNumber(), 2, "Should be Received");
    });
});
