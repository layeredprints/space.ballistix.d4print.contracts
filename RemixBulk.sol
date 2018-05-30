pragma solidity ^0.4.18;

/**
 * You can paste this into Remix at http://remix.ethereum.org to test the contracts
 *
 * Deploy individually, or deploy the Factory contract
 *
 * Contracts can be added by reference by selecting the correct contract type
 * and pasting the reference address in the "Load contract from Address" under deploy
 *
 * It's best to turn off Auto compile to keep the page reactive
 *
 * todo: apply Mortal where appropriate
 * todo: proxy contract for the factory (?)
 *
 **/

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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
    if (addr != address(0)) {
      owner = addr;
    } else {
      revert();
    }
  }

}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

// debug and testing stuff

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

/**
 * Funds contract that manages the service funds for all users
 *
 * funds can be deposited, withdrawn and reserved
 *
 **/

contract Funds is Delegate, Secured {

  // Mapping for the balance of each account within the Funds wallet
  mapping (address => uint) balances;

  // Mapping for the funds in reservation
  mapping (address => uint) reservations;

  // Fee for payout calculation
  uint private fee = 1; // default is 1%

  constructor (address origin, address usersContractAddres) public Delegate(origin) Secured(usersContractAddres) {
    // do other stuff
  }


  // ---
  // Contract functions
  // ---



  // ---
  // Direct Service functions (called by users directly)
  // ---

  // Allow the owner to fill the contract buffer
  function fillBuffer (uint amount) isAdmin(msg.sender) public payable {
    // Check if the owner is filling how much they say they are
    if (msg.value == amount) {
      // Update the balance for the owner (this keeps track of the buffer initially, but also has to be updated when it is used)
      balances[msg.sender] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow users to deposit funds into their wallet
  function deposit (uint amount) isCustomerOrProvider(msg.sender) public payable {
    // Check if the user is paying how much they say they are
    if (msg.value == amount) {
      // Update the balance
      balances[msg.sender] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow users to check their funds
  function getDeposit () view isCustomerOrProvider(msg.sender) public returns (uint) {
    return balances[msg.sender];
  }

  // Allow users to check their reserve
  function getReserve () view isCustomerOrProvider(msg.sender) public returns (uint) {
    return reservations[msg.sender];
  }

  // Allow users to withdraw funds from their wallet
  function withdraw (uint amount) isCustomerOrProvider(msg.sender) public {
    // Check if the user has that amount or more
    if (balances[msg.sender] >= amount) {
      // Send the funds
      msg.sender.transfer(amount);
      // Subtract the amount from the balance
      balances[msg.sender] -= amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow users to transfer funds to other wallets
  function transfer (uint amount, address destination) isCustomerOrProvider(msg.sender) public {
    // Check if the user has that amount or more
    if (balances[msg.sender] >= amount) {
      // Subtract the amount from the balance of the user
      balances[msg.sender] -= amount;
      // Add the amount to the balance of the destination
      balances[destination] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin to transfer funds between any wallets
  function transfer (uint amount, address source, address destination) isAdmin(msg.sender) public {
    // Check if the source has that amount or more
    if (balances[source] >= amount) {
      // Subtract the amount from the balance of the source
      balances[source] -= amount;
      // Add the amount to the balance of the destination
      balances[destination] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin to update the fee
  function updateFee (uint newFee) isAdmin(msg.sender) public {
    if (newFee >= 0 && newFee <= 100) {
      fee = newFee;
    }
  }

  // ---
  // Delegate Service functions (called by trused contracts and admins)
  // ---

  // Reserve funds
  function reserve (uint amount, address source) restrictToPermitted public {
    // Check if the source has that amount or more
    if (balances[source] >= amount) {
      // Subtract the amount from the balance of the source
      balances[source] -= amount;
      // Add that amount to the reservations of the source
      reservations[source] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Unreserve funds
  function unReserve (uint amount, address source) restrictToPermitted public {
    // Check if the source has that amount or more in reservations
    if (reservations[source] >= amount) {
      // Subtract the amount from the reservations of the source
      reservations[source] -= amount;
      // Add that amount to the balance of the source
      balances[source] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Unreserve all funds
  function unReserve (address source) restrictToPermitted public {
    // Get the total funds in reservations for the source
    uint amount = reservations[source];
    // Subtract the amount from the reservations of the source
    reservations[source] -= amount;
    // Add that amount to the balance of the source
    balances[source] += amount;
  }

  // Calculate the fee
  function calculateFee (uint amount) view restrictToPermitted public returns (uint) {
    if (amount > 0) {
      return (amount / 100) * fee;
    } else {
      revert();
    }
  }

  // Allow admin to transfer reserves
  // NOTE: this transfers from source RESERVE to destination BALANCE, not destination RESERVE
  function transferReserve (uint amount, address source, address destination) restrictToPermitted public {
    // Check if the source has that amount or more in reservations
    if (reservations[source] >= amount) {
      // Subtract the amount from the reservations of the source
      reservations[source] -= amount;
      // Add that amount to the balance of the destination
      balances[destination] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin to transfer reserves
  // NOTE: this transfers from source RESERVE to owner BALANCE, not owner RESERVE
  function transferReserve (uint amount, address source) restrictToPermitted public {
    // Check if the source has that amount or more in reservations
    if (reservations[source] >= amount) {
      // Subtract the amount from the reservations of the source
      reservations[source] -= amount;
      // Add that amount to the balance of the destination
      balances[owner] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin to pay out from admin account
  function transferOwnerFunds (uint amount, address destination) restrictToPermitted public {
    // Check if the source has that amount or more in balance
    if (balances[owner] >= amount) {
      // Subtract the amount from the balance of the owner
      balances[owner] -= amount;
      // Add that amount to the balance of the destination
      balances[destination] += amount;
    } else {
      revert();
    }
  }

  // Check reserve
  function getReserve (address source) view restrictToPermitted public returns (uint) {
    return reservations[source];
  }
}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

/**
 * Auctions contract that manages the service auctions for all users
 *
 * auctions can be created, cancelled, ended, etc
 *
 * when providers bid on an auction, this contract interacts with the Funds contract to reserve the necessary funds
 *
 **/

contract Auctions is Delegate, Secured {

  struct Auction {
    uint id;
    uint itemCount; // we can pay out the provider in increments based on this
    address winner;
    uint partsPayed;
  }

  // Reference to the funds contract
  Funds public funds;

  // Mapping of existant auctions (we don't want to keep their data here, just identifier and bids)
  // First key (uint) is the auction id, second mapping is on a provider address (key) to bid amount (value)
  mapping (uint => mapping (address => uint)) public auctions;
  mapping (uint => Auction) public auctionsData;

  // Keep track of which auctions are ongoing
  mapping (uint => bool) public ongoing;

  // Keep track of the bid count for auctions (necessary for winner iteration :( )
  mapping (uint => uint) public bidCount;

  // Keep track of participating providers per auction (also necessary for winner iteration :(( )
  mapping (uint => mapping (uint => address)) public participants;

  // (keep track of which auctions are finished?)

  constructor (address origin, address usersContractAddres, address fundsContractAddress) public Delegate(origin) Secured(usersContractAddres) {
    updateFundsContractReference(fundsContractAddress);
  }


  // ---
  // Contract functions
  // ---

  // Allow for updating the owning (factory) contract, since it may change
  function updateFundsContractReference (address addr) restrict public {
    if (addr != address(0)) {
      funds = Funds (addr);
    } else {
      revert();
    }
  }


  // ---
  // Service functions
  // ---

  // Allow administrators to start an auction
  function addAuction (uint auctionId, uint itemCount) isAdmin(msg.sender) public {
    ongoing[auctionId] = true;
    Auction memory auc = Auction ({
      id: auctionId,
      itemCount: itemCount,
      winner: address(0),
      partsPayed: 0
      });
    auctionsData[auctionId] = auc;
  }

  // Allow administrators to end an auction todo: this does not perform the needed logic
  function endAuction (uint auctionId) isAdmin(msg.sender) public {
    ongoing[auctionId] = false;
  }

  // Allow admin to get winner for an auction
  // note: if this gets an auctionid that is invalid, it will likely return null, that's expected behaviour it think
  function getWinner (uint auctionId) isAdmin(msg.sender) public returns (address) {

    // return the winner if we already calculated it
    if (auctionsData[auctionId].winner != address(0)) {
      return auctionsData[auctionId].winner;
    }

    // calculate the winner
    address winner;
    uint largestBid = 0;
    // get the bidcount
    uint numberOfBids = bidCount[auctionId];
    // iterate the mapping
    for(uint i = 1; i <= numberOfBids; i++) {
      // get the participant address
      address participant = participants[auctionId][i];
      // get the value that participant bid
      uint bid = auctions[auctionId][participant];
      if (bid > largestBid) {
        largestBid = bid;
        winner = participant;
      }
    }

    // assign the winner
    auctionsData[auctionId].winner = winner;
    return winner;
  }

  // Allow admin to finish up auction with the calculated winner
  function finishAuction (uint auctionId, address winner) isAdmin(msg.sender) public {
    // todo: keep the funds of the winner, take a fee on that and pay ourselves, they get the rest back (?)
    // todo: refund / unReserve the funds of the rest of the participants
    // Unreserve all the funds for this auction, except for the winner's
    uint numberOfBids = bidCount[auctionId];

    for(uint i = 1; i <= numberOfBids; i++) {
      address participant = participants[auctionId][i];
      if (participant != winner) {
        uint bid = auctions[auctionId][participant];
        funds.unReserve(bid, participant);
      }
    }

    // transfer everything from the winner to the owner account
    uint winningBid = auctions[auctionId][winner];
    funds.transferReserve(winningBid, winner);
  }

  // todo: we need some kind of confirmation function that checks a customer if their item has been delivered, then checks the batch that item was in
  // if the entire batch has been delivered, the provider should be paid (or pay them in percentage increments)

  // Allow providers to bid on ongoing auctions (replace their bid if they bid again, this has to re-reserve those funds)
  function bid (uint auctionId, uint amount) isProvider(msg.sender) public {
    // Check if the auction is ongoing
    if (ongoing[auctionId]) {
      // If the amount is smaller than or equal to zero or the present amount, do nothing
      if (amount <= 0 || auctions[auctionId][msg.sender] == amount) {
        revert();
      }

      // Otherwise check if there is already a bid amount
      if (auctions[auctionId][msg.sender] > 0) {
        // If the new amount is larger than the present amount, we just reserve the remainder and update the bid
        if (amount > auctions[auctionId][msg.sender]) {
          uint remainder = amount - auctions[auctionId][msg.sender];
          funds.reserve(remainder, msg.sender);
          auctions[auctionId][msg.sender] = amount;
        } else { // The new amount is smaller, unreserve the difference, update the bid
          uint difference = auctions[auctionId][msg.sender] - amount;
          funds.unReserve(difference, msg.sender);
          auctions[auctionId][msg.sender] = amount;
        }
      } else { // Simply reserve the bid amount, increment the total bid count and assign that address with that participant index
        funds.reserve(amount, msg.sender);
        auctions[auctionId][msg.sender] = amount;
        bidCount[auctionId] += 1;
        participants[auctionId][bidCount[auctionId]] = msg.sender;
      }
    } else {
      revert();
    }
  }

  // ---
  // Delegate Service functions (called by trused contracts and admins)
  // ---

  // Allow part of auction to be payed out to provider
  function payoutPart (uint auctionId) restrictToPermitted public {
    Auction memory auc = auctionsData[auctionId];
    if (auc.itemCount > auc.partsPayed) {
      // get the winning bid
      uint winningBid = auctions[auctionId][auc.winner];
      // subtract the fee
      uint fee = funds.calculateFee(winningBid);
      uint total = winningBid - fee;
      // calculate the part
      uint part = total / auc.itemCount;
      // pay that amount to the provider from the owner account
      funds.transferOwnerFunds(part, auc.winner);
      // update the auction data
      auctionsData[auctionId].partsPayed += 1;

      // repay the deposit if this was the last part
      if (auctionsData[auctionId].itemCount == auctionsData[auctionId].partsPayed) {
        refund(auctionId);
      }
    } else {
      revert();
    }
    //   auctionsData[auctionId]
    // the amount to be payed to the provider is the winning bid - our fee divided by the item count in the auction
    // we can check itemCount vs partsPayed to see if everything has been paid
  }

  // Allow full deposit to be payed back to provider
  function refund (uint auctionId) restrictToPermitted public {
    // get the winning bid, this was originally deposited as escrow / downpayment
    uint winningBid = auctions[auctionId][auc.winner];
    // pay that amount to the provider from the owner account
    funds.transferOwnerFunds(winningBid, auc.winner);
  }

  // instead of refunding all providers (besides the winner) in a list / loop at contract end, make providers withdraw their own refunds,
  // otherwise that function is much too computationally expensive
  // same for deciding when an auction is over, make that an external call, don't check inside of the contract

}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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
    if (addr != address(0)) {
      administrators[addr] = true;
    } else {
      revert();
    }
  }

  // Add an address to providers
  function addProvider (address addr) restrictToCreators public {
    if (addr != address(0)) {
      providers[addr] = true;
    } else {
      revert();
    }
  }

  // Add an address to customers
  function addCustomer (address addr) restrictToCreators public {
    if (addr != address(0)) {
      customers[addr] = true;
    } else {
      revert();
    }
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

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

/**
 * Factory contract that manages the chain of contracts and their interdependence
 *
 * Users, Funds, Items and Auctions contracts can be interacted with
 * References to those contracts can be updated, both within the contract and in the contracts that depend on the updated information
 *
 * this contract is more of an easy debugging contract, but can be extended to a proper proxy chain managing contract
 *
 * note: be sure to provide enough gas when deploying this contract, it invokes a lot of other code and runs out pretty quick
 * the overall cost once deployed is fairly reasonable
 *
 **/

contract Factory is Owned {

  // Contract references
  Users private users;
  Funds private funds;
  Items private items;
  Auctions private auctions;


  constructor() public Owned(msg.sender) {
    // Create the users contract, reference us and the factory as owners
    users = new Users(msg.sender);

    // Create the funds contract, reference us and the factory as owners, reference the users contract for access management
    funds = new Funds(msg.sender, users);

    // Create the auctions contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    auctions = new Auctions(msg.sender, users, funds);

    // Create the items contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    items = new Items(msg.sender, users, funds, auctions);

    // Add Funds, Items and Auctions to the permitted callers of the Users contract
    users.addPermittedCaller(funds);
    users.addPermittedCaller(items);
    users.addPermittedCaller(auctions);

    // Add Items and Auctions to the permitted callers of the Funds contract
    funds.addPermittedCaller(items);
    funds.addPermittedCaller(auctions);

    // Add Items to the permitted callers of the Auctions contract
    auctions.addPermittedCaller(items);
  }


  // ---
  // Contract functions
  // ---

  // Update the users contract reference for the linked contracts
  function updateUsersReference (address newAddr) restrictToOwner public {
    if (newAddr != address(0)) {
      // Update the local reference and pointer
      users = new Users(newAddr);

      // Update the individual contract's references
      funds.updateUsersContractReference(users);
      items.updateUsersContractReference(users);
      auctions.updateUsersContractReference(users);
    } else {
      revert();
    }
  }

  // Update the funds contract reference for the linked contracts
  function updateFundsReference (address newAddr) restrictToOwner public {
    if (newAddr != address(0)) {
      // Update the local reference and pointer
      funds = new Funds(newAddr, users);

      // Update the individual contract's references
      items.updateFundsContractReference(funds);
      auctions.updateFundsContractReference(funds);
    } else {
      revert();
    }
  }

  function getUsersReference() view restrictToOwner public returns (Users) {
    return users;
  }

  function getFundsReference() view restrictToOwner public returns (Funds) {
    return funds;
  }

  function getItemsReference() view restrictToOwner public returns (Items) {
    return items;
  }

  function getAuctionsReference() view restrictToOwner public returns (Auctions) {
    return auctions;
  }

  // ---
  // Service functions
  // ---


}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

// todo: proxy contract for the factory
