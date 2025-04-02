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
    event ProductShipped(uint productId, address sender);
    event ProductReceived(uint productId, address receiver);
    event PaymentProcessed(uint id, address payer, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlySupplier() {
        require(isSupplier(msg.sender), "Only supplier can perform this action");
        _;
    }

    // Check if an address has ever been registered as a supplier
    function isSupplier(address _addr) internal view returns (bool) {
        for (uint i = 1; i <= rawMaterialCount; i++) {
            if (rawMaterials[i].supplier == _addr) {
                return true;
            }
        }
        return false;
    }

    // For raw material-related functions, ensure the caller is the manufacturer set for that raw material
    modifier onlyManufacturer(uint _rawMaterialId) {
        require(msg.sender == rawMaterials[_rawMaterialId].manufacturer, "Only manufacturer can receive this raw material");
        _;
    }

    // For product-related functions, ensure the caller is the retailer set for that product
    modifier onlyRetailer(uint _productId) {
        require(msg.sender == products[_productId].retailer, "Only retailer can receive this product");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Raw Material Management

    // Only an address that has been a supplier can create raw materials.
    function createRawMaterial(
        string memory _name,
        uint _quantity,
        uint _price
    ) public onlySupplier {
        rawMaterialCount++;
        rawMaterials[rawMaterialCount] = RawMaterial(
            rawMaterialCount,
            _name,
            _quantity,
            _price,
            msg.sender,
            address(0),
            RawMaterialStatus.Created
        );
    }

    // Supplier supplies a raw material and assigns a manufacturer.
    function supplyRawMaterial(uint _rawMaterialId, address _manufacturer) public {
        require(msg.sender == rawMaterials[_rawMaterialId].supplier, "Only supplier can supply raw materials");
        require(rawMaterials[_rawMaterialId].status == RawMaterialStatus.Created, "Invalid status");
        rawMaterials[_rawMaterialId].status = RawMaterialStatus.Supplied;
        rawMaterials[_rawMaterialId].manufacturer = _manufacturer;
        emit RawMaterialSupplied(_rawMaterialId, msg.sender);
    }

    // Either the assigned manufacturer or the supplier can mark the raw material as received.
    function receiveRawMaterial(uint _rawMaterialId) public {
        require(
            msg.sender == rawMaterials[_rawMaterialId].manufacturer || msg.sender == rawMaterials[_rawMaterialId].supplier,
            "Only manufacturer or supplier can receive raw material"
        );
        require(rawMaterials[_rawMaterialId].status == RawMaterialStatus.Supplied, "Raw material not supplied yet");
        rawMaterials[_rawMaterialId].status = RawMaterialStatus.Received;
        emit RawMaterialReceived(_rawMaterialId, msg.sender);
    }

    // Product Management

    // Only a manufacturer (an address that is not a supplier) can add a product.
    function addProductManufacture(
        string memory _name,
        uint _quantity,
        uint _price,
        address _retailer
    ) public {
        require(!isSupplier(msg.sender), "Only manufacturer wallet can add product manufacture");
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
    }

    // Shipping a product can be done by either the manufacturer or any address that has acted as a supplier.
    function shipProduct(uint _productId) public {
        require(
            msg.sender == products[_productId].manufacturer || isSupplier(msg.sender),
            "Only manufacturer or supplier can ship the product"
        );
        require(products[_productId].status == ProductStatus.Created, "Invalid status");
        products[_productId].status = ProductStatus.Shipped;
        emit ProductShipped(_productId, msg.sender);
    }

    // Receiving a product can be done by the retailer or the manufacturer.
    function receiveProduct(uint _productId) public {
        require(
            msg.sender == products[_productId].retailer || msg.sender == products[_productId].manufacturer,
            "Only retailer or manufacturer can receive this product"
        );
        require(products[_productId].status == ProductStatus.Shipped, "Product not shipped yet");
        products[_productId].status = ProductStatus.Received;
        emit ProductReceived(_productId, msg.sender);
    }

    // Process payments for raw materials (manufacturer pays supplier) or for products (retailer pays manufacturer).
    function processPayment(uint _id, string memory _type) public payable {
        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("rawMaterial"))) {
            RawMaterial memory rawMaterial = rawMaterials[_id];
            require(msg.sender == rawMaterial.manufacturer, "Only manufacturer can pay for raw materials");
            require(rawMaterial.status == RawMaterialStatus.Received, "Raw material not received yet");
            uint amount = msg.value;
            payable(rawMaterial.supplier).transfer(amount);
            emit PaymentProcessed(_id, msg.sender, amount);
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("product"))) {
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

    // Only the manufacturer for the raw material can view its details.
    function getRawMaterial(uint _rawMaterialId) public view onlyManufacturer(_rawMaterialId) returns (
        string memory, uint, uint, address, address, RawMaterialStatus
    ) {
        RawMaterial memory rm = rawMaterials[_rawMaterialId];
        return (rm.name, rm.quantity, rm.price, rm.supplier, rm.manufacturer, rm.status);
    }

    // Only the retailer can view the product details.
    function getProduct(uint _productId) public view onlyRetailer(_productId) returns (
        string memory, uint, uint, address, address, ProductStatus
    ) {
        Product memory p = products[_productId];
        return (p.name, p.quantity, p.price, p.manufacturer, p.retailer, p.status);
    }
}
