pragma solidity ^0.4.18;

import "./CryptoSagaCardSwap.sol";

contract ExampleSwap is CryptoSagaCardSwap {

  function swapCardForReward(address _by, uint8 _rank)
    onlyCard
    public 
    returns (uint256)
  {
    if (_by != address(0)) {
      return 10;
    } else {
      return 11;
    }
  }
  
}