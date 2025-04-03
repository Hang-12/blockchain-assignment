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
    mapping(uint => uint) public escrowBalance; // Secure payments
    
    mapping(uint => uint) public escrowBalanceForRawMaterial;
    mapping(uint => uint) public escrowBalanceForProduct;

    function getEscrowBalance(uint _id, bool isProduct) public view returns (uint) {
        if (isProduct) {
            return escrowBalanceForProduct[_id];
        } else {
            return escrowBalanceForRawMaterial[_id];
        }
    }

    uint public rawMaterialCount;
    uint public productCount;

    event RawMaterialSupplied(uint rawMaterialId, address supplier);
    event RawMaterialReceived(uint rawMaterialId, address manufacturer);
    event ProductShipped(uint productId, address manufacturer);
    event ProductReceived(uint productId, address retailer);
    // event PaymentProcessed(uint productId, address retailer, uint amount);
    event PaymentDeposited(uint id, address payer, uint amount);
    event PaymentReleased(uint id, address recipient, uint amount);

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Only owner can perform this action");
    //     _;
    // }

    modifier onlyVerifiedUser(AccountVerification.UserRole role) {
        (AccountVerification.UserRole userRole, bool isVerified) = accountVerifier.getUser(msg.sender);
        require(isVerified, "User is not verified");
        require(userRole == role, "Unauthorized user role");
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
        // address _supplier,
        address _manufacturer
    ) public onlyVerifiedUser(AccountVerification.UserRole.Supplier) {
        (AccountVerification.UserRole role, bool isVerified) = accountVerifier.getUser(_manufacturer);
        require(isVerified, "Manufacturer is not verified");
        require(role == AccountVerification.UserRole.Manufacturer, "Invalid manufacturer address");

        // require(msg.value == _price, "Incorrect deposit amount");

        rawMaterialCount++;
        rawMaterials[rawMaterialCount] = RawMaterial(
            rawMaterialCount,
            _name,
            _quantity,
            _price,
            // _supplier,
            msg.sender, // Supplier is the sender of the transaction
            _manufacturer,
            RawMaterialStatus.Created
        );

        // escrowBalances[rawMaterialCount] = msg.value; // Store the deposit in escrow
        emit PaymentDeposited(rawMaterialCount, msg.sender, _price);
    }

    // function supplyRawMaterial(uint _rawMaterialId) public {
    //     // require(msg.sender == rawMaterials[_rawMaterialId].supplier, "Not authorized");
    //     require(rawMaterials[_rawMaterialId].status == RawMaterialStatus.Created, "Invalid status");

    //     rawMaterials[_rawMaterialId].status = RawMaterialStatus.Supplied;
    //     emit RawMaterialSupplied(_rawMaterialId, msg.sender);
    // }

    function supplyRawMaterial(uint _rawMaterialId) public {
        RawMaterial storage rm = rawMaterials[_rawMaterialId];
        require(msg.sender == rm.supplier, "Not authorized");
        require(rm.status == RawMaterialStatus.Created, "Invalid status");
        require(escrowBalanceForRawMaterial[_rawMaterialId] >= rm.price, "Payment not deposited");

        rm.status = RawMaterialStatus.Supplied;
        emit RawMaterialSupplied(_rawMaterialId, msg.sender);
    }

    // function receiveRawMaterial(uint _rawMaterialId) public onlyManufacturer(_rawMaterialId) {
    //     require(rawMaterials[_rawMaterialId].status == RawMaterialStatus.Supplied, "Raw material not supplied yet");

    //     rawMaterials[_rawMaterialId].status = RawMaterialStatus.Received;
    //     emit RawMaterialReceived(_rawMaterialId, msg.sender);
    // }

    // function receiveRawMaterial(uint _rawMaterialId) public onlyVerifiedUser(AccountVerification.UserRole.Manufacturer) {
    //     require(rawMaterials[_rawMaterialId].status == RawMaterialStatus.Supplied, "Raw material not supplied yet");

    //     rawMaterials[_rawMaterialId].status = RawMaterialStatus.Received;
    //     emit RawMaterialReceived(_rawMaterialId, msg.sender);
    // }

    function receiveRawMaterial(uint _rawMaterialId) public onlyVerifiedUser(AccountVerification.UserRole.Manufacturer) {
        RawMaterial storage rm = rawMaterials[_rawMaterialId];

        require(msg.sender == rm.manufacturer, "Only assigned manufacturer can receive");
        require(rm.status == RawMaterialStatus.Supplied, "Raw material not supplied yet");

        rm.status = RawMaterialStatus.Received;
        emit RawMaterialReceived(_rawMaterialId, msg.sender);

        uint amount = escrowBalanceForRawMaterial[_rawMaterialId];
        require(amount > 0, "No funds in escrow");

        emit PaymentReleased(_rawMaterialId, rm.supplier, amount);
    }

    // Product Management
    function addProduct(
        string memory _name,
        uint _quantity,
        uint _price,
        // address _manufacturer
        address _retailer
    ) public onlyVerifiedUser(AccountVerification.UserRole.Manufacturer) {
        (AccountVerification.UserRole role, bool isVerified) = accountVerifier.getUser(_retailer);
        require(isVerified, "Retailer is not verified");
        require(role == AccountVerification.UserRole.Retailer, "Invalid retailer address");

        // require(msg.value == _price, "Incorrect deposit amount");

        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _quantity,
            _price,
            // _manufacturer,
            msg.sender, // Manufacturer is the sender of the transaction
            _retailer,
            ProductStatus.Created
        );

        // escrowBalances[productCount] = msg.value; // Store the deposit in escrow
        emit PaymentDeposited(productCount, msg.sender, _price);
    }

    // function shipProduct(uint _productId) public onlyVerifiedUser((AccountVerification.UserRole.Manufacturer)) {
    //     // require(msg.sender == products[_productId].manufacturer, "Not authorized");
    //     require(products[_productId].status == ProductStatus.Created, "Invalid status");

    //     products[_productId].status = ProductStatus.Shipped;
    //     emit ProductShipped(_productId, msg.sender);
    // }

    function shipProduct(uint _productId) public onlyVerifiedUser(AccountVerification.UserRole.Manufacturer) {
        Product storage p = products[_productId];
        require(msg.sender == p.manufacturer, "Not authorized");
        require(p.status == ProductStatus.Created, "Invalid status");
        require(escrowBalanceForProduct[_productId] >= p.price, "Payment not deposited");

        p.status = ProductStatus.Shipped;
        emit ProductShipped(_productId, msg.sender);
    }

    // function receiveProduct(uint _productId) public onlyRetailer(_productId) {
    //     require(products[_productId].status == ProductStatus.Shipped, "Product not shipped yet");

    //     products[_productId].status = ProductStatus.Received;
    //     emit ProductReceived(_productId, msg.sender);
    // }

    // function receiveProduct(uint _productId) public onlyVerifiedUser(AccountVerification.UserRole.Retailer) {
    //     require(products[_productId].status == ProductStatus.Shipped, "Product not shipped yet");

    //     products[_productId].status = ProductStatus.Received;
    //     emit ProductReceived(_productId, msg.sender);
    // }

    function receiveProduct(uint _productId) public onlyVerifiedUser(AccountVerification.UserRole.Retailer) {
        Product storage p = products[_productId];

        require(msg.sender == p.retailer, "Only assigned retailer can receive");
        require(p.status == ProductStatus.Shipped, "Product not shipped yet");

        p.status = ProductStatus.Received;
        emit ProductReceived(_productId, msg.sender);

        uint amount = escrowBalanceForProduct[_productId];
        require(amount > 0, "No funds in escrow");

        emit PaymentReleased(_productId, p.manufacturer, amount);
    }

    // function processPayment(
    // uint _id, // ID of the raw material or product
    // string memory _type // "rawMaterial" or "product"
    // ) public payable {
    //     if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("rawMaterial"))) {
    //         // Payment for raw materials (manufacturer pays supplier)
    //         RawMaterial memory rawMaterial = rawMaterials[_id];
    //         require(msg.sender == rawMaterial.manufacturer, "Only manufacturer can pay for raw materials");
    //         require(rawMaterial.status == RawMaterialStatus.Received, "Raw material not received yet");

    //         uint amount = msg.value;
    //         payable(rawMaterial.supplier).transfer(amount);
    //         emit PaymentProcessed(_id, msg.sender, amount);
    //     } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("product"))) {
    //         // Payment for products (retailer pays manufacturer)
    //         Product memory product = products[_id];
    //         require(msg.sender == product.retailer, "Only retailer can pay for products");
    //         require(product.status == ProductStatus.Received, "Product not received yet");

    //         uint amount = msg.value;
    //         payable(product.manufacturer).transfer(amount);
    //         emit PaymentProcessed(_id, msg.sender, amount);
    //     } else {
    //         revert("Invalid payment type");
    //     }
    // }

    function depositPayment(uint _id, string memory _type) public payable {
        require(msg.value > 0, "Must deposit a positive amount");

        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("rawMaterial"))) {
            require(rawMaterials[_id].price > 0, "Raw material does not exist");
            require(
                escrowBalanceForRawMaterial[_id] + msg.value == rawMaterials[_id].price,
                "Total deposit must match required amount"
            );
            escrowBalanceForRawMaterial[_id] += msg.value;
        } 
        else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("product"))) {
            require(products[_id].price > 0, "Product does not exist");
            require(
                escrowBalanceForProduct[_id] + msg.value == products[_id].price,
                "Total deposit must match required amount"
            );
            escrowBalanceForProduct[_id] += msg.value;
        } 
        else {
            revert("Invalid type");
        }

        emit PaymentDeposited(_id, msg.sender, msg.value);
    }

    function releasePayment(uint _id, string memory _type) public {
        uint256 amount;
        address recipient;
        address payer;

        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("rawMaterial"))) {
            require(rawMaterials[_id].price > 0, "Raw material does not exist");
            amount = escrowBalanceForRawMaterial[_id];
            require(amount > 0, "No funds in escrow");
            
            recipient = rawMaterials[_id].supplier;
            payer = rawMaterials[_id].manufacturer;

            escrowBalanceForRawMaterial[_id] = 0; 
        } 
        else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("product"))) {
            require(products[_id].price > 0, "Product does not exist");
            amount = escrowBalanceForProduct[_id];
            require(amount > 0, "No funds in escrow");

            recipient = products[_id].manufacturer;
            payer = products[_id].retailer;

            escrowBalanceForProduct[_id] = 0; 
        } 
        else {
            revert("Invalid payment type");
        }

        require(msg.sender == payer, "Only payer can release payment");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit PaymentReleased(_id, recipient, amount);
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