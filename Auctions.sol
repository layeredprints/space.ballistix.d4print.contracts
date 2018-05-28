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

  // Mapping of existant auctions (we don't want to keep their data here, just identifier and bids)
  // First key (uint) is the auction id, second mapping is on a provider address (key) to bid amount (value)
  mapping (uint => mapping (address => uint)) public auctions;

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
    funds = Funds (addr);
  }


  // ---
  // Service functions
  // ---

  // Allow administrators to start an auction
  function addAuction (uint auctionId) isAdmin(msg.sender) public {
    ongoing[auctionId] = true;
  }

  // Allow administrators to end an auction todo: this does not perform the needed logic
  function endAuction (uint auctionId) isAdmin(msg.sender) public {
    ongoing[auctionId] = false;
  }

  // Allow admin to get winner for an auction
  // note: if this gets an auctionid that is invalid, it will likely return null, that's expected behaviour it think
  function getWinner (uint auctionId) view isAdmin(msg.sender) public returns (address) {
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
    return winner;
  }

  // Allow admin to finish up auction with the calculated winner
  function finishAuction (uint auctionId, address winner) isAdmin(msg.sender) public {
    // todo: keep the funds of the winner, take a fee on that and pay ourselves, they get the rest back (?)
    // todo: refund / unReserve the funds of the rest of the participants
    // Unreserve all the funds for this auction, except for the winner's
    for(uint i = 1; i <= numberOfBids; i++) {
      address participant = participants[auctionId][i];
      if (participant != winner) {
        uint bid = auctions[auctionId][participant];
        funds.unReserve(bid, participant);
      }
    }

    // calculate the fee
    uint bid = auctions[auctionId][winner];
    uint fee = funds.calculateFee(bid);
    // transfer that fee from the winner's reserve to our balance
    //
    // the reserved funds need to be transferred away from the winner into a company wallet,
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

  // instead of refunding all providers (besides the winner) in a list / loop at contract end, make providers withdraw their own refunds,
  // otherwise that function is much too computationally expensive
  // same for deciding when an auction is over, make that an external call, don't check inside of the contract

}
