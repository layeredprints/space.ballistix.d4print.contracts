pragma solidity ^0.4.18;

import "./Funds.sol";
import "./Secured.sol";
import "./Delegate.sol";

/**
 * Auctions contract that manages the service auctions for all users
 *
 * auctions can be created, cancelled, ended, etc
 *
 * when providers bid on an auction, this contract interacts with the Funds contract to reserve the necessary funds
 *
 **/

contract Auctions is Delegate, Secured {

  // Reference to the funds contract
  Funds public funds;

  uint public zehVar;

  constructor (address origin, address usersContractAddres, address fundsContractAddress) public Delegate(origin) Secured(usersContractAddres) {
    updateFundsContractReference(fundsContractAddress);
  }

  function test (uint nuVar) isAdmin(msg.sender) public {
    zehVar = nuVar;
  }

  // Allow for updating the owning (factory) contract, since it may change
  function updateFundsContractReference (address addr) restrict public {
    funds = Funds (addr);
  }
}
