// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract AccountVerification {
    address public admin;

    struct User {
        address userAddress;
        string role; // Changed from enum to string
        bool isVerified;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed userAddress, string role);
    event UserVerified(address indexed userAddress, string role);
    event UserRevoked(address indexed userAddress, string role);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(address _userAddress, string memory _role) public onlyAdmin {
        require(users[_userAddress].userAddress == address(0), "User already registered");
        users[_userAddress] = User(_userAddress, _role, false);
        emit UserRegistered(_userAddress, _role);
    }

    function verifyUser(address _userAddress) public onlyAdmin {
        require(users[_userAddress].userAddress != address(0), "User not registered");
        require(!users[_userAddress].isVerified, "User already verified");
        users[_userAddress].isVerified = true;
        emit UserVerified(_userAddress, users[_userAddress].role);
    }

    function revokeUser(address _userAddress) public onlyAdmin {
        require(users[_userAddress].userAddress != address(0), "User not registered");
        require(users[_userAddress].isVerified, "User is not verified");
        users[_userAddress].isVerified = false;
        emit UserRevoked(_userAddress, users[_userAddress].role);
    }

    function isUserVerified(address _userAddress) public view returns (bool) {
        return users[_userAddress].isVerified;
    }

    function getUser(address _userAddress) public view returns (string memory, bool) {
        require(users[_userAddress].userAddress != address(0), "User not registered");
        User memory user = users[_userAddress];
        return (user.role, user.isVerified);
    }
}
