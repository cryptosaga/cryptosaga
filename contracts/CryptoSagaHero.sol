pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";

import "./AccessMint.sol";
import "./AccessDeploy.sol";
import "./AccessDeposit.sol";

import "./Gold.sol";

/**
 * @title CryptoSagaHero
 * @dev The token contract for the hero.
 *  Also a superset of the ERC721 standard that allows for the minting
 *  of the non-fungible tokens.
 */
contract CryptoSagaHero is ERC721Token, Claimable, AccessMint, AccessDeploy, AccessDeposit {

  string public constant name = "CryptoSaga Hero";
  string public constant symbol = "HERO";
  
  struct HeroClass {
    // ex) Soldier, Knight, Fighter...
    string className;

    // Race of this class.
    string classRace;
    // How old is this hero class? 
    uint32 classAge;
    // 0: Common, 1: Uncommon, 2: Rare, 3: Heroic, 4: Legendary
    uint8 classRank;
    // Possible max level of this class.
    uint32 maxLevel; 
    // 0: Water, 1: Fire, 2: Nature, 3: Light, 4: Darkness.
    uint8 aura; 

    // Initial stats of this hero type. 
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] intitialStats;
    // Minimum IVs for stats. 
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] minIVForStats;
    // Maximum IVs for stats.
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] maxIVForStats;
    
    // Number of currently instanced heroes.
    uint32 currentNumberOfInstancedHeroes;
  }
    
  struct HeroInstance {
    // What is this hero's type? ex) John, Sally, Mark...
    uint32 heroClassId;
    
    // Individual hero's name.
    string heroName;
    
    // Current level of this hero.
    uint32 currentLevel;
    // Current exp of this hero.
    uint32 currentExp;

    // Where has this hero been deployed? (0: Never depolyed ever.) ex) Dungeon Floor #1, Arena #5...
    uint32 lastLocationId;
    // When a hero is deployed, it takes time for the hero to return to the base. This is in Unix epoch.
    uint256 availableAt;

    // Current stats of this hero. 
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] currentStats;
    // The individual value for this hero's stats. 
    // This will affect the current stats of heroes.
    // Intended to be hidden. No Getter for this.
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] ivForStats;
  }

  // Required exp for level up will increase per level up.
  // This defines how it will increase.
  uint32 private requiredExpIncreasePerlevel = 100;

  // Required Gold for level up will increase per level up.
  // This defines how it will increase.
  uint256 private requiredGoldIncreasePerlevel = 1000000000000000000;

  // Existing hero classes.
  mapping(uint32 => HeroClass) public heroClasses;
  // The number of hero classes ever defined.
  uint32 public numberOfHeroClasses;

  // Existing hero instances.
  // The key is _tokenId.
  mapping(uint256 => HeroInstance) public tokenIdToHeroInstance;
  // The number of tokens ever minted. This works as the serial number.
  uint256 private numberOfTokenIds;

  // Gold contract.
  Gold private goldContract;

  // Deposit of players (in Gold).
  mapping(address => uint256) public addressToGoldDeposit;

  // Random seed.
  uint32 private seed = 0;

  // Event that is fired when a hero type defined.
  event DefineType(
    address indexed _by,
    uint32 indexed _typeId,
    string _className
  );

  // Event that is fired when a hero is upgraded.
  event LevelUp(
    address indexed _by,
    uint256 indexed _tokenId,
    uint32 _newLevel
  );

  // Event that is fired when a hero is deployed.
  event Deploy(
    address indexed _by,
    uint256 indexed _tokenId,
    uint32 _locationId,
    uint256 _duration
  );

  // @dev Get the class's class name.
  function getHeroClassName(uint32 _classId)
    public view
    returns (string)
  {
    return heroClasses[_classId].className;
  }

  // @dev Get the class's race.
  function getHeroClassRace(uint32 _classId)
    public view
    returns (string)
  {
    return heroClasses[_classId].classRace;
  }

  // @dev Get the class's age.
  function getHeroClassAge(uint32 _classId)
    public view
    returns (uint32)
  {
    return heroClasses[_classId].classAge;
  }

  // @dev Get the class's rank.
  function getHeroClassRank(uint32 _classId)
    public view
    returns (uint8)
  {
    return heroClasses[_classId].classRank;
  }

   // @dev Get the class's max level.
  function getHeroClassMaxLevel(uint32 _classId)
    public view
    returns (uint32)
  {
    return heroClasses[_classId].maxLevel;
  }

  // @dev Get the class's aura.
  function getHeroClassAura(uint32 _classId)
    public view
    returns (uint8)
  {
    return heroClasses[_classId].aura;
  }

  // @dev Get the class's base stats.
  function getHeroClassBaseStats(uint32 _classId)
    public view
    returns (uint32[5])
  {
    return heroClasses[_classId].intitialStats;
  }

  // @dev Get the class's min IVs.
  function getHeroClassMinIVs(uint32 _classId)
    public view
    returns (uint32[5])
  {
    return heroClasses[_classId].minIVForStats;
  }

  // @dev Get the class's max IVs.
  function getHeroClassMaxIVs(uint32 _classId)
    public view
    returns (uint32[5])
  {
    return heroClasses[_classId].maxIVForStats;
  }

  // @dev Get the heroes ever minted for the class.
  function getHeroClassMintCount(uint32 _classId)
    public view
    returns (uint32)
  {
    return heroClasses[_classId].currentNumberOfInstancedHeroes;
  }

  // @dev Get the hero's class id.
  function getHeroClassId(uint256 _tokenId)
    public view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].heroClassId;
  }

  // @dev Get the hero's name.
  function getHeroName(uint256 _tokenId)
    public view
    returns (string)
  {
    return tokenIdToHeroInstance[_tokenId].heroName;
  }

  // @dev Get the hero's level.
  function getHeroLevel(uint256 _tokenId)
    public view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].currentLevel;
  }
  
  // @dev Get the hero's exp.
  function getHeroExp(uint256 _tokenId)
    public view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].currentExp;
  }

  // @dev Get the hero's location.
  function getHeroLocation(uint256 _tokenId)
    public view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].lastLocationId;
  }

  // @dev Get the time when the hero become available.
  function getHeroAvailableAt(uint256 _tokenId)
    public view
    returns (uint256)
  {
    return tokenIdToHeroInstance[_tokenId].availableAt;
  }

  // @dev Get the hero's current stats.
  function getHeroStats(uint256 _tokenId)
    public view
    returns (uint32[5])
  {
    return tokenIdToHeroInstance[_tokenId].currentStats;
  }

  // @dev Get the hero's BP.
  function getHeroBP(uint256 _tokenId)
     public view
    returns (uint32)
  {
    var _tmp = tokenIdToHeroInstance[_tokenId].currentStats;
    return (_tmp[0] + _tmp[1] + _tmp[2] + _tmp[3] + _tmp[4]);
  }

  // @dev Get the deposit of gold of the player.
  function getGoldDepositOfAddress(address _address)
    public view
    returns (uint256)
  {
    return addressToGoldDeposit[_address];
  }

  // @dev Get the token id of the player's #th token.
  function getTokenIdOfAddressAndIndex(address _address, uint256 _index)
    public view
    returns (uint256)
  {
    return tokensOf(_address)[_index];
  }

  // @dev Set the hero's name.
  function setHeroName(uint256 _tokenId, string _name)
    onlyOwnerOf(_tokenId)
    public
  {
    tokenIdToHeroInstance[_tokenId].heroName = _name;
  }

  // @dev Set the address of the contract that represents ERC20 Gold.
  function setGoldContract(address _contractAddress)
    onlyOwner
    public
  {
    goldContract = Gold(_contractAddress);
  }

  // @dev Set the required golds to level up a hero.
  function setRequiredExpIncreasePerlevel(uint32 _value)
    onlyOwner
    public
  {
    requiredExpIncreasePerlevel = _value;
  }

  // @dev Set the required golds to level up a hero.
  function setRequiredGoldIncreasePerlevel(uint32 _value)
    onlyOwner
    public
  {
    requiredGoldIncreasePerlevel = _value;
  }

  // @dev Contructor.
  function CryptoSagaHero(address _goldAddress)
    public
  {
    require(_goldAddress != address(0));

    setGoldContract(_goldAddress);

    // Initial heroes.
    // Name, Max level, Race, Age, Rank, Aura, Stats. 
    defineType("Archangel", 120, "Celestial", 13540, 4, 3, [uint32(75), 80, 55, 70, 95], [uint32(3), 4, 5, 3, 3], [uint32(6), 4, 8, 5, 5]);
    defineType("Assassin", 99, "Human", 27, 3, 4, [uint32(50), 35, 65, 55, 55], [uint32(2), 1, 6, 2, 2], [uint32(4), 4, 8, 5, 4]);
    defineType("Arcane Mage", 99, "Human", 22, 3, 3, [uint32(45), 40, 45, 70, 60], [uint32(3), 2, 4, 2, 2], [uint32(4), 5, 5, 6, 5]);

  }

  // @dev Define a new hero type (class).
  function defineType(string _className, uint32 _maxLevel, string _classRace, uint32 _classAge, uint8 _classRank, uint8 _aura, uint32[5] _intitialStats, uint32[5] _minIVForStats, uint32[5] _maxIVForStats)
    onlyOwner
    public
  {
    require(_classRank < 5);
    require(_aura < 5);

    var _heroType = HeroClass({
      className: _className,
      classRace: _classRace,
      classAge: _classAge,
      classRank: _classRank,
      maxLevel: _maxLevel,
      aura: _aura,
      intitialStats: _intitialStats,
      minIVForStats: _minIVForStats,
      maxIVForStats: _maxIVForStats,
      currentNumberOfInstancedHeroes: 0
    });

    // Save the hero class.
    heroClasses[numberOfHeroClasses] = _heroType;

    // Fire event.
    DefineType(msg.sender, numberOfHeroClasses, _heroType.className);

    // Increment number of hero classes.
    numberOfHeroClasses ++;

  }

  // @dev Mint a new hero, with _heroClassId.
  function mint(address _owner, uint32 _heroClassId)
    onlyAccessMint
    public
    returns (uint256)
  {
    require(_owner != address(0));
    require(_heroClassId < numberOfHeroClasses);

    // The information of the hero's class.
    var _heroClassInfo = heroClasses[_heroClassId];

    // Mint ERC721 token.
    _mint(_owner, numberOfTokenIds);

    // Build random IVs for this hero instance.
    uint32[5] memory _ivForStats;
    for (uint8 i = 0; i < 5; i++) {
      _ivForStats[i] = (random(_heroClassInfo.maxIVForStats[i] + 1, _heroClassInfo.minIVForStats[i]));
    }

    // Temporary hero instance.
    var _heroInstance = HeroInstance({
      heroClassId: _heroClassId,
      heroName: _heroClassInfo.className,
      currentLevel: 1,
      currentExp: 0,
      lastLocationId: 0,
      availableAt: now,
      currentStats: _heroClassInfo.intitialStats,
      ivForStats: _ivForStats
    });

    // Save the hero instance.
    tokenIdToHeroInstance[numberOfTokenIds] = _heroInstance;

    // Increment number of token ids.
    // This will only increment when new token is minted, and will never be decemented when the token is burned.
    numberOfTokenIds ++;

     // Increment instanced number of heroes.
    _heroClassInfo.currentNumberOfInstancedHeroes ++;

    return numberOfTokenIds - 1;
  }

  // @dev Set where the heroes are deployed, and when they will return.
  //  This is intended to be called by Dungeon, Arena, Guild contracts.
  function deploy(uint256 _tokenId, uint32 _locationId, uint256 _duration)
    onlyAccessDeploy
    public
    returns (bool)
  {
    
    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    // The character should be avaiable. 
    require(_heroInstance.availableAt <= now);

    _heroInstance.lastLocationId = _locationId;
    _heroInstance.availableAt = now + _duration;

    // As the hero has been deployed to another place, fire event.
    Deploy(msg.sender, _tokenId, _locationId, _duration);
  }

  // @dev Add exp.
  //  This is intended to be called by Dungeon, Arena, Guild contracts.
  function addExp(uint256 _tokenId, uint32 _exp)
    onlyAccessDeploy
    public
    returns (bool)
  {
    
    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    var _newExp = _heroInstance.currentExp + _exp;

    // Sanity check to ensure we don't overflow.
    require(_newExp == uint256(uint128(_newExp)));

    _heroInstance.currentExp +=_newExp;

  }

  // @dev Add deposit.
  //  This is intended to be called by Dungeon, Arena, Guild contracts.
  function addDeposit(address _to, uint256 _amount)
    onlyAccessDeposit
    public
  {
    // Increment deposit.
    addressToGoldDeposit[_to] += _amount;
  }

  // @dev Level up the hero with _tokenId.
  //  This function is called by the owner of the hero.
  function levelUp(uint256 _tokenId)
    onlyOwnerOf(_tokenId)
    public
  {

    // Hero instance.
    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    // The character should be avaiable. (Should have already returned from the dungeons, arenas, etc.)
    require(_heroInstance.availableAt <= now);

    // The information of the hero's class.
    var _heroClassInfo = heroClasses[_heroInstance.heroClassId];

    // Hero shouldn't level up exceed its max level.
    require(_heroInstance.currentLevel < _heroClassInfo.maxLevel);

    // Required Exp.
    var requiredExp = (_heroInstance.currentLevel + 1) * requiredExpIncreasePerlevel;

    // Need to have enough exp.
    require(_heroInstance.currentExp >= requiredExp);

    // Required Gold.
    var requiredGold = (_heroInstance.currentLevel + 1) * requiredGoldIncreasePerlevel;

    // Owner of token.
    var _ownerOfToken = ownerOf(_tokenId);

    // Need to have enough Gold balance.
    require(addressToGoldDeposit[_ownerOfToken] >= requiredGold);

    // Increase stats.
    _heroInstance.currentLevel += 1;
    for (uint8 i = 0; i < 5; i++) {
      _heroInstance.currentStats[i] = _heroClassInfo.intitialStats[i] + (_heroInstance.currentLevel - 1) * _heroInstance.ivForStats[i];
    }
    
    // Deduct exp.
    _heroInstance.currentExp -= requiredExp;

    // Deduct gold.
    addressToGoldDeposit[_ownerOfToken] -= requiredGold;

    // Fire event.
    LevelUp(msg.sender, _tokenId, _heroInstance.currentLevel);
  }

  // @dev Transfer deposit (with the allowance pattern.)
  function transferDeposit(uint256 _amount)
    public
  {
    require(goldContract.allowance(msg.sender, this) >= _amount);

    // Send msg.sender's Gold to this contract.
    if (goldContract.transferFrom(msg.sender, this, _amount)) {
       // Increment deposit.
      addressToGoldDeposit[msg.sender] += _amount;
    }
  }

  // @dev Withdraw deposit.
  function withdrawDeposit(uint256 _amount)
    public
  {
    require(addressToGoldDeposit[msg.sender] >= _amount);

    // Send deposit of Golds to msg.sender. (Rather minting...)
    if (goldContract.transfer(msg.sender, _amount)) {
      // Decrement deposit.
      addressToGoldDeposit[msg.sender] -= _amount;
    }
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