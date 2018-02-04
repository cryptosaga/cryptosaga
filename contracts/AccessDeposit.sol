pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";

/**
 * @title AccessDeposit
 * @dev Adds grant/revoke functions to the contract.
 */
contract AccessDeposit is Claimable {

  // Access for adding deposit.
  mapping(address => bool) private depositAccess;

  // Modifier for accessibility to add deposit.
  modifier onlyAccessDeposit {
    require(msg.sender == owner || depositAccess[msg.sender] == true);
    _;
  }

  // @dev Grant acess to deposit heroes.
  function grantAccessDeposit(address _address)
    onlyOwner
    public
  {
    depositAccess[_address] = true;
  }

  // @dev Revoke acess to deposit heroes.
  function revokeAccessDeposit(address _address)
    onlyOwner
    public
  {
    depositAccess[_address] = false;
  }

}