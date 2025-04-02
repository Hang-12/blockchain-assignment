// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract AccountVerification {
    address public admin;

    enum UserRole { Supplier, Manufacturer, Retailer }

    struct User {
        address userAddress;
        UserRole role;
        bool isVerified;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed userAddress, UserRole role);
    event UserVerified(address indexed userAddress, UserRole role);
    event UserRevoked(address indexed userAddress, UserRole role);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender; // Set the deployer as the admin
    }

    // Register a new user (Supplier, Manufacturer, or Retailer)
    function registerUser(address _userAddress, UserRole _role) public onlyAdmin {
        require(users[_userAddress].userAddress == address(0), "User already registered");
        users[_userAddress] = User(_userAddress, _role, false);
        emit UserRegistered(_userAddress, _role);
    }

    // Verify a user
    function verifyUser(address _userAddress) public onlyAdmin {
        require(users[_userAddress].userAddress != address(0), "User not registered");
        require(!users[_userAddress].isVerified, "User already verified");
        users[_userAddress].isVerified = true;
        emit UserVerified(_userAddress, users[_userAddress].role);
    }

    // Revoke a user's verification
    function revokeUser(address _userAddress) public onlyAdmin {
        require(users[_userAddress].userAddress != address(0), "User not registered");
        require(users[_userAddress].isVerified, "User is not verified");
        users[_userAddress].isVerified = false;
        emit UserRevoked(_userAddress, users[_userAddress].role);
    }

    // Check if a user is verified
    function isUserVerified(address _userAddress) public view returns (bool) {
        return users[_userAddress].isVerified;
    }

    // Get user details
    function getUser(address _userAddress) public view returns (UserRole, bool) {
        require(users[_userAddress].userAddress != address(0), "User not registered");
        User memory user = users[_userAddress];
        return (user.role, user.isVerified);
    }
}