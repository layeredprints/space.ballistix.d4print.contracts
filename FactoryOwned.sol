pragma solidity ^0.4.18;

import "./Owned.sol";

/**
 * Intended to be extended by other contracts, specifically the Delegate contract
 *
 * Contracts that extend Owned are assumed to be created by a factory contract,
 * we want to keep track of the original creator of the factory, as well as the
 *
 * Enable the extending contracts to check function callers for ownership or
 * ownership by factory
 *
 * A constructor like so:
 * constructor (address origin) public FactoryOwned(origin)
 *
 * means that the passed 'origin' address is the owner of the factory contract,
 * the msg.sender that is passed implicitly through the FactoryOwned constructor
 * is the factory contract that calls the constructor
 *
 **/

contract FactoryOwned is Owned {

  // Allow extenders to check function caller against owner or owning factory
  modifier restrictToCreators {
    if (msg.sender == owner || msg.sender == factory) _;
    else revert();
  }

  address public factory;

  constructor (address origin) public Owned (origin) {
    // Don't allow an empty owner, that's about all we can do
    if (origin != address(0)) {
      factory = msg.sender;
    } else {
      revert();
    }
  }


  // ---
  // Contract functions
  // ---

  // Allow for updating the owning (factory) contract, since it may change
  function updateFactory (address addr) restrictToCreators public {
    if (addr != address(0)) {
      factory = addr;
    } else {
      revert();
    }
  }

}
