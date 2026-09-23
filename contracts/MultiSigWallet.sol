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

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owners can call this function");
        _;
    }
    
    // FUNCTIONS
    // add Owner
    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid owner address");
        require(!isOwner[_newOwner], "Address is already an owner");
        owners.push(_newOwner);
        isOwner[_newOwner] = true;
    }

    // submitTransaction()
    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            approvalCount: 0,
            executed: false,
            proposedBy: msg.sender,
            proposedAt: block.timestamp
        }));
    }
    // approveTransaction()
   
    // executeTransaction()
    // cancelTransaction()
    
    // removeOwner()
    // changeThreshold()
}