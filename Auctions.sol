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

  struct Auction {
    uint id;
    uint itemCount; // we can pay out the provider in increments based on this
    address winner;
    uint partsPayed;
    bool finished;
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
      partsPayed: 0,
      finished: false
      });
    auctionsData[auctionId] = auc;
  }

  // Allow administrators to end an auction todo: this does not perform the needed logic
  function endAuction (uint auctionId) isAdmin(msg.sender) public {
    ongoing[auctionId] = false;
  }

  // Allow admin to get winner for an auction
  function getWinner (uint auctionId) view isAdmin(msg.sender) public returns (address) {
    return auctionsData[auctionId].winner;
  }

  // Allow admin to finish up auction with the calculated winner
  function finishAuction (uint auctionId) isAdmin(msg.sender) public {
    if (ongoing[auctionId] && !auctionsData[auctionId].finished) {
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

      // Unreserve all the funds for this auction, except for the winner's
      uint numberOfBids = bidCount[auctionId];
      for(uint i = 1; i <= numberOfBids; i++) {
        address participant = participants[auctionId][i];
        if (participant != winner) {
          uint bid = auctions[auctionId][participant];
          funds.unReserve(bid, participant);
        }
      }

      // transfer everything from the winner to the owner account as deposit
      uint winningBid = auctions[auctionId][winner];
      funds.transferReserve(winningBid, winner);

      // set auction to done / not ongoing
      ongoing[auctionId] = false;
      auctionsData[auctionId].finished = true;
    } else {
      revert();
    }
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
