const Retailer = artifacts.require("Retailer");

module.exports = async function(callback) {
    try {
        let retailer = await Retailer.deployed();
        console.log("Retailer Contract Address:", retailer.address);
    } catch (error) {
        console.error("Error fetching contract address:", error);
    }
    callback();
};