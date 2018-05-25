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
 **/

contract Factory is Owned {

  // Contract references
  Users private users;
  Funds private funds;
  Items private items;
  Auctions private auctions;


  constructor() public Owned(msg.sender) {
    // Create the users contract, reference us and the factory as owners
    users = new Users(msg.sender);

    // Create the funds contract, reference us and the factory as owners, reference the users contract for access management
    funds = new Funds(msg.sender, users);

    // Create the items contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    items = new Items(msg.sender, users, funds);

    // Create the auctions contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    auctions = new Auctions(msg.sender, users, funds);

    // Add Funds, Items and Auctions to the permitted callers of the Users contract
    users.addPermittedCaller(funds);
    users.addPermittedCaller(items);
    users.addPermittedCaller(auctions);

    // Add Items and Auctions to the permitted callers of the Funds contract
    funds.addPermittedCaller(items);
    funds.addPermittedCaller(auctions);
  }

  function testCall () restrictToOwner public {
    auctions.test(5);
  }

  // Update the users contract reference for the linked contracts
  function updateUsersReference (address newAddr) restrictToOwner public {
    // Update the local reference and pointer
    users = new Users(newAddr);

    // Update the individual contract's references
    funds.updateUsersContractReference(users);
    items.updateUsersContractReference(users);
    auctions.updateUsersContractReference(users);
  }

  // Update the funds contract reference for the linked contracts
  function updateFundsReference (address newAddr) restrictToOwner public {
    // Update the local reference and pointer
    funds = new Funds(newAddr, users);

    // Update the individual contract's references
    items.updateFundsContractReference(funds);
    auctions.updateFundsContractReference(funds);
  }

}
