pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

import "./CryptoSagaArenaRecord.sol";
import "./CryptoSagaCard.sol";
import "./CryptoSagaCorrectedHeroStats.sol";

/**
 * @title CryptoSagaArenaVer1
 * @dev The actual gameplay is done by this contract. Version 1.0.1.
 */
contract CryptoSagaArenaVer1 is Claimable, Pausable {

  struct PlayRecord {
    // This is needed for reconstructing the record.
    uint32 initialSeed;
    // The address of the enemy player.
    address enemyAddress;
    // Hero's token ids.
    uint256[4] tokenIds;
    // Unit's class ids. 0 ~ 3: Heroes. 4 ~ 7: Mobs.
    uint32[8] unitClassIds;
    // Unit's levels. 0 ~ 3: Heroes. 4 ~ 7: Mobs.
    uint32[8] unitLevels;
    // Exp reward given.
    uint32 expReward;
    // Gold Reward given.
    uint256 goldReward;
  }

  // This information can be reconstructed with seed and dateTime.
  // For the optimization this won't be really used.
  struct TurnInfo {
    // Number of turns before a team was vanquished.
    uint8 turnLength;
    // Turn order of units.
    uint8[8] turnOrder;
    // Defender list. (The unit that is attacked.)
    uint8[24] defenderList;
    // Damage list. (The damage given to the defender.)
    uint32[24] damageList;
    // Heroes' original Exps.
    uint32[4] originalExps;
  }

  // Progress contract.
  CryptoSagaArenaRecord private recordContract;

  // The hero contract.
  CryptoSagaHero private heroContract;

  // Corrected hero stats contract.
  CryptoSagaCorrectedHeroStats private correctedHeroContract;

  // Gold contract.
  Gold public goldContract;

  // Card contract.
  CryptoSagaCard public cardContract;

  // The location Id of this contract.
  // Will be used when calling deploy function of hero contract.
  uint32 public locationId = 100;

  // Hero cooldown time. (Default value: 60 mins.)
  uint256 public coolHero = 3600;

  // The exp reward for fighting in this arena.
  uint32 public expReward = 100;

  // The Gold reward when fighting in this arena.
  uint256 public goldReward = 1000000000000000000;

  // Should this contract save the turn data?
  bool public isTurnDataSaved = true;

  // Last game's record of the player.
  mapping(address => PlayRecord) public addressToPlayRecord;

  // Additional information on last game's record of the player.
  mapping(address => TurnInfo) public addressToTurnInfo;

  // Random seed.
  uint32 private seed = 0;

  // Event that is fired when a player fights in this arena.
  event TryArena(
    address indexed _by,
    address indexed _against,
    bool _didWin
  );

  // @dev Get previous game record.
  function getPlayRecord(address _address)
    external view
    returns (uint32, address, uint256[4], uint32[8], uint32[8], uint32, uint256, uint8, uint8[8], uint8[24], uint32[24])
  {
    PlayRecord memory _p = addressToPlayRecord[_address];
    TurnInfo memory _t = addressToTurnInfo[_address];
    return (
      _p.initialSeed,
      _p.enemyAddress,
      _p.tokenIds,
      _p.unitClassIds,
      _p.unitLevels,
      _p.expReward,
      _p.goldReward,
      _t.turnLength,
      _t.turnOrder,
      _t.defenderList,
      _t.damageList
    );
  }

  // @dev Get previous game record.
  function getPlayRecordNoTurnData(address _address)
    external view
    returns (uint32, address, uint256[4], uint32[8], uint32[8], uint32, uint256)
  {
    PlayRecord memory _p = addressToPlayRecord[_address];
    return (
      _p.initialSeed,
      _p.enemyAddress,
      _p.tokenIds,
      _p.unitClassIds,
      _p.unitLevels,
      _p.expReward,
      _p.goldReward
      );
  }

  // @dev Set location id.
  function setLocationId(uint32 _value)
    onlyOwner
    public
  {
    locationId = _value;
  }

  // @dev Set cooldown of heroes entered this arena.
  function setCoolHero(uint32 _value)
    onlyOwner
    public
  {
    coolHero = _value;
  }

  // @dev Set the Exp given to the player for fighting in this arena.
  function setExpReward(uint32 _value)
    onlyOwner
    public
  {
    expReward = _value;
  }

  // @dev Set the Golds given to the player for fighting in this arena.
  function setGoldReward(uint256 _value)
    onlyOwner
    public
  {
    goldReward = _value;
  }

  // @dev Set wether the turn data saved or not.
  function setIsTurnDataSaved(bool _value)
    onlyOwner
    public
  {
    isTurnDataSaved = _value;
  }

  // @dev Set Record Contract.
  function setRecordContract(address _address)
    onlyOwner
    public
  {
    recordContract = CryptoSagaArenaRecord(_address);
  }

  // @dev Constructor.
  function CryptoSagaArenaVer1(
    address _recordContractAddress,
    address _heroContractAddress,
    address _correctedHeroContractAddress,
    address _cardContractAddress,
    address _goldContractAddress,
    address _firstPlayerAddress,
    uint32 _locationId,
    uint256 _coolHero,
    uint32 _expReward,
    uint256 _goldReward,
    bool _isTurnDataSaved)
    public
  {
    recordContract = CryptoSagaArenaRecord(_recordContractAddress);
    heroContract = CryptoSagaHero(_heroContractAddress);
    correctedHeroContract = CryptoSagaCorrectedHeroStats(_correctedHeroContractAddress);
    cardContract = CryptoSagaCard(_cardContractAddress);
    goldContract = Gold(_goldContractAddress);

    // Save first player's record.
    // This is for preventing errors.
    PlayRecord memory _playRecord;
    _playRecord.initialSeed = seed;
    _playRecord.enemyAddress = _firstPlayerAddress;
    _playRecord.tokenIds[0] = 1;
    _playRecord.tokenIds[1] = 2;
    _playRecord.tokenIds[2] = 3;
    _playRecord.tokenIds[3] = 4;
    addressToPlayRecord[_firstPlayerAddress] = _playRecord;
    
    locationId = _locationId;
    coolHero = _coolHero;
    expReward = _expReward;
    goldReward = _goldReward;
    
    isTurnDataSaved = _isTurnDataSaved;
  }
  
  // @dev Enter this arena.
  function enterArena(uint256[4] _tokenIds, address _enemyAddress)
    whenNotPaused
    public
  {

    // Shouldn't fight against self.
    require(msg.sender != _enemyAddress);

    // Each hero should be with different ids.
    require(_tokenIds[0] == 0 || (_tokenIds[0] != _tokenIds[1] && _tokenIds[0] != _tokenIds[2] && _tokenIds[0] != _tokenIds[3]));
    require(_tokenIds[1] == 0 || (_tokenIds[1] != _tokenIds[0] && _tokenIds[1] != _tokenIds[2] && _tokenIds[1] != _tokenIds[3]));
    require(_tokenIds[2] == 0 || (_tokenIds[2] != _tokenIds[0] && _tokenIds[2] != _tokenIds[1] && _tokenIds[2] != _tokenIds[3]));
    require(_tokenIds[3] == 0 || (_tokenIds[3] != _tokenIds[0] && _tokenIds[3] != _tokenIds[1] && _tokenIds[3] != _tokenIds[2]));

    // Check ownership and availability of the heroes.
    require(checkOwnershipAndAvailability(msg.sender, _tokenIds));

    // The play record of the enemy should exist.
    // The check is done with the enemy's enemy address, because the default value of it will be address(0).
    require(addressToPlayRecord[_enemyAddress].enemyAddress != address(0));

    // Set seed.
    seed += uint32(now);

    // Define play record here.
    PlayRecord memory _playRecord;
    _playRecord.initialSeed = seed;
    _playRecord.enemyAddress = _enemyAddress;
    _playRecord.tokenIds[0] = _tokenIds[0];
    _playRecord.tokenIds[1] = _tokenIds[1];
    _playRecord.tokenIds[2] = _tokenIds[2];
    _playRecord.tokenIds[3] = _tokenIds[3];

    // The information that can give additional information.
    TurnInfo memory _turnInfo;

    // Step 1: Retrieve Hero information (0 ~ 3) & Enemy information (4 ~ 7).

    uint32[5][8] memory _unitStats; // Stats of units for given levels and class ids.
    uint8[2][8] memory _unitTypesAuras; // 0: Types of units for given levels and class ids. 1: Auras of units for given levels and class ids.

    // Retrieve deployed hero information.
    if (_tokenIds[0] != 0) {
      _playRecord.unitClassIds[0] = heroContract.getHeroClassId(_tokenIds[0]);
      (_playRecord.unitLevels[0], _turnInfo.originalExps[0], _unitStats[0], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[0]);
      (, , , , _unitTypesAuras[0][0], , _unitTypesAuras[0][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[0]);
    }
    if (_tokenIds[1] != 0) {
      _playRecord.unitClassIds[1] = heroContract.getHeroClassId(_tokenIds[1]);
      (_playRecord.unitLevels[1], _turnInfo.originalExps[1], _unitStats[1], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[1]);
      (, , , , _unitTypesAuras[1][0], , _unitTypesAuras[1][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[1]);
    }
    if (_tokenIds[2] != 0) {
      _playRecord.unitClassIds[2] = heroContract.getHeroClassId(_tokenIds[2]);
      (_playRecord.unitLevels[2], _turnInfo.originalExps[2], _unitStats[2], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[2]);
      (, , , , _unitTypesAuras[2][0], , _unitTypesAuras[2][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[2]);
    }
    if (_tokenIds[3] != 0) {
      _playRecord.unitClassIds[3] = heroContract.getHeroClassId(_tokenIds[3]);
      (_playRecord.unitLevels[3], _turnInfo.originalExps[3], _unitStats[3], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[3]);
      (, , , , _unitTypesAuras[3][0], , _unitTypesAuras[3][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[3]);
    }

    // Retrieve enemy information.
    PlayRecord memory _enemyPlayRecord = addressToPlayRecord[_enemyAddress];
    if (_enemyPlayRecord.tokenIds[0] != 0) {
      _playRecord.unitClassIds[4] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[0]);
      (_playRecord.unitLevels[4], , _unitStats[4], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[0]);
      (, , , , _unitTypesAuras[4][0], , _unitTypesAuras[4][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[4]);
    }
    if (_enemyPlayRecord.tokenIds[1] != 0) {
      _playRecord.unitClassIds[5] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[1]);
      (_playRecord.unitLevels[5], , _unitStats[5], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[1]);
      (, , , , _unitTypesAuras[5][0], , _unitTypesAuras[5][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[5]);
    }
    if (_enemyPlayRecord.tokenIds[2] != 0) {
      _playRecord.unitClassIds[6] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[2]);
      (_playRecord.unitLevels[6], , _unitStats[6], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[2]);
      (, , , , _unitTypesAuras[6][0], , _unitTypesAuras[6][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[6]);
    }
    if (_enemyPlayRecord.tokenIds[3] != 0) {
      _playRecord.unitClassIds[7] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[3]);
      (_playRecord.unitLevels[7], , _unitStats[7], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[3]);
      (, , , , _unitTypesAuras[7][0], , _unitTypesAuras[7][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[7]);
    }

    // Step 2. Run the battle logic.
    
    // Firstly, we need to assign the unit's turn order with AGLs of the units.
    uint32[8] memory _unitAGLs;
    for (uint8 i = 0; i < 8; i ++) {
      _unitAGLs[i] = _unitStats[i][2];
    }
    _turnInfo.turnOrder = getOrder(_unitAGLs);
    
    // Fight for 24 turns. (8 units x 3 rounds.)
    _turnInfo.turnLength = 24;
    for (i = 0; i < 24; i ++) {
      if (_unitStats[4][4] == 0 && _unitStats[5][4] == 0 && _unitStats[6][4] == 0 && _unitStats[7][4] == 0) {
        _turnInfo.turnLength = i;
        break;
      } else if (_unitStats[0][4] == 0 && _unitStats[1][4] == 0 && _unitStats[2][4] == 0 && _unitStats[3][4] == 0) {
        _turnInfo.turnLength = i;
        break;
      }
      
      var _slotId = _turnInfo.turnOrder[(i % 8)];
      if (_slotId < 4 && _tokenIds[_slotId] == 0) {
        // This means the slot is empty.
        // Defender should be default value.
        _turnInfo.defenderList[i] = 127;
      } else if (_unitStats[_slotId][4] == 0) {
        // This means the unit on this slot is dead.
        // Defender should be default value.
        _turnInfo.defenderList[i] = 128;
      } else {
        // 1) Check number of attack targets that are alive.
        uint8 _targetSlotId = 255;
        if (_slotId < 4) {
          if (_unitStats[4][4] > 0)
            _targetSlotId = 4;
          else if (_unitStats[5][4] > 0)
            _targetSlotId = 5;
          else if (_unitStats[6][4] > 0)
            _targetSlotId = 6;
          else if (_unitStats[7][4] > 0)
            _targetSlotId = 7;
        } else {
          if (_unitStats[0][4] > 0)
            _targetSlotId = 0;
          else if (_unitStats[1][4] > 0)
            _targetSlotId = 1;
          else if (_unitStats[2][4] > 0)
            _targetSlotId = 2;
          else if (_unitStats[3][4] > 0)
            _targetSlotId = 3;
        }
        
        // Target is the defender.
        _turnInfo.defenderList[i] = _targetSlotId;
        
        // Base damage. (Attacker's ATK * 1.5 - Defender's DEF).
        uint32 _damage = 10;
        if ((_unitStats[_slotId][0] * 150 / 100) > _unitStats[_targetSlotId][1])
          _damage = max((_unitStats[_slotId][0] * 150 / 100) - _unitStats[_targetSlotId][1], 10);
        else
          _damage = 10;

        // Check miss / success.
        if ((_unitStats[_slotId][3] * 150 / 100) > _unitStats[_targetSlotId][2]) {
          if (min(max(((_unitStats[_slotId][3] * 150 / 100) - _unitStats[_targetSlotId][2]), 75), 99) <= random(100, 0))
            _damage = _damage * 0;
        }
        else {
          if (75 <= random(100, 0))
            _damage = _damage * 0;
        }

        // Is the attack critical?
        if (_unitStats[_slotId][3] > _unitStats[_targetSlotId][3]) {
          if (min(max((_unitStats[_slotId][3] - _unitStats[_targetSlotId][3]), 5), 75) > random(100, 0))
            _damage = _damage * 150 / 100;
        }
        else {
          if (5 > random(100, 0))
            _damage = _damage * 150 / 100;
        }

        // Is attacker has the advantageous Type?
        if (_unitTypesAuras[_slotId][0] == 0 && _unitTypesAuras[_targetSlotId][0] == 1) // Fighter > Rogue
          _damage = _damage * 125 / 100;
        else if (_unitTypesAuras[_slotId][0] == 1 && _unitTypesAuras[_targetSlotId][0] == 2) // Rogue > Mage
          _damage = _damage * 125 / 100;
        else if (_unitTypesAuras[_slotId][0] == 2 && _unitTypesAuras[_targetSlotId][0] == 0) // Mage > Fighter
          _damage = _damage * 125 / 100;

        // Is attacker has the advantageous Aura?
        if (_unitTypesAuras[_slotId][1] == 0 && _unitTypesAuras[_targetSlotId][1] == 1) // Water > Fire
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 1 && _unitTypesAuras[_targetSlotId][1] == 2) // Fire > Nature
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 2 && _unitTypesAuras[_targetSlotId][1] == 0) // Nature > Water
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 3 && _unitTypesAuras[_targetSlotId][1] == 4) // Light > Darkness
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 4 && _unitTypesAuras[_targetSlotId][1] == 3) // Darkness > Light
          _damage = _damage * 150 / 100;
        
        // Apply damage so that reduce hp of defender.
        if(_unitStats[_targetSlotId][4] > _damage)
          _unitStats[_targetSlotId][4] -= _damage;
        else
          _unitStats[_targetSlotId][4] = 0;

        // Save damage to play record.
        _turnInfo.damageList[i] = _damage;
      }
    }
    
    // Step 3. Apply the result of this battle.

    // Set heroes deployed.
    if (_tokenIds[0] != 0)
      heroContract.deploy(_tokenIds[0], locationId, coolHero);
    if (_tokenIds[1] != 0)
      heroContract.deploy(_tokenIds[1], locationId, coolHero);
    if (_tokenIds[2] != 0)
      heroContract.deploy(_tokenIds[2], locationId, coolHero);
    if (_tokenIds[3] != 0)
      heroContract.deploy(_tokenIds[3], locationId, coolHero);

    uint8 _deadHeroes = 0;
    uint8 _deadEnemies = 0;

    // Check result.
    if (_unitStats[0][4] == 0)
      _deadHeroes ++;
    if (_unitStats[1][4] == 0)
      _deadHeroes ++;
    if (_unitStats[2][4] == 0)
      _deadHeroes ++;
    if (_unitStats[3][4] == 0)
      _deadHeroes ++;
    if (_unitStats[4][4] == 0)
      _deadEnemies ++;
    if (_unitStats[5][4] == 0)
      _deadEnemies ++;
    if (_unitStats[6][4] == 0)
      _deadEnemies ++;
    if (_unitStats[7][4] == 0)
      _deadEnemies ++;
      
    if (_deadEnemies > _deadHeroes) { // Win
      // Fire TryArena event.
      TryArena(msg.sender, _enemyAddress, true);
      
      // Give reward.
      (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, true, _turnInfo.originalExps);

      // Save the record.
      recordContract.updateRecord(msg.sender, _enemyAddress, true);
    }
    else if (_deadEnemies < _deadHeroes) { // Lose
      // Fire TryArena event.
      TryArena(msg.sender, _enemyAddress, false);

      // Rewards.
      (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, false, _turnInfo.originalExps);

      // Save the record.
      recordContract.updateRecord(msg.sender, _enemyAddress, false);
    }
    else { // Draw
      // Fire TryArena event.
      TryArena(msg.sender, _enemyAddress, false);

      // Rewards.
      (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, false, _turnInfo.originalExps);
    }

    // Save the result of this gameplay.
    addressToPlayRecord[msg.sender] = _playRecord;

    // Save the turn data.
    // This is commented as this information can be reconstructed with intitial seed and date time.
    // By commenting this, we can reduce about 400k gas.
    if (isTurnDataSaved) {
      addressToTurnInfo[msg.sender] = _turnInfo;
    }
  }

  // @dev Check ownership.
  function checkOwnershipAndAvailability(address _playerAddress, uint256[4] _tokenIds)
    private view
    returns(bool)
  {
    if ((_tokenIds[0] == 0 || heroContract.ownerOf(_tokenIds[0]) == _playerAddress) && (_tokenIds[1] == 0 || heroContract.ownerOf(_tokenIds[1]) == _playerAddress) && (_tokenIds[2] == 0 || heroContract.ownerOf(_tokenIds[2]) == _playerAddress) && (_tokenIds[3] == 0 || heroContract.ownerOf(_tokenIds[3]) == _playerAddress)) {
      
      // Retrieve avail time of heroes.
      uint256[4] memory _heroAvailAts;
      if (_tokenIds[0] != 0)
        ( , , , , , _heroAvailAts[0], , , ) = heroContract.getHeroInfo(_tokenIds[0]);
      if (_tokenIds[1] != 0)
        ( , , , , , _heroAvailAts[1], , , ) = heroContract.getHeroInfo(_tokenIds[1]);
      if (_tokenIds[2] != 0)
        ( , , , , , _heroAvailAts[2], , , ) = heroContract.getHeroInfo(_tokenIds[2]);
      if (_tokenIds[3] != 0)
        ( , , , , , _heroAvailAts[3], , , ) = heroContract.getHeroInfo(_tokenIds[3]);

      if (_heroAvailAts[0] <= now && _heroAvailAts[1] <= now && _heroAvailAts[2] <= now && _heroAvailAts[3] <= now) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  // @dev Give rewards.
  function giveReward(uint256[4] _heroes, bool _didWin, uint32[4] _originalExps)
    private
    returns (uint32 expRewardGiven, uint256 goldRewardGiven)
  {
    if (!_didWin) {
      // In case lost.
      // Give baseline gold reward.
      goldRewardGiven = goldReward / 10;
      expRewardGiven = expReward / 5;
    } else {
      // In case win.
      goldRewardGiven = goldReward;
      expRewardGiven = expReward;
    }

    // Give reward Gold.
    goldContract.mint(msg.sender, goldRewardGiven);
    
    // Give reward EXP.
    if(_heroes[0] != 0)
      heroContract.addExp(_heroes[0], uint32(2)**32 - _originalExps[0] + expRewardGiven);
    if(_heroes[1] != 0)
      heroContract.addExp(_heroes[1], uint32(2)**32 - _originalExps[1] + expRewardGiven);
    if(_heroes[2] != 0)
      heroContract.addExp(_heroes[2], uint32(2)**32 - _originalExps[2] + expRewardGiven);
    if(_heroes[3] != 0)
      heroContract.addExp(_heroes[3], uint32(2)**32 - _originalExps[3] + expRewardGiven);
  }

  // @dev Return a pseudo random number between lower and upper bounds
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);

    seed = seed % uint32(1103515245) + 12345;
    return seed % (_upper - _lower) + _lower;
  }

  // @dev Retreive order based on given array _by.
  function getOrder(uint32[8] _by)
    private pure
    returns (uint8[8])
  {
    uint8[8] memory _order = [uint8(0), 1, 2, 3, 4, 5, 6, 7];
    for (uint8 i = 0; i < 8; i ++) {
      for (uint8 j = i + 1; j < 8; j++) {
        if (_by[i] < _by[j]) {
          uint32 tmp1 = _by[i];
          _by[i] = _by[j];
          _by[j] = tmp1;
          uint8 tmp2 = _order[i];
          _order[i] = _order[j];
          _order[j] = tmp2;
        }
      }
    }
    return _order;
  }

  // @return Bigger value of two uint32s.
  function max(uint32 _value1, uint32 _value2)
    private pure
    returns (uint32)
  {
    if(_value1 >= _value2)
      return _value1;
    else
      return _value2;
  }

  // @return Bigger value of two uint32s.
  function min(uint32 _value1, uint32 _value2)
    private pure
    returns (uint32)
  {
    if(_value2 >= _value1)
      return _value1;
    else
      return _value2;
  }

  // @return Square root of the given value.
  function sqrt(uint32 _value) 
    private pure
    returns (uint32) 
  {
    uint32 z = (_value + 1) / 2;
    uint32 y = _value;
    while (z < y) {
      y = z;
      z = (_value / z + z) / 2;
    }
    return y;
  }

}