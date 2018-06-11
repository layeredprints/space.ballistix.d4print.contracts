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
  // Constants
  bytes32 constant ROLE_USER = 'USER';
  bytes32 constant ROLE_CUSTOMER = 'CUSTOMER';
  bytes32 constant ROLE_PROVIDER = 'PROVIDER';
  bytes32 constant ROLE_ADMIN = 'ADMIN';

  // Struct
  struct User {
    address addr;
    bytes32 role;
  }

  // Events
  event UserPatch(address indexed _address);
  event UserDestroy(address indexed _address);

  // Mapping for user structs
  mapping(address => User) public users;

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
//  function hasRoleAdmin (address addr) view restrictToPermitted public returns (bool) {
  function otherHasRoleAdmin (address addr) view public returns (bool) {
    return administrators[addr];
  }

  // Check if the requesting user is a provider
  function hasRoleProvider () view public returns (bool) {
    return providers[msg.sender];
  }

  // Check if the given user is a provider
//  function hasRoleProvider (address addr) view restrictToPermitted public returns (bool) {
  function otherHasRoleProvider (address addr) view public returns (bool) {
    return providers[addr];
  }

  // Check if the requesting user is a customer
  function hasRoleCustomer () view public returns (bool) {
    return customers[msg.sender];
  }

  // Check if the given user is a customer
//  function hasRoleCustomer (address addr) view restrictToPermitted public returns (bool) {
  function otherHasRoleCustomer (address addr) view public returns (bool) {
    return customers[addr];
  }

  function exists (address _address) view public returns (bool) {
    return (administrators[_address] || providers[_address] || customers[_address]) && (users[_address].addr != address(0));
  }

  // ---
  // Add functions
  // ---

  // roles: USER, PROVIDER, CUSTOMER, ADMIN ?

  function patch (address _address, bytes32 _role) public {
    users[_address] = User({addr: _address, role: _role}) ;
    if (_role == ROLE_USER) {
      addCustomer(_address);
    } else  if (_role == ROLE_CUSTOMER) {
      addCustomer(_address);
    } else  if (_role == ROLE_PROVIDER) {
      addProvider(_address);
    } else  if (_role == ROLE_ADMIN) {
      addAdministrator(_address);
    }
    UserPatch(_address);
  }

  // Add an address to administrators
//  function addAdministrator (address addr) restrictToCreators public {
  function addAdministrator (address addr) public {
    if (addr != address(0)) {
      administrators[addr] = true;
      users[addr] = User({addr: addr, role: ROLE_ADMIN});
      UserPatch(addr);
    } else {
      revert();
    }
  }

  // Add an address to providers
//  function addProvider (address addr) restrictToCreators public {
  function addProvider (address addr) public {
    if (addr != address(0)) {
      providers[addr] = true;
      users[addr] = User({addr: addr, role: ROLE_PROVIDER});
      UserPatch(addr);
    } else {
      revert();
    }
  }

  // Add an address to customers
//  function addCustomer (address addr) restrictToCreators public {
  function addCustomer (address addr) public {
    if (addr != address(0)) {
      customers[addr] = true;
      users[addr] = User({addr: addr, role: ROLE_CUSTOMER});
      UserPatch(addr);
    } else {
      revert();
    }
  }


  // ---
  // Remove functions
  // ---

  // Remove an address from administrators
//  function removeAdministrator (address addr) restrictToCreators public {
  function removeAdministrator (address addr) public {
    administrators[addr] = false;
  }

  // Remove an address from providers
//  function removeProvider (address addr) restrictToCreators public {
  function removeProvider (address addr) public {
    providers[addr] = false;
  }

  // Remove an address from customers
//  function removeCustomer (address addr) restrictToCreators public {
  function removeCustomer (address addr) public {
    customers[addr] = false;
  }

  function destroy (address _address) public {
    require(exists(_address));
    delete users[_address];
    delete customers[_address];
    delete providers[_address];
    delete administrators[_address];
    UserDestroy(_address);
  }

  function get (address _address) public constant returns(address, bytes32) {
    require(exists(_address));
    return (users[_address].addr, users[_address].role);
  }
}

/*
users contract
+import "./Mortal.sol";
+
+contract Users is Mortal {
+  struct User {
+    address addr;
+    bytes32 role;
+  }
+
+  mapping(address => User) public users;
+
+  event UserPatch(address indexed _address);
+  event UserDestroy(address indexed _address);
+
+  function exists (address _address) public constant returns (bool _exists) {
+    return (users[_address].addr != address(0));
+  }
+
+  function patch (address _address, bytes32 _role) restricted public {
+    users[_address] = User({addr: _address, role: _role}) ;
+    UserPatch(_address);
+  }
+
+  function destroy (address _address) restricted public {
+    require(exists(_address));
+    delete users[_address];
+    UserDestroy(_address);
+  }
+
+  function get (address _address) public constant returns(address, bytes32) {
+    require(exists(_address));
+    return (users[_address].addr, users[_address].role);
+  }
+}
*/
