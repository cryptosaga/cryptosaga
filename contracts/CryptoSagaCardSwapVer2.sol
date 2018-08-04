pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

import "./CryptoSagaCardSwap.sol";
import "./CryptoSagaHero.sol";
import "./Gold.sol";

/**
 * @title CryptoSagaCardSwapVer2
 * @dev This directly summons hero. Version 1.0.1
 */
contract CryptoSagaCardSwapVer2 is CryptoSagaCardSwap, Pausable{

  // Eth will be sent to this wallet.
  address public wallet;

  // The hero contract.
  CryptoSagaHero public heroContract;

  // Gold contract.
  Gold public goldContract;

  // Eth-Summon price.
  uint256 public ethPrice = 20000000000000000; // 0.02 eth.

  // Gold-Summon price.
  uint256 public goldPrice = 100000000000000000000; // 100 G. Should worth around 0.00004 eth at launch.

  // Mileage Point Summon price.
  uint256 public mileagePointPrice = 100;

  // Blacklisted heroes.
  // This is needed in order to protect players, in case there exists any hero with critical issues.
  // We promise we will use this function carefully, and this won't be used for balancing the OP heroes.
  mapping(uint32 => bool) public blackList;

  // Mileage points of each player.
  mapping(address => uint256) public addressToMileagePoint;

  // Last timestamp of summoning a free hero.
  mapping(address => uint256) public addressToFreeSummonTimestamp;

  // Random seed.
  uint32 private seed = 0;

  // @dev Get the mileage points of given address.
  function getMileagePoint(address _address)
    public view
    returns (uint256)
  {
    return addressToMileagePoint[_address];
  }

  // @dev Get the summon timestamp of given address.
  function getFreeSummonTimestamp(address _address)
    public view
    returns (uint256)
  {
    return addressToFreeSummonTimestamp[_address];
  }

  // @dev Set the price of summoning a hero with Eth.
  function setEthPrice(uint256 _value)
    onlyOwner
    public
  {
    ethPrice = _value;
  }

  // @dev Set the price of summoning a hero with Gold.
  function setGoldPrice(uint256 _value)
    onlyOwner
    public
  {
    goldPrice = _value;
  }

  // @dev Set the price of summong a hero with Mileage Points.
  function setMileagePointPrice(uint256 _value)
    onlyOwner
    public
  {
    mileagePointPrice = _value;
  }

  // @dev Set blacklist.
  function setBlacklist(uint32 _classId, bool _value)
    onlyOwner
    public
  {
    blackList[_classId] = _value;
  }

  // @dev Increment mileage points.
  function addMileagePoint(address _beneficiary, uint256 _point)
    onlyOwner
    public
  {
    require(_beneficiary != address(0));

    addressToMileagePoint[_beneficiary] += _point;
  }

  // @dev Contructor.
  function CryptoSagaCardSwapVer2(address _heroAddress, address _goldAddress, address _cardAddress, address _walletAddress)
    public
  {
    require(_heroAddress != address(0));
    require(_goldAddress != address(0));
    require(_cardAddress != address(0));
    require(_walletAddress != address(0));
    
    wallet = _walletAddress;

    heroContract = CryptoSagaHero(_heroAddress);
    goldContract = Gold(_goldAddress);
    setCardContract(_cardAddress);
  }

  // @dev Swap a card for a hero.
  function swapCardForReward(address _by, uint8 _rank)
    onlyCard
    whenNotPaused
    public
    returns (uint256)
  {
    // This is becaue we need to use tx.origin here.
    // _by should be the beneficiary, but due to the bug that is already exist with CryptoSagaCard.sol,
    // tx.origin is used instead of _by.
    require(tx.origin != _by && tx.origin != msg.sender);

    // Get value 0 ~ 9999.
    var _randomValue = random(10000, 0);

    // We hard-code this in order to give credential to the players. 
    uint8 _heroRankToMint = 0; 

    if (_rank == 0) { // Origin Card. 85% Heroic, 15% Legendary.
      if (_randomValue < 8500) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }
    } else if (_rank == 3) { // Dungeon Chest card.
      if (_randomValue < 6500) {
        _heroRankToMint = 1;
      } else if (_randomValue < 9945) {
        _heroRankToMint = 2;
      }  else if (_randomValue < 9995) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }
    } else { // Do nothing here.
      _heroRankToMint = 0;
    }
    
    // Summon the hero.
    return summonHero(tx.origin, _heroRankToMint);

  }

  // @dev Pay with Eth.
  function payWithEth(uint256 _amount, address _referralAddress)
    whenNotPaused
    public
    payable
  {
    require(msg.sender != address(0));
    // Referral address shouldn't be the same address.
    require(msg.sender != _referralAddress);
    // Up to 5 purchases at once.
    require(_amount >= 1 && _amount <= 5);

    var _priceOfBundle = ethPrice * _amount;

    require(msg.value >= _priceOfBundle);

    // Send the raised eth to the wallet.
    wallet.transfer(_priceOfBundle);

    for (uint i = 0; i < _amount; i ++) {
      // Get value 0 ~ 9999.
      var _randomValue = random(10000, 0);
      
      // We hard-code this in order to give credential to the players. 
      uint8 _heroRankToMint = 0; 

      if (_randomValue < 5000) {
        _heroRankToMint = 1;
      } else if (_randomValue < 9550) {
        _heroRankToMint = 2;
      }  else if (_randomValue < 9950) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }

      // Summon the hero.
      summonHero(msg.sender, _heroRankToMint);

      // In case there exists referral address...
      if (_referralAddress != address(0)) {
        // Add mileage to the referral address.
        addressToMileagePoint[_referralAddress] += 5;
        addressToMileagePoint[msg.sender] += 3;
      }
    }
  }

  // @dev Pay with Gold.
  function payWithGold(uint256 _amount)
    whenNotPaused
    public
  {
    require(msg.sender != address(0));
    // Up to 5 purchases at once.
    require(_amount >= 1 && _amount <= 5);

    var _priceOfBundle = goldPrice * _amount;

    require(goldContract.allowance(msg.sender, this) >= _priceOfBundle);

    if (goldContract.transferFrom(msg.sender, this, _priceOfBundle)) {
      for (uint i = 0; i < _amount; i ++) {
        // Get value 0 ~ 9999.
        var _randomValue = random(10000, 0);
        
        // We hard-code this in order to give credential to the players. 
        uint8 _heroRankToMint = 0; 

        if (_randomValue < 3000) {
          _heroRankToMint = 0;
        } else if (_randomValue < 7500) {
          _heroRankToMint = 1;
        } else if (_randomValue < 9945) {
          _heroRankToMint = 2;
        } else if (_randomValue < 9995) {
          _heroRankToMint = 3;
        } else {
          _heroRankToMint = 4;
        }

        // Summon the hero.
        summonHero(msg.sender, _heroRankToMint);
      }
    }
  }

  // @dev Pay with Mileage.
  function payWithMileagePoint(uint256 _amount)
    whenNotPaused
    public
  {
    require(msg.sender != address(0));
    // Up to 5 purchases at once.
    require(_amount >= 1 && _amount <= 5);

    var _priceOfBundle = mileagePointPrice * _amount;

    require(addressToMileagePoint[msg.sender] >= _priceOfBundle);

    // Decrement mileage point.
    addressToMileagePoint[msg.sender] -= _priceOfBundle;

    for (uint i = 0; i < _amount; i ++) {
      // Get value 0 ~ 9999.
      var _randomValue = random(10000, 0);
      
      // We hard-code this in order to give credential to the players. 
      uint8 _heroRankToMint = 0; 

      if (_randomValue < 5000) {
        _heroRankToMint = 1;
      } else if (_randomValue < 9050) {
        _heroRankToMint = 2;
      }  else if (_randomValue < 9950) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }

      // Summon the hero.
      summonHero(msg.sender, _heroRankToMint);
    }
  }

  // @dev Free daily summon.
  function payWithDailyFreePoint()
    whenNotPaused
    public
  {
    require(msg.sender != address(0));
    // Only once a day.
    require(now > addressToFreeSummonTimestamp[msg.sender] + 1 days);
    addressToFreeSummonTimestamp[msg.sender] = now;

    // Get value 0 ~ 9999.
    var _randomValue = random(10000, 0);
    
    // We hard-code this in order to give credential to the players. 
    uint8 _heroRankToMint = 0; 

    if (_randomValue < 5500) {
      _heroRankToMint = 0;
    } else if (_randomValue < 9850) {
      _heroRankToMint = 1;
    } else {
      _heroRankToMint = 2;
    }

    // Summon the hero.
    summonHero(msg.sender, _heroRankToMint);

  }

  // @dev Summon a hero.
  // 0: Common, 1: Uncommon, 2: Rare, 3: Heroic, 4: Legendary
  function summonHero(address _to, uint8 _heroRankToMint)
    private
    returns (uint256)
  {

    // Get the list of hero classes.
    uint32 _numberOfClasses = heroContract.numberOfHeroClasses();
    uint32[] memory _candidates = new uint32[](_numberOfClasses);
    uint32 _count = 0;
    for (uint32 i = 0; i < _numberOfClasses; i ++) {
      if (heroContract.getClassRank(i) == _heroRankToMint && blackList[i] != true) {
        _candidates[_count] = i;
        _count++;
      }
    }

    require(_count != 0);
    
    return heroContract.mint(_to, _candidates[random(_count, 0)]);
  }

  // @dev return a pseudo random number between lower and upper bounds
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);
    
    seed = uint32(keccak256(keccak256(block.blockhash(block.number - 1), seed), now));
    return seed % (_upper - _lower) + _lower;
  }

}