pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";
import "./AccessDeploy.sol";

/**
 * @title CryptoSagaDungeonProgress
 * @dev Storage contract for progress of dungeons.
 */
contract CryptoSagaDungeonProgress is Claimable, AccessDeploy {

  // The progress of the player in dungeons.
  mapping(address => uint32[25]) public addressToProgress;

  // @dev Get progress.
  function getProgressOfAddressAndId(address _address, uint32 _id)
    external view
    returns (uint32)
  {
    var _progressList = addressToProgress[_address];
    return _progressList[_id];
  }

  // @dev Increment progress.
  function incrementProgressOfAddressAndId(address _address, uint32 _id)
    onlyAccessDeploy
    public
  {
    var _progressList = addressToProgress[_address];
    _progressList[_id]++;
    addressToProgress[_address] = _progressList;
  }
}