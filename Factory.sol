pragma solidity ^0.4.18;

import "./Owned.sol";
import "./Users.sol";
import "./Funds.sol";
import "./Items.sol";
import "./Auctions.sol";

/**
 * Factory contract that manages the chain of contracts and their interdependence
 *
 * Users, Funds, Items and Auctions contracts can be interacted with
 * References to those contracts can be updated, both within the contract and in the contracts that depend on the updated information
 *
 * this contract is more of an easy debugging contract, but can be extended to a proper proxy chain managing contract
 *
 * note: be sure to provide enough gas when deploying this contract, it invokes a lot of other code and runs out pretty quick
 * the overall cost once deployed is fairly reasonable
 *
 **/

contract Factory is Owned {

  // Contract references
  Users private users;
  Funds private funds;
  Items private items;
  Auctions private auctions;

  // todo: don't deploy contracts in constructor, have seperate deployers for the contracts and do them individually

  constructor() public Owned(msg.sender) {
    // // Create the users contract, reference us and the factory as owners
    // users = new Users(msg.sender);

    // // Create the funds contract, reference us and the factory as owners, reference the users contract for access management
    // funds = new Funds(msg.sender, users);

    // // Create the auctions contract, reference us and the factory as owners
    // // Reference the users contract for access management
    // // Reference the funds contract for fund management
    // auctions = new Auctions(msg.sender, users, funds);

    // // Create the items contract, reference us and the factory as owners
    // // Reference the users contract for access management
    // // Reference the funds contract for fund management
    // items = new Items(msg.sender, users, funds, auctions);

    // // Add Funds, Items and Auctions to the permitted callers of the Users contract
    // users.addPermittedCaller(funds);
    // users.addPermittedCaller(items);
    // users.addPermittedCaller(auctions);

    // // Add Items and Auctions to the permitted callers of the Funds contract
    // funds.addPermittedCaller(items);
    // funds.addPermittedCaller(auctions);

    // // Add Items to the permitted callers of the Auctions contract
    // auctions.addPermittedCaller(items);
  }


  // ---
  // Contract functions
  // ---

//  function initUsersContract () restrictToOwner public {
  function initUsersContract () public {
    if (users == address(0)) {
      // Create the users contract, reference us and the factory as owners
      users = new Users(msg.sender);
    }
  }

//  function initFundsContract () restrictToOwner public {
  function initFundsContract () public {
    if (users != address(0) && funds == address(0)) {
      // Create the funds contract, reference us and the factory as owners, reference the users contract for access management
      funds = new Funds(msg.sender, users);
    }
  }

//  function initAuctionsContract () restrictToOwner public {
  function initAuctionsContract () public {
    if (users != address(0) && funds != address(0) && auctions == address(0)) {
      // Create the auctions contract, reference us and the factory as owners
      // Reference the users contract for access management
      // Reference the funds contract for fund management
      auctions = new Auctions(msg.sender, users, funds);
    }
  }

//  function initItemsContract () restrictToOwner public {
  function initItemsContract () public {
    if (users != address(0) && funds != address(0) && auctions != address(0) && items == address(0)) {
      // Create the items contract, reference us and the factory as owners
      // Reference the users contract for access management
      // Reference the funds contract for fund management
      items = new Items(msg.sender, users, funds, auctions);
    }
  }

//  function initPermittedCallers () restrictToOwner public {
  function initPermittedCallers () public {
    if (users != address(0) && funds != address(0) && auctions != address(0) && items != address(0)) {
      // Add Funds, Items and Auctions to the permitted callers of the Users contract
      users.addPermittedCaller(funds);
      users.addPermittedCaller(items);
      users.addPermittedCaller(auctions);

      // Add Items and Auctions to the permitted callers of the Funds contract
      funds.addPermittedCaller(items);
      funds.addPermittedCaller(auctions);

      // Add Items to the permitted callers of the Auctions contract
      auctions.addPermittedCaller(items);
    }
  }

  // Update the users contract reference for the linked contracts
//  function updateUsersReference (address newAddr) restrictToOwner public {
  function updateUsersReference (address newAddr) public {
    if (newAddr != address(0)) {
      // Update the local reference and pointer
      users = new Users(newAddr);

      // Update the individual contract's references
      funds.updateUsersContractReference(users);
      items.updateUsersContractReference(users);
      auctions.updateUsersContractReference(users);
    } else {
      revert();
    }
  }

  // Update the funds contract reference for the linked contracts
//  function updateFundsReference (address newAddr) restrictToOwner public {
  function updateFundsReference (address newAddr) public {
    if (newAddr != address(0)) {
      // Update the local reference and pointer
      funds = new Funds(newAddr, users);

      // Update the individual contract's references
      items.updateFundsContractReference(funds);
      auctions.updateFundsContractReference(funds);
    } else {
      revert();
    }
  }

//  function getUsersReference() view restrictToOwner public returns (Users) {
  function getUsersReference() view public returns (Users) {
    return users;
  }

//  function getFundsReference() view restrictToOwner public returns (Funds) {
  function getFundsReference() view public returns (Funds) {
    return funds;
  }

//  function getItemsReference() view restrictToOwner public returns (Items) {
  function getItemsReference() view public returns (Items) {
    return items;
  }

//  function getAuctionsReference() view restrictToOwner public returns (Auctions) {
  function getAuctionsReference() view public returns (Auctions) {
    return auctions;
  }

  // ---
  // Service functions
  // ---


}
