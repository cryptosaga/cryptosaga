pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title The interface contract for Card-For-Hero swap functionality.
 * @dev With this contract, a card holder can swap his/her CryptoSagaCard for reward.
 *  This contract is intended to be inherited by CryptoSagaCardSwap implementation contracts.
 */
contract CryptoSagaCardSwap is Ownable {

  // Card contract.
  address internal cardAddess;

  // Modifier for accessibility to define new hero types.
  modifier onlyCard {
    require(msg.sender == cardAddess);
    _;
  }
  
  // @dev Set the address of the contract that represents ERC721 Card.
  function setCardContract(address _contractAddress)
    public
    onlyOwner
  {
    cardAddess = _contractAddress;
  }

  // @dev Convert card into reward.
  //  This should be implemented by CryptoSagaCore later.
  function swapCardForReward(address _by, uint8 _rank)
    onlyCard
    public 
    returns (uint256);

}