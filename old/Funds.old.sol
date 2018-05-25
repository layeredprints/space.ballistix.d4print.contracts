pragma solidity ^0.4.18;

contract Funds {
  // note: probably went a bit overboard wiht the comments, but clarity is key here

  modifier restrictedToOwner {
    if (msg.sender == owner) _;
    else revert();
  }

  // Mapping for the balance of each account within the Funds wallet
  mapping (address => uint) balances;

  // Mapping for the funds in reservation
  mapping (address => uint) reservations;

  address public owner = msg.sender;

  // Allow users to deposit funds into their wallet
  function deposit (uint amount) public payable {
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
  function withdraw (uint amount) public {
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
  function transfer (uint amount, address destination) public {
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
  function transfer (uint amount, address source, address destination) restrictedToOwner public {
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

  // Allow admin and user to reserve funds
  function reserve (uint amount, address source) public {
    // Check if source is either user themselves or admin
    if (msg.sender == source || msg.sender == owner) {
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
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin (and user?) to unreserve funds
  function unReserve (uint amount, address source) public {
    // Check if source is either user themselves or admin
    if (msg.sender == source || msg.sender == owner) {
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
    } else {
      // If failed, revert
      revert();
    }
  }

  // Allow admin (and user?) to unreserve all funds
  function unReserve (address source) public {
    // Check if source is either user themselves or admin
    if (msg.sender == source || msg.sender == owner) {
      // Get the total funds in reservations for the source
      uint amount = reservations[source];
      // Subtract the amount from the reservations of the source
      reservations[source] -= amount;
      // Add that amount to the balance of the source
      balances[source] += amount;
    } else {
      // If failed, revert
      revert();
    }
  }
}
