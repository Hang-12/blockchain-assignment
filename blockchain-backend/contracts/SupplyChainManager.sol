// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccountVerification.sol";

contract SupplyChainManager {
    address public owner;
    AccountVerification public accountVerification;

    struct RawMaterial {
        uint id;
        string name;
        uint quantity;
        uint price;
        address supplier;
        string status; // Changed from enum to string
    }

    struct Product {
        uint id;
        string name;
        uint quantity;
        uint price;
        address manufacturer;
        string status; // Changed from enum to string
    }

    mapping(uint => RawMaterial) public rawMaterials;
    mapping(uint => Product) public products;

    uint public rawMaterialCount;
    uint public productCount;

    event RawMaterialCreated(uint rawMaterialId, address supplier);
    event RawMaterialSupplied(uint rawMaterialId);
    event RawMaterialReceived(uint rawMaterialId, address manufacturer);
    event ProductCreated(uint productId, address manufacturer);
    event ProductShipped(uint productId);
    event ProductReceived(uint productId);
    event PaymentProcessed(uint id, address sender, uint amount);

    modifier onlyVerifiedSupplier() {
        (string memory role, bool isVerified) = accountVerification.getUser(msg.sender);
        require(isVerified && keccak256(abi.encodePacked(role)) == keccak256("Supplier"), "Only verified suppliers can perform this action");
        _;
    }

    modifier onlyVerifiedManufacturer() {
        (string memory role, bool isVerified) = accountVerification.getUser(msg.sender);
        require(isVerified && keccak256(abi.encodePacked(role)) == keccak256("Manufacturer"), "Only verified manufacturers can perform this action");
        _;
    }

    constructor(address _accountVerificationAddress) {
        owner = msg.sender;
        accountVerification = AccountVerification(_accountVerificationAddress);
    }

    // Raw Material Management
    function createRawMaterial(
        string memory _name,
        uint _quantity,
        uint _price
    ) public onlyVerifiedSupplier {
        rawMaterialCount++;
        rawMaterials[rawMaterialCount] = RawMaterial(
            rawMaterialCount,
            _name,
            _quantity,
            _price,
            msg.sender,
            "Created"
        );

        emit RawMaterialCreated(rawMaterialCount, msg.sender);
    }

    function supplyRawMaterial(uint _rawMaterialId) public {
        require(msg.sender == rawMaterials[_rawMaterialId].supplier, "Not authorized");
        require(keccak256(abi.encodePacked(rawMaterials[_rawMaterialId].status)) == keccak256("Created"), "Invalid status");

        rawMaterials[_rawMaterialId].status = "Supplied";
        emit RawMaterialSupplied(_rawMaterialId);
    }

    function receiveRawMaterial(uint _rawMaterialId) public onlyVerifiedManufacturer {
        require(keccak256(abi.encodePacked(rawMaterials[_rawMaterialId].status)) == keccak256("Supplied"), "Raw material not supplied yet");

        rawMaterials[_rawMaterialId].status = "Received";
        emit RawMaterialReceived(_rawMaterialId, msg.sender);
    }

    // Product Management
    function addProduct(
        string memory _name,
        uint _quantity,
        uint _price
    ) public onlyVerifiedManufacturer {
        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _quantity,
            _price,
            msg.sender,
            "Created"
        );

        emit ProductCreated(productCount, msg.sender);
    }

    function shipProduct(uint _productId) public {
        require(msg.sender == products[_productId].manufacturer, "Not authorized");
        require(keccak256(abi.encodePacked(products[_productId].status)) == keccak256("Created"), "Invalid status");

        products[_productId].status = "Shipped";
        emit ProductShipped(_productId);
    }

    function receiveProduct(uint _productId) public {
        require(keccak256(abi.encodePacked(products[_productId].status)) == keccak256("Shipped"), "Product not shipped yet");

        products[_productId].status = "Received";
        emit ProductReceived(_productId);
    }

    // Payment Processing
    function processPayment(uint _id, string memory _type) public payable {
        if (keccak256(abi.encodePacked(_type)) == keccak256("rawMaterial")) {
            RawMaterial memory rawMaterial = rawMaterials[_id];
            require(msg.sender != rawMaterial.supplier, "Supplier cannot pay themselves");
            require(keccak256(abi.encodePacked(rawMaterial.status)) == keccak256("Received"), "Raw material not received yet");

            uint amount = msg.value;
            payable(rawMaterial.supplier).transfer(amount);
            emit PaymentProcessed(_id, msg.sender, amount);
        } else if (keccak256(abi.encodePacked(_type)) == keccak256("product")) {
            Product memory product = products[_id];
            require(msg.sender != product.manufacturer, "Manufacturer cannot pay themselves");
            require(keccak256(abi.encodePacked(product.status)) == keccak256("Received"), "Product not received yet");

            uint amount = msg.value;
            payable(product.manufacturer).transfer(amount);
            emit PaymentProcessed(_id, msg.sender, amount);
        } else {
            revert("Invalid payment type");
        }
    }
}
