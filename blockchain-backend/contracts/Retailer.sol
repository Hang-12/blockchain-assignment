// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Retailer {
  address public owner;

  enum ProductStatus { Created, Shipped, Received }

  struct Product {
    uint id;
    string name;
    address supplier;
    address manufacturer;
    address retailer;
    ProductStatus status;
  }

  mapping(uint => Product) public products;
  uint public productCount;

  event ProductShipped(uint productId, address manufacturer);
  event ProductReceived(uint productId, address retailer);
  event PaymentProcessed(uint productId, address retailer, uint amount);

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can perform this action");
    _;
  }

  modifier onlyRetailer(uint _productId) {
    require(msg.sender == products[_productId].retailer, "Not authorized");
    _;
  }

  function addProduct(
    string memory _name,
    address _manufacturer,
    address _retailer
  ) public {
    productCount++;
    products[productCount] = Product(
      productCount,
      _name,
      msg.sender,
      _manufacturer,
      _retailer,
      ProductStatus.Created
    );
  }

  function receiveProduct(uint _productId) public onlyRetailer(_productId) {
    require(products[_productId].status == ProductStatus.Shipped, "Product not shipped yet");

    products[_productId].status = ProductStatus.Received;
    emit ProductReceived(_productId, msg.sender);
  }

  function processPayment(uint _productId) public payable onlyRetailer(_productId) {
    require(products[_productId].status == ProductStatus.Received, "Product not received yet");

    uint amount = msg.value;
    payable(products[_productId].manufacturer).transfer(amount);
    emit PaymentProcessed(_productId, msg.sender, amount);
  }

  function getProduct(uint _productId) public view returns (
    string memory, address, address, address, ProductStatus
  ) {
    Product memory p = products[_productId];
    return (p.name, p.supplier, p.manufacturer, p.retailer, p.status);
  }
}