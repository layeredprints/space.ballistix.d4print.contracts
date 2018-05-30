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

  struct Item {
    uint id;
    // note: if we keep the price and auction id here, we could transfer the price by ourselves
    string hash;
    uint categoryId;
    bool confirmed;
  }

  // Reference to the funds contract
  Funds public funds;

  // Reference to the auctions contract
  Auctions public auctions;

  // Mapping of user's item id lists
  mapping (address => uint[]) items;

  // Mapping of user's item struct lists
  mapping (address => Item[]) itemStructs;

  // Map users to the indexes of their items
  mapping (address => mapping (uint => uint)) itemReferences;

  constructor (address origin, address usersContractAddres, address fundsContractAddress, address auctionsContractAddress) public Delegate(origin) Secured(usersContractAddres) {
    updateFundsContractReference(fundsContractAddress);
    updateAuctionsContractReference(auctionsContractAddress);
  }


  // ---
  // Contract functions
  // ---

  // Allow for updating the funds contract reference, since it may change
  function updateFundsContractReference (address addr) restrict public {
    if (addr != address(0)) {
      funds = Funds (addr);
    } else {
      revert();
    }
  }

  // Allow for updating the auctions contract reference, since it may change
  function updateAuctionsContractReference (address addr) restrict public {
    if (addr != address(0)) {
      auctions = Auctions (addr);
    } else {
      revert();
    }
  }

  // --
  // Service functions
  // ---

  // Allow user to order an item, reserves those funds (fails if they don't have them)
  function order (uint price, uint itemId, uint categoryId, string hash) isCustomer(msg.sender) public {
    funds.reserve(price, msg.sender);
    Item memory item = Item ({
      id: itemId,
      categoryId: categoryId,
      hash: hash,
      confirmed: false
      });
    items[msg.sender].push(itemId);
    uint newLength = itemStructs[msg.sender].push(item);
    // keep track of the item indices within the user's item lists for easy acces later
    itemReferences[msg.sender][itemId] = newLength - 1;
  }

  // Allow user to get filehash for item
  function getItemFileHash (uint itemId) view isCustomer(msg.sender) public returns (string) {
    uint itemIndex = itemReferences[msg.sender][itemId];
    return itemStructs[msg.sender][itemIndex].hash;
  }

  // Allow user to get category for item
  function getItemCategory (uint itemId) view isCustomer(msg.sender) public returns (uint) {
    uint itemIndex = itemReferences[msg.sender][itemId];
    return itemStructs[msg.sender][itemIndex].categoryId;
  }

  // Allow user to get confirmation status for item
  function getItemStatus (uint itemId) view isCustomer(msg.sender) public returns (bool) {
    uint itemIndex = itemReferences[msg.sender][itemId];
    return itemStructs[msg.sender][itemIndex].confirmed;
  }

  // Allow user to confirm item
  function confirmItem (uint itemId, uint auctionId) isCustomer(msg.sender) public {
    uint itemIndex = itemReferences[msg.sender][itemId];
    itemStructs[msg.sender][itemIndex].confirmed = true;
    auctions.payoutPart(auctionId);
    // todo: this should trigger some event or action that transfers
    // a percentage of the batch cost to the provider that ... provided it
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
