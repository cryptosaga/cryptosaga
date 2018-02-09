pragma solidity ^0.4.18;

import "./CryptoSagaHero.sol";

contract ExampleDungeon {

  // The hero contract.
  CryptoSagaHero private heroContract;

  // @dev Constructor.
  function ExampleDungeon(address _contractAddress)
    public
  {
    heroContract = CryptoSagaHero(_contractAddress);
  }

  function deployHero(address _beneficiary, uint256 _tokenId)
    public
  {
    heroContract.deploy(_tokenId, 20180318, 0);
    heroContract.addDeposit(_beneficiary, 2770000000000000000);
    heroContract.addExp(_tokenId, 1000);
  }

}