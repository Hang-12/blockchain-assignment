// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SupplyChainManager {
    address public owner;

    enum RawMaterialStatus { Created, Supplied, Received }
    enum ProductStatus { Created, Shipped, Received }

    struct RawMaterial {
        uint id;
        string name;
        uint quantity;
        uint price;
        address supplier;
        address manufacturer;
        RawMaterialStatus status;
    }

    struct Product {
        uint id;
        string name;
        uint quantity;
        uint price;
        address manufacturer;
        address retailer;
        ProductStatus status;
    }

    mapping(uint => RawMaterial) public rawMaterials;
    mapping(uint => Product) public products;

    uint public rawMaterialCount;
    uint public productCount;

    event RawMaterialSupplied(uint rawMaterialId, address supplier);
    event RawMaterialReceived(uint rawMaterialId, address manufacturer);
    event ProductShipped(uint productId, address manufacturer);
    event ProductReceived(uint productId, address retailer);
    event PaymentProcessed(uint productId, address retailer, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyManufacturer(uint _rawMaterialId) {
        require(msg.sender == rawMaterials[_rawMaterialId].manufacturer, "Not authorized");
        _;
    }

    modifier onlyRetailer(uint _productId) {
        require(msg.sender == products[_productId].retailer, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Raw Material Management
    function createRawMaterial(
        string memory _name,
        uint _quantity,
        uint _price,
        address _supplier,
        address _manufacturer
    ) public {
        rawMaterialCount++;
        rawMaterials[rawMaterialCount] = RawMaterial(
            rawMaterialCount,
            _name,
            _quantity,
            _price,
            _supplier,
            _manufacturer,
            RawMaterialStatus.Created
        );
    }

    function supplyRawMaterial(uint _rawMaterialId) public {
        require(msg.sender == rawMaterials[_rawMaterialId].supplier, "Not authorized");
        require(rawMaterials[_rawMaterialId].status == RawMaterialStatus.Created, "Invalid status");

        rawMaterials[_rawMaterialId].status = RawMaterialStatus.Supplied;
        emit RawMaterialSupplied(_rawMaterialId, msg.sender);
    }

    function receiveRawMaterial(uint _rawMaterialId) public onlyManufacturer(_rawMaterialId) {
        require(rawMaterials[_rawMaterialId].status == RawMaterialStatus.Supplied, "Raw material not supplied yet");

        rawMaterials[_rawMaterialId].status = RawMaterialStatus.Received;
        emit RawMaterialReceived(_rawMaterialId, msg.sender);
    }

    // Product Management
    function addProductManufacture(
        string memory _name,
        uint _quantity,
        uint _price,
        address _manufacturer,
        address _retailer
    ) public {
        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _quantity,
            _price,
            _manufacturer,
            _retailer,
            ProductStatus.Created
        );
    }

    function shipProduct(uint _productId) public {
        require(msg.sender == products[_productId].manufacturer, "Not authorized");
        require(products[_productId].status == ProductStatus.Created, "Invalid status");

        products[_productId].status = ProductStatus.Shipped;
        emit ProductShipped(_productId, msg.sender);
    }

    function receiveProduct(uint _productId) public onlyRetailer(_productId) {
        require(products[_productId].status == ProductStatus.Shipped, "Product not shipped yet");

        products[_productId].status = ProductStatus.Received;
        emit ProductReceived(_productId, msg.sender);
    }

    function processPayment(
    uint _id, // ID of the raw material or product
    string memory _type // "rawMaterial" or "product"
    ) public payable {
        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("rawMaterial"))) {
            // Payment for raw materials (manufacturer pays supplier)
            RawMaterial memory rawMaterial = rawMaterials[_id];
            require(msg.sender == rawMaterial.manufacturer, "Only manufacturer can pay for raw materials");
            require(rawMaterial.status == RawMaterialStatus.Received, "Raw material not received yet");

            uint amount = msg.value;
            payable(rawMaterial.supplier).transfer(amount);
            emit PaymentProcessed(_id, msg.sender, amount);
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("product"))) {
            // Payment for products (retailer pays manufacturer)
            Product memory product = products[_id];
            require(msg.sender == product.retailer, "Only retailer can pay for products");
            require(product.status == ProductStatus.Received, "Product not received yet");

            uint amount = msg.value;
            payable(product.manufacturer).transfer(amount);
            emit PaymentProcessed(_id, msg.sender, amount);
        } else {
            revert("Invalid payment type");
        }
    }

    // Getters
    function getRawMaterial(uint _rawMaterialId) public view returns (
        string memory, uint, uint, address, address, RawMaterialStatus
    ) {
        RawMaterial memory rm = rawMaterials[_rawMaterialId];
        return (rm.name, rm.quantity, rm.price, rm.supplier, rm.manufacturer, rm.status);
    }

    function getProduct(uint _productId) public view returns (
        string memory, uint, uint, address, address, ProductStatus
    ) {
        Product memory p = products[_productId];
        return (p.name, p.quantity, p.price, p.manufacturer, p.retailer, p.status);
    }
}