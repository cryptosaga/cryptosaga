pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

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
contract CryptoSagaHero is ERC721Token, Claimable, Pausable, AccessMint, AccessDeploy, AccessDeposit {

  string public constant name = "CryptoSaga Hero";
  string public constant symbol = "HERO";
  
  struct HeroClass {
    // ex) Soldier, Knight, Fighter...
    string className;
    // 0: Common, 1: Uncommon, 2: Rare, 3: Heroic, 4: Legendary.
    uint8 classRank;
    // 0: Human, 1: Celestial, 2: Demon, 3: Elf, 4: Dark Elf, 5: Yogoe, 6: Furry, 7: Dragonborn, 8: Undead, 9: Goblin, 10: Troll, 11: Slime, and more to come.
    uint8 classRace;
    // How old is this hero class? 
    uint32 classAge;
    // 0: Fighter, 1: Rogue, 2: Mage.
    uint8 classType;

    // Possible max level of this class.
    uint32 maxLevel; 
    // 0: Water, 1: Fire, 2: Nature, 3: Light, 4: Darkness.
    uint8 aura; 

    // Base stats of this hero type. 
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] baseStats;
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
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] ivForStats;
  }

  // Required exp for level up will increase when heroes level up.
  // This defines how the value will increase.
  uint32 public requiredExpIncreaseFactor = 100;

  // Required Gold for level up will increase when heroes level up.
  // This defines how the value will increase.
  uint256 public requiredGoldIncreaseFactor = 1000000000000000000;

  // Existing hero classes.
  mapping(uint32 => HeroClass) public heroClasses;
  // The number of hero classes ever defined.
  uint32 public numberOfHeroClasses;

  // Existing hero instances.
  // The key is _tokenId.
  mapping(uint256 => HeroInstance) public tokenIdToHeroInstance;
  // The number of tokens ever minted. This works as the serial number.
  uint256 public numberOfTokenIds;

  // Gold contract.
  Gold public goldContract;

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

  // @dev Get the class's entire infomation.
  function getClassInfo(uint32 _classId)
    external view
    returns (string className, uint8 classRank, uint8 classRace, uint32 classAge, uint8 classType, uint32 maxLevel, uint8 aura, uint32[5] baseStats, uint32[5] minIVs, uint32[5] maxIVs) 
  {
    var _cl = heroClasses[_classId];
    return (_cl.className, _cl.classRank, _cl.classRace, _cl.classAge, _cl.classType, _cl.maxLevel, _cl.aura, _cl.baseStats, _cl.minIVForStats, _cl.maxIVForStats);
  }

  // @dev Get the class's name.
  function getClassName(uint32 _classId)
    external view
    returns (string)
  {
    return heroClasses[_classId].className;
  }

  // @dev Get the class's rank.
  function getClassRank(uint32 _classId)
    external view
    returns (uint8)
  {
    return heroClasses[_classId].classRank;
  }

  // @dev Get the heroes ever minted for the class.
  function getClassMintCount(uint32 _classId)
    external view
    returns (uint32)
  {
    return heroClasses[_classId].currentNumberOfInstancedHeroes;
  }

  // @dev Get the hero's entire infomation.
  function getHeroInfo(uint256 _tokenId)
    external view
    returns (uint32 classId, string heroName, uint32 currentLevel, uint32 currentExp, uint32 lastLocationId, uint256 availableAt, uint32[5] currentStats, uint32[5] ivs, uint32 bp)
  {
    HeroInstance memory _h = tokenIdToHeroInstance[_tokenId];
    var _bp = _h.currentStats[0] + _h.currentStats[1] + _h.currentStats[2] + _h.currentStats[3] + _h.currentStats[4];
    return (_h.heroClassId, _h.heroName, _h.currentLevel, _h.currentExp, _h.lastLocationId, _h.availableAt, _h.currentStats, _h.ivForStats, _bp);
  }

  // @dev Get the hero's class id.
  function getHeroClassId(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].heroClassId;
  }

  // @dev Get the hero's name.
  function getHeroName(uint256 _tokenId)
    external view
    returns (string)
  {
    return tokenIdToHeroInstance[_tokenId].heroName;
  }

  // @dev Get the hero's level.
  function getHeroLevel(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].currentLevel;
  }
  
  // @dev Get the hero's location.
  function getHeroLocation(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].lastLocationId;
  }

  // @dev Get the time when the hero become available.
  function getHeroAvailableAt(uint256 _tokenId)
    external view
    returns (uint256)
  {
    return tokenIdToHeroInstance[_tokenId].availableAt;
  }

  // @dev Get the hero's BP.
  function getHeroBP(uint256 _tokenId)
    public view
    returns (uint32)
  {
    var _tmp = tokenIdToHeroInstance[_tokenId].currentStats;
    return (_tmp[0] + _tmp[1] + _tmp[2] + _tmp[3] + _tmp[4]);
  }

  // @dev Get the hero's required gold for level up.
  function getHeroRequiredGoldForLevelUp(uint256 _tokenId)
    public view
    returns (uint256)
  {
    return (uint256(2) ** (tokenIdToHeroInstance[_tokenId].currentLevel / 10)) * requiredGoldIncreaseFactor;
  }

  // @dev Get the hero's required exp for level up.
  function getHeroRequiredExpForLevelUp(uint256 _tokenId)
    public view
    returns (uint32)
  {
    return ((tokenIdToHeroInstance[_tokenId].currentLevel + 2) * requiredExpIncreaseFactor);
  }

  // @dev Get the deposit of gold of the player.
  function getGoldDepositOfAddress(address _address)
    external view
    returns (uint256)
  {
    return addressToGoldDeposit[_address];
  }

  // @dev Get the token id of the player's #th token.
  function getTokenIdOfAddressAndIndex(address _address, uint256 _index)
    external view
    returns (uint256)
  {
    return tokensOf(_address)[_index];
  }

  // @dev Get the total BP of the player.
  function getTotalBPOfAddress(address _address)
    external view
    returns (uint32)
  {
    var _tokens = tokensOf(_address);
    uint32 _totalBP = 0;
    for (uint256 i = 0; i < _tokens.length; i ++) {
      _totalBP += getHeroBP(_tokens[i]);
    }
    return _totalBP;
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
  function setRequiredExpIncreaseFactor(uint32 _value)
    onlyOwner
    public
  {
    requiredExpIncreaseFactor = _value;
  }

  // @dev Set the required golds to level up a hero.
  function setRequiredGoldIncreaseFactor(uint256 _value)
    onlyOwner
    public
  {
    requiredGoldIncreaseFactor = _value;
  }

  // @dev Contructor.
  function CryptoSagaHero(address _goldAddress)
    public
  {
    require(_goldAddress != address(0));

    // Assign Gold contract.
    setGoldContract(_goldAddress);

    // Initial heroes.
    // Name, Rank, Race, Age, Type, Max Level, Aura, Stats.
    defineType("Archangel", 4, 1, 13540, 0, 99, 3, [uint32(74), 75, 57, 99, 95], [uint32(8), 6, 8, 5, 5], [uint32(8), 10, 10, 6, 6]);
    defineType("Shadowalker", 3, 4, 134, 1, 75, 4, [uint32(45), 35, 60, 80, 40], [uint32(3), 2, 10, 4, 5], [uint32(5), 5, 10, 7, 5]);
    defineType("Pyromancer", 2, 0, 14, 2, 50, 1, [uint32(50), 28, 17, 40, 35], [uint32(5), 3, 2, 3, 3], [uint32(8), 4, 3, 4, 5]);
    defineType("Magician", 1, 3, 224, 2, 30, 0, [uint32(35), 15, 25, 25, 30], [uint32(3), 1, 2, 2, 2], [uint32(5), 2, 3, 3, 3]);
    defineType("Farmer", 0, 0, 59, 0, 15, 2, [uint32(10), 22, 8, 15, 25], [uint32(1), 2, 1, 1, 2], [uint32(1), 3, 1, 2, 3]);
  }

  // @dev Define a new hero type (class).
  function defineType(string _className, uint8 _classRank, uint8 _classRace, uint32 _classAge, uint8 _classType, uint32 _maxLevel, uint8 _aura, uint32[5] _baseStats, uint32[5] _minIVForStats, uint32[5] _maxIVForStats)
    onlyOwner
    public
  {
    require(_classRank < 5);
    require(_classType < 3);
    require(_aura < 5);
    require(_minIVForStats[0] <= _maxIVForStats[0] && _minIVForStats[1] <= _maxIVForStats[1] && _minIVForStats[2] <= _maxIVForStats[2] && _minIVForStats[3] <= _maxIVForStats[3] && _minIVForStats[4] <= _maxIVForStats[4]);

    HeroClass memory _heroType = HeroClass({
      className: _className,
      classRank: _classRank,
      classRace: _classRace,
      classAge: _classAge,
      classType: _classType,
      maxLevel: _maxLevel,
      aura: _aura,
      baseStats: _baseStats,
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
    HeroInstance memory _heroInstance = HeroInstance({
      heroClassId: _heroClassId,
      heroName: "",
      currentLevel: 1,
      currentExp: 0,
      lastLocationId: 0,
      availableAt: now,
      currentStats: _heroClassInfo.baseStats,
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
    // The hero should be possessed by anybody.
    require(ownerOf(_tokenId) != address(0));

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
    // The hero should be possessed by anybody.
    require(ownerOf(_tokenId) != address(0));

    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    var _newExp = _heroInstance.currentExp + _exp;

    // Sanity check to ensure we don't overflow.
    require(_newExp == uint256(uint128(_newExp)));

    _heroInstance.currentExp += _newExp;

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
    onlyOwnerOf(_tokenId) whenNotPaused
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
    var requiredExp = getHeroRequiredExpForLevelUp(_tokenId);

    // Need to have enough exp.
    require(_heroInstance.currentExp >= requiredExp);

    // Required Gold.
    var requiredGold = getHeroRequiredGoldForLevelUp(_tokenId);

    // Owner of token.
    var _ownerOfToken = ownerOf(_tokenId);

    // Need to have enough Gold balance.
    require(addressToGoldDeposit[_ownerOfToken] >= requiredGold);

    // Increase Level.
    _heroInstance.currentLevel += 1;

    // Increase Stats.
    for (uint8 i = 0; i < 5; i++) {
      _heroInstance.currentStats[i] = _heroClassInfo.baseStats[i] + (_heroInstance.currentLevel - 1) * _heroInstance.ivForStats[i];
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
    whenNotPaused
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