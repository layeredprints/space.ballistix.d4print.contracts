pragma solidity ^0.4.4;

contract Migrations {
  address public migrationsOwner;
  uint public last_completed_migration;

  modifier restrictedMigration() {
    if (msg.sender == migrationsOwner) _;
  }

  constructor () public {
    migrationsOwner = msg.sender;
  }

  function setCompleted(uint completed) restrictedMigration public {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restrictedMigration public {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
