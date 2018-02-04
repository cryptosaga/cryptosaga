pragma solidity ^0.4.18;

import "./CryptoSagaCardSwap.sol";
import "./CryptoSagaHero.sol";

/**
 * @title CryptoSagaCardSwapVer1
 * @dev This implements CryptoSagaCardSwap interface.
 */
contract CryptoSagaCardSwapVer1 is CryptoSagaCardSwap {

  // The hero contract.
  CryptoSagaHero private heroContract;

  // Random seed.
  uint32 private seed = 0;

  // @dev Set the address of the contract that represents CryptoSaga Cards.
  function setHeroContract(address _contractAddress)
    public
    onlyOwner
  {
    heroContract = CryptoSagaHero(_contractAddress);
  }

  // @dev Contructor.
  function CryptoSagaCardSwapVer1(address _heroAddress, address _cardAddress)
    public
  {
    require(_heroAddress != address(0));
    require(_cardAddress != address(0));

    setHeroContract(_heroAddress);
    setCardContract(_cardAddress);
  }

  // @dev Swap a card for a hero.
  //  When called by the Card contract, this will ask for 
  function swapCardForReward(address _by, uint8 _rank)
    onlyCard
    public
    returns (uint256)
  {
    // This is becaue we need to use tx.origin here.
    // _by should be the beneficiary, but due to the bug that is already exist with CryptoSagaCard.sol,
    // tx.origin is used instead of _by.
    require(tx.origin != _by && tx.origin != msg.sender);

    var _randomValue = random(100, 0);
    
    // We hard-code this in order to give credential to the players.
    // 0: Common, 1: Uncommon, 2: Rare, 3: Heroic, 4: Legendary
    uint8 _heroRankToMint = 0; 

    if (_rank == 0) { // Origin Card. 85% Heroic, 15% Legendary.
      if (_randomValue < 85) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }
    } else if (_rank == 1) { // Eth Card. 50% Uncommon, 30% Rare, 19% heroic, 1% Legendary.
      if (_randomValue < 50) {
        _heroRankToMint = 1;
      } else if (_randomValue < 80) {
        _heroRankToMint = 2;
      }  else if (_randomValue < 99) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }
    } else if (_rank == 2) { // Gold Card. 50% Common, 35% Uncommon, 15% Rare.
      if (_randomValue < 50) {
        _heroRankToMint = 0;
      } else if (_randomValue < 85) {
        _heroRankToMint = 1;
      } else {
        _heroRankToMint = 2;
      }
    } else { // Do nothing here.
      _heroRankToMint = 0;
    }

    // Get the list of hero classes.
    uint32 _numberOfClasses = heroContract.numberOfHeroClasses();
    uint32[] memory _candidates = new uint32[](_numberOfClasses);
    uint32 _count;
    for (uint32 i = 0; i < _numberOfClasses; i ++) {
      if (heroContract.getHeroClassRank(i) == _heroRankToMint) {
        _candidates[_count] = i;
        _count++;
      }
    }
    
    return heroContract.mint(tx.origin, _candidates[random(_count, 0)]);
  }

  // @dev return a pseudo random number between lower and upper bounds
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);

    seed = uint32(keccak256(keccak256(block.blockhash(block.number), seed), now));
    return seed % (_upper - _lower) + _lower;
  }

}