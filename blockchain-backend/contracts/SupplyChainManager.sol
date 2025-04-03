// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccountVerification.sol";

contract SupplyChainManager {
    AccountVerification public accountVerifier;
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
    mapping(uint => uint) public escrowBalance;

    uint public rawMaterialCount;
    uint public productCount;

    event RawMaterialCreated(uint rawMaterialId, address supplier);
    event RawMaterialSupplied(uint rawMaterialId, address supplier);
    event RawMaterialReceived(uint rawMaterialId, address manufacturer);
    event ProductCreated(uint productId, address manufacturer);
    event ProductShipped(uint productId, address manufacturer);
    event ProductReceived(uint productId, address retailer);
    event PaymentDeposited(uint id, address payer, uint amount);
    event PaymentReleased(uint id, address recipient, uint amount);

    modifier onlyVerifiedUser(AccountVerification.UserRole role) {
        (AccountVerification.UserRole userRole, bool isVerified) = accountVerifier.getUser(msg.sender);
        require(isVerified, "User not verified");
        require(userRole == role, "Unauthorized role");
        _;
    }

    modifier onlyAssignedManufacturer(uint _rawMaterialId) {
        require(msg.sender == rawMaterials[_rawMaterialId].manufacturer, 
            "Not assigned manufacturer");
        _;
    }

    modifier onlyAssignedRetailer(uint _productId) {
        require(msg.sender == products[_productId].retailer, 
            "Not assigned retailer");
        _;
    }

    constructor(address _accountVerifier) {
        owner = msg.sender;
        accountVerifier = AccountVerification(_accountVerifier);
    }

    // Raw Material Management
    function createRawMaterial(
        string memory _name,
        uint _quantity,
        uint _price,
        address _manufacturer
    ) public onlyVerifiedUser(AccountVerification.UserRole.Supplier) {
        (, bool mfgVerified) = accountVerifier.getUser(_manufacturer);
        require(mfgVerified, "Manufacturer not verified");

        rawMaterialCount++;
        rawMaterials[rawMaterialCount] = RawMaterial(
            rawMaterialCount,
            _name,
            _quantity,
            _price,
            msg.sender,
            _manufacturer,
            RawMaterialStatus.Created
        );
        emit RawMaterialCreated(rawMaterialCount, msg.sender);
    }

    function supplyRawMaterial(uint _rawMaterialId) public {
        RawMaterial storage rm = rawMaterials[_rawMaterialId];
        require(msg.sender == rm.supplier, "Not supplier");
        require(rm.status == RawMaterialStatus.Created, "Invalid status");
        
        rm.status = RawMaterialStatus.Supplied;
        emit RawMaterialSupplied(_rawMaterialId, msg.sender);
    }

    function receiveRawMaterial(uint _rawMaterialId) 
        public 
        onlyVerifiedUser(AccountVerification.UserRole.Manufacturer)
        onlyAssignedManufacturer(_rawMaterialId) 
    {
        RawMaterial storage rm = rawMaterials[_rawMaterialId];
        require(rm.status == RawMaterialStatus.Supplied, "Not supplied");
        
        rm.status = RawMaterialStatus.Received;
        emit RawMaterialReceived(_rawMaterialId, msg.sender);
        
        _releasePayment(_rawMaterialId, "rawMaterial", rm.supplier);
    }

    // Product Management
    function createProduct(
        string memory _name,
        uint _quantity,
        uint _price,
        address _retailer
    ) public onlyVerifiedUser(AccountVerification.UserRole.Manufacturer) {
        (, bool retailVerified) = accountVerifier.getUser(_retailer);
        require(retailVerified, "Retailer not verified");

        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _quantity,
            _price,
            msg.sender,
            _retailer,
            ProductStatus.Created
        );
        emit ProductCreated(productCount, msg.sender);
    }

    function shipProduct(uint _productId) 
        public 
        onlyVerifiedUser(AccountVerification.UserRole.Manufacturer) 
    {
        Product storage p = products[_productId];
        require(msg.sender == p.manufacturer, "Not manufacturer");
        require(p.status == ProductStatus.Created, "Invalid status");
        
        p.status = ProductStatus.Shipped;
        emit ProductShipped(_productId, msg.sender);
    }

    function receiveProduct(uint _productId) 
        public 
        onlyVerifiedUser(AccountVerification.UserRole.Retailer)
        onlyAssignedRetailer(_productId) 
    {
        Product storage p = products[_productId];
        require(p.status == ProductStatus.Shipped, "Not shipped");
        
        p.status = ProductStatus.Received;
        emit ProductReceived(_productId, msg.sender);
        
        _releasePayment(_productId, "product", p.manufacturer);
    }

    // Payment Handling
    function depositPayment(uint _id, string memory _type) public payable {
        uint requiredAmount;
        address payee;

        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("rawMaterial"))) {
            RawMaterial storage rm = rawMaterials[_id];
            requiredAmount = rm.price;
            payee = rm.manufacturer;
        } else {
            Product storage p = products[_id];
            requiredAmount = p.price;
            payee = p.retailer;
        }

        require(msg.value == requiredAmount, "Incorrect amount");
        require(msg.sender == payee, "Unauthorized payment");

        escrowBalance[_id] += msg.value;
        emit PaymentDeposited(_id, msg.sender, msg.value);
    }

    function _releasePayment(uint _id, string memory _type, address recipient) private {
        uint amount = escrowBalance[_id];
        require(amount > 0, "No funds in escrow");

        escrowBalance[_id] = 0;
        payable(recipient).transfer(amount);
        emit PaymentReleased(_id, recipient, amount);
    }

    // Getters
    function getRawMaterial(uint _id) public view returns (
        string memory, uint, uint, address, address, RawMaterialStatus
    ) {
        RawMaterial memory rm = rawMaterials[_id];
        return (rm.name, rm.quantity, rm.price, rm.supplier, rm.manufacturer, rm.status);
    }

    function getProduct(uint _id) public view returns (
        string memory, uint, uint, address, address, ProductStatus
    ) {
        Product memory p = products[_id];
        return (p.name, p.quantity, p.price, p.manufacturer, p.retailer, p.status);
    }
}