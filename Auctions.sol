pragma solidity ^0.4.18;

import "./Funds.sol";
import "./Secured.sol";
import "./Delegate.sol";

contract Auctions is Delegate, Secured {

  // Reference to the funds contract
  Funds public funds;

  // Reference to the Funds contract address
  address public fundsAddress;

  uint public zehVar;

  constructor (address origin, address usersContractAddres, address fundsContractAddress) public Delegate(origin) Secured(usersContractAddres) {
    updateFundsContractReference(fundsContractAddress);
  }

  function test (uint nuVar) isAdmin(msg.sender) public {
    zehVar = nuVar;
  }

  // Allow for updating the owning (factory) contract, since it may change
  function updateFundsContractReference (address addr) restrict public {
    fundsAddress = addr;
    funds = Funds (fundsAddress);
  }
}
