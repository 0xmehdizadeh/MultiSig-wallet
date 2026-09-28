//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiSigWallet contract
 * @author 0xmehdizadeh
 * @dev This contract allows multiple owners to manage a wallet and approve transactions collectively.
 * @dev Owners can submit, approve, execute, and cancel transactions. The contract also allows adding and removing owners and changing the approval threshold.
 */
contract MultiSigWallet {

    /**
     * @notice Struct representing a transaction in the MultiSigWallet.
     * @param to The address to which the transaction is directed.
     * @param value The amount of Ether to be sent in the transaction.
     * @param data The data payload for the transaction (used for contract calls).
     * @param approvalCount The number of approvals the transaction has received from owners.
     * @param executed A boolean indicating whether the transaction has been executed.
     * @param cancelled A boolean indicating whether the transaction has been cancelled.
     * @param proposedBy The address of the owner who proposed the transaction.
     * @param proposedAt The timestamp when the transaction was proposed.
     */
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint256 approvalCount;
        bool executed;
        bool cancelled;
        address proposedBy;
        uint256 proposedAt;
    }
    
    /// @notice Emitted when an owner submits a new transaction.
    event SubmitTransaction(address indexed proposer, uint indexed txIndex, address indexed to, uint256 value, bytes data);

    /// @notice Emitted when an owner approves a transaction.
    event ApproveTransaction(address indexed approver, uint indexed txIndex);

    /// @notice Emitted when a transaction is executed
    event ExecuteTransaction(address indexed executer, uint indexed txIndex);

    /// @notice Emitted when the approval threshold is changed
    event ChangeThreshold(uint oldThreshold, uint indexed newThreshold);

    /// @notice Emitted when a new owner is added to the wallet. 
    event OwnerAdded(address indexed newOwner);

    /// @notice Emitted when an owner is removed from the wallet.
    event OwnerRemoved(address indexed removedOwner);

    /// @notice Emitted when a transaction is cancelled by an owner
    event CancelTransaction(address indexed canceller, uint indexed txIndex);


    // STORAGE VARIABLES
    /// @notice Array storing all submitted transactions.
    Transaction[] public transactions;
    
    /// @notice Represents the number of transactions that have been submitted.
    uint public transactionCount;

    /// @notice Mapping tracking which owners have approved each transaction.
    mapping(uint => mapping(address => bool)) public approvals;

    /// @notice The minimum number of approvals required to execute a transaction
    uint public threshold;
    
    /// @notice Array containing all owner addresses of the wallet.
    address[] public owners;
    
    /// @notice Mapping to quickly check if an address is an owner.
    mapping(address => bool) public isOwner;
    
    /// @notice Initializes the wallet with the deployer as the first owner and threshold set to 1.
    constructor(){
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
        threshold = 1;
    }

    // MODIFIERS
    /// @notice Modifier to restrict function access to only owners of the wallet.
    /// @dev Checks if the caller's address is in the `isOwner` mapping.
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owners can call this function");
        _;
    }

    /// @notice Modifier to check if a transaction exists at the given index.
    /// @param _txIndex The index of the transaction to check.
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    /// @notice Modifier to ensure that a transaction has not been executed yet.
    /// @param _txIndex The index of the transaction to check.
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    /// @notice Modifier to ensure that a transaction has not been cancelled yet.
    /// @param _txIndex The index of the transaction to check.
    modifier notCancelled(uint256 _txIndex) {
        require(!transactions[_txIndex].cancelled, "Transaction already cancelled");
        _;
    }
    
    // FUNCTIONS
    /// @notice Function to allow owners to add another owner to the wallet.
    /// @param _newOwner The address of the new owner.
    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid owner address");
        require(!isOwner[_newOwner], "Address is already an owner");
        owners.push(_newOwner);
        isOwner[_newOwner] = true;
        emit OwnerAdded(_newOwner);
    }

    // submitTransaction()
    /**
     * @notice Submits a new transaction for approval by owners.
     * @dev Transaction starts with 0 approvals and must reach the threshold before execution.
     * @param _to Recipient address (cannot be zero address).
     * @param _value Amount in wei to transfer.
     * @param _data Encoded function call data (empty bytes for pure ETH transfers).
     */
    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            approvalCount: 0,
            executed: false,
            cancelled: false,
            proposedBy: msg.sender,
            proposedAt: block.timestamp
        }));
        transactionCount = transactions.length;
        emit SubmitTransaction(msg.sender, transactions.length - 1, _to, _value, _data);
    }
    // approveTransaction()
    /**
     * @notice Approves a submitted transaction by owners.
     * @param _txIndex The index of transaction to approve.
     * @dev It increases the approvalCount amount by 1. The transaction should not be approved by the msg.sender before. 
     */
    function approveTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notCancelled(_txIndex) {
        require(!approvals[_txIndex][msg.sender], "Transaction already approved by this owner");
        approvals[_txIndex][msg.sender] = true;
        transactions[_txIndex].approvalCount += 1;
        emit ApproveTransaction(msg.sender, _txIndex);
    }
    // executeTransaction()
    /**
     * @notice Executes a transaction
     * @param _txIndex The index of transaction to execute.
     * @dev The approvalCount must be greater than or equal to the threshold.
     */
    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notCancelled(_txIndex){
        require(transactions[_txIndex].approvalCount >= threshold, "Not enough approvals");
        Transaction storage transaction = transactions[_txIndex];
        
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    // cancelTransaction()
    /**
     * @notice Cancels a transaction by owners.
     * @param _txIndex The index of transaction to cancel.
     */
    function cancelTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notCancelled(_txIndex) {
        transactions[_txIndex].cancelled = true;
        emit CancelTransaction(msg.sender, _txIndex);
    }
    // removeOwner()
    /// @notice Function to allow owners to remove another owner from the wallet.
    /// @param _owner The address of the owner to remove.
    function removeOwner(address _owner) public onlyOwner {
        require(isOwner[_owner], "Address is not an owner");
        require(_owner != msg.sender, "Owner cannot remove themselves");
        require(threshold <= owners.length - 1, "Threshold must be less than or equal to the number of remaining owners");
        isOwner[_owner] = false;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        emit OwnerRemoved(_owner);
    }
    // changeThreshold()
    /// @notice Function to allow owners to change the amount of approval threshold.
    /// @param _newThreshold The new amount of the threshold
    /// @dev The new threshold must be greater that 0 and less than or equal to the number of owners.
    function changeThreshold(uint _newThreshold) public onlyOwner {
        require(_newThreshold > 0 && _newThreshold <= owners.length, "Invalid threshold");
        uint oldThreshold = threshold;
        threshold = _newThreshold;
        emit ChangeThreshold(oldThreshold, _newThreshold);
    }

    /// @notice Receive function that allows the wallet to accept Ether deposits.
    /// @dev This function is called when Ether is sent to the contract with no data.
     receive() external payable {}
}