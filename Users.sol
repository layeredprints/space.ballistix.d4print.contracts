pragma solidity ^0.4.18;

import "./Delegate.sol";

/**
 * Users contract that manages the service roles and access verification for all users
 *
 * admins, providers and customers can be added, removed and verified
 *
 * this contract is wrapped by the Secure contract to offer role checking modifiers to the extending contracts (Funds, Items and Auctions)
 *
 **/

contract Users is Delegate {

  // Mapping for address admin role
  mapping (address => bool) administrators;

  // Mapping for address provider role
  mapping (address => bool) providers;

  // Mapping for address customer role
  mapping (address => bool) customers; // customers are generic users, clients


  constructor (address origin) public Delegate(origin) {
    // Add all roles (or at least admin) to the owner and ownerContract
    addAdministrator(origin);
    addAdministrator(msg.sender);

    addProvider(origin);
    addProvider(msg.sender);
    addCustomer(origin);
    addCustomer(msg.sender);
  }


  // ---
  // Check functions
  // ---

  // Check if the requesting user is an admin
  function hasRoleAdmin () view public returns (bool) {
    return administrators[msg.sender];
  }

  // Check if the given user is an admin
  function hasRoleAdmin (address addr) view restrictToPermitted public returns (bool) {
    return administrators[addr];
  }

  // Check if the requesting user is a provider
  function hasRoleProvider () view public returns (bool) {
    return providers[msg.sender];
  }

  // Check if the given user is a provider
  function hasRoleProvider (address addr) view restrictToPermitted public returns (bool) {
    return providers[addr];
  }

  // Check if the requesting user is a customer
  function hasRoleCustomer () view public returns (bool) {
    return customers[msg.sender];
  }

  // Check if the given user is a customer
  function hasRoleCustomer (address addr) view restrictToPermitted public returns (bool) {
    return customers[addr];
  }


  // ---
  // Add functions
  // ---

  // Add an address to administrators
  function addAdministrator (address addr) restrictToCreators public {
    administrators[addr] = true;
  }

  // Add an address to providers
  function addProvider (address addr) restrictToCreators public {
    providers[addr] = true;
  }

  // Add an address to customers
  function addCustomer (address addr) restrictToCreators public {
    customers[addr] = true;
  }


  // ---
  // Remove functions
  // ---

  // Remove an address from administrators
  function removeAdministrator (address addr) restrictToCreators public {
    administrators[addr] = false;
  }

  // Remove an address from providers
  function removeProvider (address addr) restrictToCreators public {
    providers[addr] = false;
  }

  // Remove an address from customers
  function removeCustomer (address addr) restrictToCreators public {
    customers[addr] = false;
  }
}
