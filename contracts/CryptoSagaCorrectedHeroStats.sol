pragma solidity ^0.4.18;

import "./CryptoSagaHero.sol";

/**
 * @title CryptoSagaCorrectedHeroStats
 * @dev Corrected hero stats is needed to fix the bug in hero stats.
 */
contract CryptoSagaCorrectedHeroStats {

  // The hero contract.
  CryptoSagaHero private heroContract;

  // @dev Constructor.
  function CryptoSagaCorrectedHeroStats(address _heroContractAddress)
    public
  {
    heroContract = CryptoSagaHero(_heroContractAddress);
  }

  // @dev Get the hero's stats and some other infomation.
  function getCorrectedStats(uint256 _tokenId)
    external view
    returns (uint32 currentLevel, uint32 currentExp, uint32[5] currentStats, uint32[5] ivs, uint32 bp)
  {
    var (, , _currentLevel, _currentExp, , , _currentStats, _ivs, ) = heroContract.getHeroInfo(_tokenId);
    
    if (_currentLevel != 1) {
      for (uint8 i = 0; i < 5; i ++) {
        _currentStats[i] += _ivs[i];
      }
    }

    var _bp = _currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4];
    return (_currentLevel, _currentExp, _currentStats, _ivs, _bp);
  }

  // @dev Get corrected total BP of the address.
  function getCorrectedTotalBPOfAddress(address _address)
    external view
    returns (uint32)
  {
    var _balance = heroContract.balanceOf(_address);

    uint32 _totalBP = 0;

    for (uint256 i = 0; i < _balance; i ++) {
      var (, , _currentLevel, , , , _currentStats, _ivs, ) = heroContract.getHeroInfo(heroContract.getTokenIdOfAddressAndIndex(_address, i));
      if (_currentLevel != 1) {
        for (uint8 j = 0; j < 5; j ++) {
          _currentStats[j] += _ivs[j];
        }
      }
      _totalBP += (_currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4]);
    }

    return _totalBP;
  }

  // @dev Get corrected total BP of the address.
  function getCorrectedTotalBPOfTokens(uint256[] _tokens)
    external view
    returns (uint32)
  {
    uint32 _totalBP = 0;

    for (uint256 i = 0; i < _tokens.length; i ++) {
      var (, , _currentLevel, , , , _currentStats, _ivs, ) = heroContract.getHeroInfo(_tokens[i]);
      if (_currentLevel != 1) {
        for (uint8 j = 0; j < 5; j ++) {
          _currentStats[j] += _ivs[j];
        }
      }
      _totalBP += (_currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4]);
    }

    return _totalBP;
  }
}