pragma solidity ^0.4.18;

import "./Delegate.sol";
import "./Secured.sol";
import "./Funds.sol";

/**
 * Items contract that manages the service items for all users
 *
 * items can be ordered, cancelled, fetched, etc
 *
 * when ordering an item or items, this contract interacts with the Funds contract to reserve the necessary funds
 *
 **/

contract Items is Delegate, Secured {

  // Reference to the funds contract
  Funds public funds;

  // Mapping for the balance of each account within the Funds wallet
  mapping (address => uint[]) items;

  constructor (address origin, address usersContractAddres, address fundsContractAddress) public Delegate(origin) Secured(usersContractAddres) {
    updateFundsContractReference(fundsContractAddress);
  }


  // ---
  // Contract functions
  // ---

  // Allow for updating the owning (factory) contract, since it may change
  function updateFundsContractReference (address addr) restrict public {
    funds = Funds (addr);
  }


  // ---
  // Service functions
  // ---

  // Allow user to order an item, which reserves those funds if they have them
  // Otherwise fail the function
  function order (uint price, uint itemId) isCustomer(msg.sender) public {
    // Reserve the funds
    funds.reserve(price, msg.sender); // be wary of the msg.sender change when executing these calls
    // Add the item to that user's list of items
    items[msg.sender].push(itemId);
  }

  // Get the items queued for the requesting user
  function getItems () view public returns (uint[]) {
    return items[msg.sender];
  }

  // Get the items queued for the given user, owner only
  function getItems (address source) view isAdmin(msg.sender) public returns (uint[]) {
    return items[source];
  }

}
