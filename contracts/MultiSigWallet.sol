//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint256 approvalCount;
        bool executed;
        address proposedBy;
        uint256 proposedAt;
    }
    

    event SubmitTransaction(address indexed proposer, uint indexed txIndex, address indexed to, uint256 value, bytes data);
    event ApproveTransaction(address indexed approver, uint indexed txIndex);
    event ExecuteTransaction(address indexed executer, uint indexed txIndex);

    // STORAGE VARIABLES
    // List all transactions
    Transaction[] public transactions;
    // Track approvals of a specific transaction by an owner
    mapping(uint => mapping(address => bool)) public approvals;

    // Store threshold
    uint public threshold;
    
    // List all owners
    address[] public owners;
    
    // Track if address is owner
    mapping(address => bool) public isOwner;
    
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
    function approveTransaction(uint _txIndex) public onlyOwner {
        require(_txIndex < transactions.length, "Transaction does not exist");
        require(!transactions[_txIndex].executed, "Transaction already executed");
        require(!approvals[_txIndex][msg.sender], "Transaction already approved by this owner");
        approvals[_txIndex][msg.sender] = true;
        transactions[_txIndex].approvalCount += 1;
    }
    // executeTransaction()
    function executeTransaction(uint _txIndex) public onlyOwner {
        require(_txIndex < transactions.length, "Transaction does not exist");
        require(!transactions[_txIndex].executed, "Transaction already executed");
        require(transactions[_txIndex].approvalCount >= threshold, "Not enough approvals");
        Transaction storage transaction = transactions[_txIndex];
        
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");
    }
    // cancelTransaction()
    // removeOwner()
    // changeThreshold()
}