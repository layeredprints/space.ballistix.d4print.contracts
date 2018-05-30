pragma solidity ^0.4.18;

import "./FactoryOwned.sol";

/**
 * Intended to be extended by other contracts that will in turn be called by several other contracts
 *
 * Contracts that extend Delegate can manage a list of permitted callers and
 * verify function callers against that list (this list of permitted callers are other contracts)
 *
 * Contracts that extend Delegate also extend Owned and are assumed to be created using a factory
 * or other managing contract
 *
 * A constructor like so:
 * constructor (address origin) public Delegate(origin)
 *
 * means that the passed 'origin' address is the original owner of the factory contract,
 * the msg.sender that is passed implicitly through the Delegate constructor
 * is the factory contract that calls the constructor
 *
 **/

contract Delegate is FactoryOwned {

  // Allow extenders to check function caller against list of permitted callers
  modifier restrictToPermitted {
    if (permittedCallers[msg.sender] || msg.sender == owner || msg.sender == factory) _;
    else revert();
  }

  // Mapping for all allowed callers (other contracts)
  mapping (address => bool) permittedCallers;

  constructor (address origin) public FactoryOwned(origin) {
    if (origin != address(0)) {
      // Add the origin and caller as permitted callers
      addPermittedCaller(msg.sender);
      addPermittedCaller(origin);
    } else {
      revert();
    }
  }

  // ---
  // Permission functions
  // ---

  // Add an address as a permitted caller
  function addPermittedCaller (address addr) restrictToCreators public {
    if (addr != address(0)) {
      permittedCallers[addr] = true;
    } else {
      revert();
    }
  }

  // Remove an address from permitted callers
  function removePermittedCaller (address addr) restrictToCreators public {
    if (addr != address(0)) {
      permittedCallers[addr] = false;
    } else {
      revert();
    }
  }
}

