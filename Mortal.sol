pragma solidity ^0.4.15;

contract Mortal {
  address owner;

  modifier restricted {
    if (msg.sender == owner) _;
  }

  /*
    Set contract owner
  */
  function Mortal() public {
    owner = msg.sender;
  }

  /*
    Kill contract and return funds to owner (can only be executed by owner)
  */
  function kill() restricted public {
    selfdestruct(owner);
  }

  /*
    Change owner to new address
  */
  function chown(address _address) restricted public {
    owner = _address;
  }
}
