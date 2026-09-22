//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    // STORAGE VARIABLES
    // List all owners
    address[] public owners;
    
    // Track if address is owner
    mapping(address => bool) public isOwner;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint256 approvalCount;
        bool executed;
        address proposedBy;
        uint256 proposedAt;
    }
    // List all transactions
    Transaction[] public transactions;
    // Track approvals of a specific transaction by an owner
    mapping(uint => mapping(address => bool)) public approvals;

    // Store threshold
    uint public threshold;
    
    constructor(){
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
        threshold = 1;
    }
    
    // FUNCTIONS
    // submitTransaction()
    // approveTransaction()
    // executeTransaction()
    // cancelTransaction()
    // add newowner()
    // removeOwner()
    // changeThreshold()
}