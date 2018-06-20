pragma solidity ^0.4.18;

import "./Delegate.sol";
import "./Secured.sol";

/**
 * Funds contract that manages the service funds for all users
 *
 * funds can be deposited, withdrawn and reserved
 *
 **/

contract Funds is Delegate, Secured {

  // Mapping for the balance of each account within the Funds wallet
  mapping (address => uint) balances;

  // Mapping for the funds in reservation
  mapping (address => uint) reservations;

  // Fee for payout calculation
  uint private fee = 1; // default is 1%

  constructor (address origin, address usersContractAddres) public Delegate(origin) Secured(usersContractAddres) {
    // do other stuff
  }


  // ---
  // Contract functions
  // ---



  // ---
  // Direct Service functions (called by users directly)
  // ---

  // Allow the owner to fill the contract buffer
//  function fillBuffer (uint amount) isAdmin(msg.sender) public payable {
  function fillBuffer (uint amount) public payable {
    // Check if the owner is filling how much they say they are
    if (msg.value == amount) {
      // Update the balance for the owner (this keeps track of the buffer initially, but also has to be updated when it is used)
      balances[msg.sender] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  event Deposit (address from, uint amount);

  // Allow users to deposit funds into their wallet
//  function deposit () isCustomerOrProvider(msg.sender) public payable {
  function deposit () public payable {
    // Update the balance
    balances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  // Allow users to check their funds
//  function getDeposit () view isCustomerOrProvider(msg.sender) public returns (uint) {
  function getDeposit ()view public returns (uint) {
    return balances[msg.sender];
  }

  // Allow users to check their reserve
//  function getReserve () view isCustomerOrProvider(msg.sender) public returns (uint) {
  function getReserve () view public returns (uint) {
    return reservations[msg.sender];
  }

  // Allow users to withdraw funds from their wallet
//  function withdraw (uint amount) isCustomerOrProvider(msg.sender) public {
  function withdraw (uint amount) public {
    // Check if the user has that amount or more
    if (balances[msg.sender] >= amount) {
      // Send the funds
      msg.sender.transfer(amount);
      // Subtract the amount from the balance
      balances[msg.sender] -= amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow users to transfer funds to other wallets
//  function transfer (uint amount, address destination) isCustomerOrProvider(msg.sender) public {
  function transfer (uint amount, address destination) public {
    // Check if the user has that amount or more
    if (balances[msg.sender] >= amount) {
      // Subtract the amount from the balance of the user
      balances[msg.sender] -= amount;
      // Add the amount to the balance of the destination
      balances[destination] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin to transfer funds between any wallets
//  function transfer (uint amount, address source, address destination) isAdmin(msg.sender) public {
//  function transfer (uint amount, address source, address destination) public {
//    // Check if the source has that amount or more
//    if (balances[source] >= amount) {
//      // Subtract the amount from the balance of the source
//      balances[source] -= amount;
//      // Add the amount to the balance of the destination
//      balances[destination] += amount;
//    } else {
//      // If failed, revert
//      revert();
//    }
//  }

  // Allow admin to update the fee
//  function updateFee (uint newFee) isAdmin(msg.sender) public {
  function updateFee (uint newFee) public {
    if (newFee >= 0 && newFee <= 100) {
      fee = newFee;
    }
  }

  // ---
  // Delegate Service functions (called by trused contracts and admins)
  // ---

  // Reserve funds
//  function reserve (uint amount, address source) restrictToPermitted public {
  function reserve (uint amount, address source) public {
    // Check if the source has that amount or more
    if (balances[source] >= amount) {
      // Subtract the amount from the balance of the source
      balances[source] -= amount;
      // Add that amount to the reservations of the source
      reservations[source] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Unreserve funds
//  function unReserve (uint amount, address source) restrictToPermitted public {
  function unReserve (uint amount, address source) public {
    // Check if the source has that amount or more in reservations
    if (reservations[source] >= amount) {
      // Subtract the amount from the reservations of the source
      reservations[source] -= amount;
      // Add that amount to the balance of the source
      balances[source] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

//  // Unreserve all funds
////  function unReserve (address source) restrictToPermitted public {
//  function unReserve (address source) public {
//    // Get the total funds in reservations for the source
//    uint amount = reservations[source];
//    // Subtract the amount from the reservations of the source
//    reservations[source] -= amount;
//    // Add that amount to the balance of the source
//    balances[source] += amount;
//  }

  // Calculate the fee
//  function calculateFee (uint amount) view restrictToPermitted public returns (uint) {
  function calculateFee (uint amount) view public returns (uint) {
    if (amount > 0) {
      return (amount / 100) * fee;
    } else {
      revert();
    }
  }

  // Allow admin to transfer reserves
  // NOTE: this transfers from source RESERVE to destination BALANCE, not destination RESERVE
//  function transferReserve (uint amount, address source, address destination) restrictToPermitted public {
//  function transferReserve (uint amount, address source, address destination) public {
//    // Check if the source has that amount or more in reservations
//    if (reservations[source] >= amount) {
//      // Subtract the amount from the reservations of the source
//      reservations[source] -= amount;
//      // Add that amount to the balance of the destination
//      balances[destination] += amount;
//    } else {
//      // If failed, revert
//      revert();
//    }
//  }

  // Allow admin to transfer reserves
  // NOTE: this transfers from source RESERVE to owner BALANCE, not owner RESERVE
//  function transferReserve (uint amount, address source) restrictToPermitted public {
  function transferReserve (uint amount, address source) public {
    // Check if the source has that amount or more in reservations
    if (reservations[source] >= amount) {
      // Subtract the amount from the reservations of the source
      reservations[source] -= amount;
      // Add that amount to the balance of the destination
      balances[owner] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin to pay out from admin account
//  function transferOwnerFunds (uint amount, address destination) restrictToPermitted public {
  function transferOwnerFunds (uint amount, address destination) public {
    // Check if the source has that amount or more in balance
    if (balances[owner] >= amount) {
      // Subtract the amount from the balance of the owner
      balances[owner] -= amount;
      // Add that amount to the balance of the destination
      balances[destination] += amount;
    } else {
      revert();
    }
  }

  // Check reserve
//  function getReserve (address source) view restrictToPermitted public returns (uint) {
  function getReserve (address source) view public returns (uint) {
    return reservations[source];
  }
}
