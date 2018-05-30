pragma solidity ^0.4.18;

import "./Users.sol";

/**
 * Parent contract that wraps the Users contract to verify function calls via modifiers
 *
 * note: can be dangerous if used incorrectly, malicious users contract could be referenced
 * may need to change architecture or remove usage of this altogether
 *
 * A constructor like so:
 * constructor (address usersContractAddres) public Secured(usersContractAddres)
 *
 * means that the Secured contract instance will wrap whatever user contract address is passed,
 * the msg.sender that is passed implicitly through the Secured constructor
 * will be verified as a permitted caller through an extension of the Delegate contract in the Users contract
 * this will happen on each function call
 *
 * this also means that whatever contract that extends the Secured contract, has to be registered as
 * a permitted caller of the referenced Users contract to be able to use its [the Secured contract] modifiers
 *
 **/

contract Secured {

  modifier restrict {
    if (msg.sender == origin) _;
    else revert();
  }

  modifier isAdmin (address addr) {
    if (users.hasRoleAdmin(addr)) _;
    else revert();
  }

  modifier isProvider (address addr) {
    if (users.hasRoleProvider(addr)) _;
    else revert();
  }

  modifier isCustomer (address addr) {
    if (users.hasRoleCustomer(addr)) _;
    else revert();
  }

  modifier isCustomerOrProvider (address addr) {
    if (users.hasRoleCustomer(addr) || users.hasRoleProvider(addr)) _;
    else revert();
  }

  address public origin;

  // Reference to the users contract
  Users public users;

  // Initialize the reference to the used contract and assign the caller as the origin
  constructor (address addr) public {
    if (addr != address(0)) {
      origin = msg.sender;
      users = Users (addr);
    } else {
      revert();
    }
  }


  // ---
  // Contract functions
  // ---

  // Allow for updating the owning (factory) contract, since it may change
  function updateUsersContractReference (address addr) restrict public {
    if (addr != address(0)) {
      users = Users (addr);
    } else {
      revert();
    }
  }
}

