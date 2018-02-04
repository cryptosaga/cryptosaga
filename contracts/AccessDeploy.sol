pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";

/**
 * @title AccessDeploy
 * @dev Adds grant/revoke functions to the contract.
 */
contract AccessDeploy is Claimable {

  // Access for deploying heroes.
  mapping(address => bool) private deployAccess;

  // Modifier for accessibility to deploy a hero on a location.
  modifier onlyAccessDeploy {
    require(msg.sender == owner || deployAccess[msg.sender] == true);
    _;
  }

  // @dev Grant acess to deploy heroes.
  function grantAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = true;
  }

  // @dev Revoke acess to deploy heroes.
  function revokeAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = false;
  }

}