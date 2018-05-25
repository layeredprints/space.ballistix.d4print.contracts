pragma solidity ^0.4.18;

/**
 * Generic parent contract that allows function call checking against its initial creator
 *
 * A constructor like so:
 * constructor() public Owned(msg.sender)
 *
 * means that the caller of that constructor owns that instance of the contract
 *
 **/

contract Owned {

  // Allow extenders to check function caller against owner
  modifier restrictToOwner {
    if (msg.sender == owner) _;
    else revert();
  }

  address public owner;

  constructor (address addr) public {
    owner = addr;
  }

}
