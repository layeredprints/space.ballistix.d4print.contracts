pragma solidity ^0.4.15;

import "./Mortal.sol";

contract Users is Mortal {
  struct User {
    address addr;
    bytes32 role;
  }

  mapping(address => User) public users;

  event UserPatch(address indexed _address);
  event UserDestroy(address indexed _address);

  function exists (address _address) public constant returns (bool _exists) {
    return (users[_address].addr != address(0));
  }

  function patch (address _address, bytes32 _role) restricted public {
    users[_address] = User({addr: _address, role: _role}) ;
    UserPatch(_address);
  }

  function destroy (address _address) restricted public {
    require(exists(_address));
    delete users[_address];
    UserDestroy(_address);
  }

  function get (address _address) public constant returns(address, bytes32) {
    require(exists(_address));
    return (users[_address].addr, users[_address].role);
  }
}
