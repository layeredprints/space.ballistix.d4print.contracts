pragma solidity ^0.4.15;

import "./Mortal.sol";


contract Deposit is Mortal {

  modifier restrictedToOwner {
    if (msg.sender == owner) _;
    else revert();
  }

  modifier restrictedToClient {
    if (msg.sender == client) _;
    else revert();
  }

  uint256 private identifier;

  uint public price;
  uint public fee;

  mapping (address => uint) balances;

  address public client; // this is the address that deposits the funds, and receives or looses them in case of ...
  address public service; // this is the address that will receive funds in case of ... (this will be us)

  address public owner = msg.sender;

  bool clientApprove;
  bool serviceApprove;

  // Initialize the contract
  function setup (address theClient, address theService, uint256 theIdentifier, uint thePrice, uint theFee) restrictedToOwner public {
    client = theClient;
    service = theService;

    identifier = theIdentifier;
    price = thePrice;
    fee = theFee;
  }

  // Refund the client
  function refund () restrictedToOwner public { // todo: do we want to allow the client to cancel on their own? or just us?
    // get the amount that this client deposited
    uint deposited = balances[client];
    // subtract that
    balances[client] -= deposited;
    // send that back
    client.transfer(deposited);
  }

  // Send fee to service in case of success
  function sendFee () restrictedToOwner public {
    // get the fee for this client's deposit
    uint calculatedFee = balances[client] / fee; // 1% fee
    // subtract that from the balance
    balances[client] -= calculatedFee;
    // send the fee to the service
    service.transfer(calculatedFee);
  }

  // Allow the client and the service to approve the payout
  function approve () public {
    if (msg.sender == client) {
      clientApprove = true;
    } else if (msg.sender == service) {
      serviceApprove = true;
    }
  }

  // Allow the client to deposit funds
  function deposit () restrictedToClient public payable {
    if (msg.value == price) {
      balances[client] += msg.value;
    } else {
      revert();
    }
  }

  // Payout the fee to the service, the deposit minus the fee to the client
  function payOut() public {
    if (clientApprove && serviceApprove) {
      sendFee();
      refund();
    } else {
      revert();
    }
  }

  function getIdentifier() public view returns (uint256) {
    return identifier;
  }

}

