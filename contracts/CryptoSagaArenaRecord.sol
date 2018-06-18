pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

import "./AccessDeploy.sol";

/**
 * @title CryptoSagaArenaRecord
 * @dev The record of battles in the Arena.
 */
contract CryptoSagaArenaRecord is Pausable, AccessDeploy {

  // Number of players for the leaderboard.
  uint8 public numberOfLeaderboardPlayers = 25;

  // Top players in the leaderboard.
  address[] public leaderBoardPlayers;

  // For checking whether the player is in the leaderboard.
  mapping(address => bool) public addressToIsInLeaderboard;

  // Number of recent player recorded for matchmaking.
  uint8 public numberOfRecentPlayers = 50;

  // List of recent players.
  address[] public recentPlayers;

  // Front of recent players.
  uint256 public recentPlayersFront;

  // Back of recent players.
  uint256 public recentPlayersBack;

  // Record of each player.
  mapping(address => uint32) public addressToElo;

  // Event that is fired when a new change has been made to the leaderboard.
  event UpdateLeaderboard(
    address indexed _by,
    uint256 _dateTime
  );

  // @dev Get elo rating of a player.
  function getEloRating(address _address)
    external view
    returns (uint32)
  {
    if (addressToElo[_address] != 0)
      return addressToElo[_address];
    else
      return 1500;
  }

  // @dev Get players in the leaderboard.
  function getLeaderboardPlayers()
    external view
    returns (address[])
  {
    return leaderBoardPlayers;
  }

  // @dev Get current length of the leaderboard.
  function getLeaderboardLength()
    external view
    returns (uint256)
  {
    return leaderBoardPlayers.length;
  }

  // @dev Get recently played players.
  function getRecentPlayers()
    external view
    returns (address[])
  {
    return recentPlayers;
  }

  // @dev Get current number of players in the recently played players queue.
  function getRecentPlayersCount()
    public view
    returns (uint256) 
  {
    return recentPlayersBack - recentPlayersFront;
  }

  // @dev Constructor.
  function CryptoSagaArenaRecord(
    address _firstPlayerAddress,
    address _previousSeasonRecord,
    uint8 _numberOfLeaderboardPlayers, 
    uint8 _numberOfRecentPlayers)
    public
  {

    numberOfLeaderboardPlayers = _numberOfLeaderboardPlayers;
    numberOfRecentPlayers = _numberOfRecentPlayers;

    // The initial player gets into leaderboard.
    leaderBoardPlayers.push(_firstPlayerAddress);
    addressToIsInLeaderboard[_firstPlayerAddress] = true;

    // The initial player pushed into the recent players queue. 
    pushPlayer(_firstPlayerAddress);
    
    // The initial player's Elo.
    addressToElo[_firstPlayerAddress] = 1500;

    // Get instance of previous season.
    CryptoSagaArenaRecord _previous = CryptoSagaArenaRecord(_previousSeasonRecord);

    for (uint256 i = _previous.recentPlayersFront(); i < _previous.recentPlayersBack(); i++) {
      var _player = _previous.recentPlayers(i);
      // The initial player's Elo.
      addressToElo[_player] = _previous.getEloRating(_player);
    }
  }

  // @dev Update record.
  function updateRecord(address _myAddress, address _enemyAddress, bool _didWin)
    whenNotPaused onlyAccessDeploy
    public
  {
    address _winnerAddress = _didWin? _myAddress: _enemyAddress;
    address _loserAddress = _didWin? _enemyAddress: _myAddress;
    
    // Initial value of Elo.
    uint32 _winnerElo = addressToElo[_winnerAddress];
    if (_winnerElo == 0)
      _winnerElo = 1500;
    uint32 _loserElo = addressToElo[_loserAddress];
    if (_loserElo == 0)
      _loserElo = 1500;

    // Adjust Elo.
    if (_winnerElo >= _loserElo) {
      if (_winnerElo - _loserElo < 50) {
        addressToElo[_winnerAddress] = _winnerElo + 5;
        addressToElo[_loserAddress] = _loserElo - 5;
      } else if (_winnerElo - _loserElo < 80) {
        addressToElo[_winnerAddress] = _winnerElo + 4;
        addressToElo[_loserAddress] = _loserElo - 4;
      } else if (_winnerElo - _loserElo < 150) {
        addressToElo[_winnerAddress] = _winnerElo + 3;
        addressToElo[_loserAddress] = _loserElo - 3;
      } else if (_winnerElo - _loserElo < 250) {
        addressToElo[_winnerAddress] = _winnerElo + 2;
        addressToElo[_loserAddress] = _loserElo - 2;
      } else {
        addressToElo[_winnerAddress] = _winnerElo + 1;
        addressToElo[_loserAddress] = _loserElo - 1;
      }
    } else {
      if (_loserElo - _winnerElo < 50) {
        addressToElo[_winnerAddress] = _winnerElo + 5;
        addressToElo[_loserAddress] = _loserElo - 5;
      } else if (_loserElo - _winnerElo < 80) {
        addressToElo[_winnerAddress] = _winnerElo + 6;
        addressToElo[_loserAddress] = _loserElo - 6;
      } else if (_loserElo - _winnerElo < 150) {
        addressToElo[_winnerAddress] = _winnerElo + 7;
        addressToElo[_loserAddress] = _loserElo - 7;
      } else if (_loserElo - _winnerElo < 250) {
        addressToElo[_winnerAddress] = _winnerElo + 8;
        addressToElo[_loserAddress] = _loserElo - 8;
      } else {
        addressToElo[_winnerAddress] = _winnerElo + 9;
        addressToElo[_loserAddress] = _loserElo - 9;
      }
    }

    // Update recent players list.
    if (!isPlayerInQueue(_myAddress)) {
      
      // If the queue is full, pop a player.
      if (getRecentPlayersCount() >= numberOfRecentPlayers)
        popPlayer();
      
      // Push _myAddress to the queue.
      pushPlayer(_myAddress);
    }

    // Update leaderboards.
    if(updateLeaderboard(_enemyAddress) || updateLeaderboard(_myAddress))
    {
      UpdateLeaderboard(_myAddress, now);
    }

  }

  // @dev Update leaderboard.
  function updateLeaderboard(address _addressToUpdate)
    whenNotPaused
    private
    returns (bool isChanged)
  {

    // If this players is already in the leaderboard, there's no need for replace the minimum recorded player.
    if (addressToIsInLeaderboard[_addressToUpdate]) {
      // Do nothing.
    } else {
      if (leaderBoardPlayers.length >= numberOfLeaderboardPlayers) {
        
        // Need to replace existing player.
        // First, we need to find the player with miminum Elo value.
        uint32 _minimumElo = 99999;
        uint8 _minimumEloPlayerIndex = numberOfLeaderboardPlayers;
        for (uint8 i = 0; i < leaderBoardPlayers.length; i ++) {
          if (_minimumElo > addressToElo[leaderBoardPlayers[i]]) {
            _minimumElo = addressToElo[leaderBoardPlayers[i]];
            _minimumEloPlayerIndex = i;
          }
        }

        // Second, if the minimum elo value is smaller than the player's elo value, then replace the entity.
        if (_minimumElo <= addressToElo[_addressToUpdate]) {
          addressToIsInLeaderboard[leaderBoardPlayers[_minimumEloPlayerIndex]] = false;
          leaderBoardPlayers[_minimumEloPlayerIndex] = _addressToUpdate;
          addressToIsInLeaderboard[_addressToUpdate] = true;
          isChanged = true;
        }
      } else {
        // The list is not full yet. 
        // Just add the player to the list.
        leaderBoardPlayers.push(_addressToUpdate);
        addressToIsInLeaderboard[_addressToUpdate] = true;
        isChanged = true;
      }
    }
  }

  // #dev Check whether contain the element or not.
  function isPlayerInQueue(address _player)
    view private
    returns (bool isContain)
  {
    isContain = false;
    for (uint256 i = recentPlayersFront; i < recentPlayersBack; i++) {
      if (_player == recentPlayers[i]) {
        isContain = true;
      }
    }
  }
    
  // @dev Push a new player into the queue.
  function pushPlayer(address _player)
    private
  {
    recentPlayers.push(_player);
    recentPlayersBack++;
  }
    
  // @dev Pop the oldest player in this queue.
  function popPlayer() 
    private
    returns (address player)
  {
    if (recentPlayersBack == recentPlayersFront)
      return address(0);
    player = recentPlayers[recentPlayersFront];
    delete recentPlayers[recentPlayersFront];
    recentPlayersFront++;
  }

}