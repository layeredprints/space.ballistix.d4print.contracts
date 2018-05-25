pragma solidity ^0.4.18;

import "./Owned.sol";
import "./Users.sol";
import "./Funds.sol";
import "./Items.sol";
import "./Auctions.sol";

// this is more of a debugging contract, but we could potentially use it as a managing contract
contract Factory is Owned {

  // Contract addresses
  address public contractUsers;
  address public contractFunds;
  address public contractItems;
  address public contractAuctions;

  // Contract references
  Users private users;
  Funds private funds;
  Items private items;
  Auctions private auctions;

  // note: contract address and reference are actually the same thing, but they differ in use, it's good to have a copy of both

  constructor() public Owned(msg.sender) {
    // Create the users contract, reference us and the factory as owners
    users = new Users(msg.sender);
    contractUsers = users;

    // Create the funds contract, reference us and the factory as owners, reference the users contract for access management
    funds = new Funds(msg.sender, contractUsers);
    contractFunds = funds;

    // Create the items contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    items = new Items(msg.sender, contractUsers, contractFunds);
    contractItems = items;

    // Create the auctions contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    auctions = new Auctions(msg.sender, contractUsers, contractFunds);
    contractAuctions = auctions;

    // Add Funds, Items and Auctions to the permitted callers of the Users contract
    users.addPermittedCaller(contractFunds);
    users.addPermittedCaller(contractItems);
    users.addPermittedCaller(contractAuctions);

    // Add Items and Auctions to the permitted callers of the Funds contract
    funds.addPermittedCaller(contractItems);
    funds.addPermittedCaller(contractAuctions);
  }

  function testCall () restrictToOwner public {
    auctions.test(5);
  }

  // Update the users contract reference for the linked contracts
  function updateUsersReference (address newAddr) restrictToOwner public {
    // Update the local reference and pointer
    users = new Users(newAddr);
    contractUsers = users;

    // Update the individual contract's references
    funds.updateUsersContractReference(contractUsers);
    items.updateUsersContractReference(contractUsers);
    auctions.updateUsersContractReference(contractUsers);
  }

  // Update the funds contract reference for the linked contracts
  function updateFundsReference (address newAddr) restrictToOwner public {
    // Update the local reference and pointer
    funds = new Funds(newAddr, contractUsers);
    contractFunds = funds;

    // Update the individual contract's references
    items.updateFundsContractReference(contractFunds);
    auctions.updateFundsContractReference(contractFunds);
  }

}
