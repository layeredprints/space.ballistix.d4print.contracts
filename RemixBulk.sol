pragma solidity ^0.4.0;

pragma solidity ^0.4.18;



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
    owner = addr;
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
    factory = addr;
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
    // Add the origin and caller as permitted callers
    addPermittedCaller(msg.sender);
    addPermittedCaller(origin);
  }

  // ---
  // Permission functions
  // ---

  // Add an address as a permitted caller
  function addPermittedCaller (address addr) restrictToCreators public {
    permittedCallers[addr] = true;
  }

  // Remove an address from permitted callers
  function removePermittedCaller (address addr) restrictToCreators public {
    permittedCallers[addr] = false;
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
  address public usersAddress;

  Users public users;

  constructor (address addr) public {
    usersAddress = addr;
    origin = msg.sender;
    users = Users (usersAddress);
  }


  // ---
  // Contract functions
  // ---

  // Allow for updating the owning (factory) contract, since it may change
  function updateUsersContractReference (address addr) restrict public {
    usersAddress = addr;
    users = Users (usersAddress);
  }
}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

// debug and testing stuff

contract TestModifiers {

  modifier isFalse {
    if (false) _;
    else revert();
  }

  modifier isTrue {
    if (true) _;
    else revert();
  }

  uint public zehVar;

  function foo (uint nuVar) isFalse isTrue public {
    zehVar = nuVar;
  }

}

contract Test is FactoryOwned {

  uint someVar;

  constructor (address origin) public FactoryOwned(origin) {
    // do other stuff
  }

  function foo (uint varVal) restrictToCreators public {
    // do ya thing
    someVar = varVal;
  }

}

contract Test2 is Delegate {

  uint someVar;

  constructor (address origin) public Delegate(origin) {
    // do other stuff
  }

  function foo (uint varVal) restrictToCreators public {
    // do ya thing
    someVar = varVal;
  }

}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

contract Funds is Delegate, Secured {

  // Mapping for the balance of each account within the Funds wallet
  mapping (address => uint) balances;

  // Mapping for the funds in reservation
  mapping (address => uint) reservations;

  // address public owner = msg.sender;
  address public itemsContract;

  constructor (address origin, address usersContractAddres) public Delegate(origin) Secured(usersContractAddres) {
    // do other stuff
  }


  // ---
  // Contract functions
  // ---

  // Set the address for the items contract for interaction
  function init (address addr) restrictToCreators public {
    itemsContract = addr;
  }


  // ---
  // Direct Service functions (called by users directly)
  // ---

  // todo: add restrictToPermitted where appropriate, and update logic accordingly (or offer alternative functions)

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

  // ---
  // Delegate Service functions (called by other contracts)
  // ---

  // Allow permitted callers (admins and trusted contracts) to reserve funds
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

  // Allow permitted callers (admins and trusted contracts) to unreserve funds
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

  // Allow permitted callers (admins and trusted contracts) to unreserve all funds
  function unReserve (address source) restrictToPermitted public {
    // Get the total funds in reservations for the source
    uint amount = reservations[source];
    // Subtract the amount from the reservations of the source
    reservations[source] -= amount;
    // Add that amount to the balance of the source
    balances[source] += amount;
  }
}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

contract Items is Delegate, Secured {

  // Reference to the funds contract
  Funds public funds;

  // Reference to the Funds contract address
  address public fundsAddress;

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
    fundsAddress = addr;
    funds = Funds (fundsAddress);
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

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

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
    administrators[addr] = true;
  }

  // Add an address to providers
  function addProvider (address addr) restrictToCreators public {
    providers[addr] = true;
  }

  // Add an address to customers
  function addCustomer (address addr) restrictToCreators public {
    customers[addr] = true;
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

// this is more of a debugging contract, but we could potentially use it as a managing contract
contract Factory is Owned {

  // Contract addresses
  address public contractUsers;
  address public contractFunds;
  address public contractItems;
  address public contractAuctions;

  // Contract references
  Users private users;
  Funds private funds;
  Items private items;
  Auctions private auctions;

  // note: contract address and reference are actually the same thing, but they differ in use, it's good to have a copy of both

  constructor() public Owned(msg.sender) {
    // Create the users contract, reference us and the factory as owners
    users = new Users(msg.sender);
    contractUsers = users;

    // Create the funds contract, reference us and the factory as owners, reference the users contract for access management
    funds = new Funds(msg.sender, contractUsers);
    contractFunds = funds;

    // Create the items contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    items = new Items(msg.sender, contractUsers, contractFunds);
    contractItems = items;

    // Create the auctions contract, reference us and the factory as owners
    // Reference the users contract for access management
    // Reference the funds contract for fund management
    auctions = new Auctions(msg.sender, contractUsers, contractFunds);
    contractAuctions = auctions;

    // Add Funds, Items and Auctions to the permitted callers of the Users contract
    users.addPermittedCaller(contractFunds);
    users.addPermittedCaller(contractItems);
    users.addPermittedCaller(contractAuctions);

    // Add Items and Auctions to the permitted callers of the Funds contract
    funds.addPermittedCaller(contractItems);
    funds.addPermittedCaller(contractAuctions);
  }

  function testCall () restrictToOwner public {
    auctions.test(5);
  }

  // Update the users contract reference for the linked contracts
  function updateUsersReference (address newAddr) restrictToOwner public {
    // Update the local reference and pointer
    users = new Users(newAddr);
    contractUsers = users;

    // Update the individual contract's references
    funds.updateUsersContractReference(contractUsers);
    items.updateUsersContractReference(contractUsers);
    auctions.updateUsersContractReference(contractUsers);
  }

  // Update the funds contract reference for the linked contracts
  function updateFundsReference (address newAddr) restrictToOwner public {
    // Update the local reference and pointer
    funds = new Funds(newAddr, contractUsers);
    contractFunds = funds;

    // Update the individual contract's references
    items.updateFundsContractReference(contractFunds);
    auctions.updateFundsContractReference(contractFunds);
  }

}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

// todo: proxy contract for the factory
