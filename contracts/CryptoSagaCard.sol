pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";
import "./AccessMint.sol";
import "./CryptoSagaCardSwap.sol";

/**
 * @title CryptoSaga Card
 * @dev ERC721 Token that repesents CryptoSaga's cards.
 *  Buy consuming a card, players of CryptoSaga can get a heroe.
 */
contract CryptoSagaCard is ERC721Token, Claimable, AccessMint {

  string public constant name = "CryptoSaga Card";
  string public constant symbol = "CARD";

  // Rank of the token.
  mapping(uint256 => uint8) public tokenIdToRank;

  // The number of tokens ever minted.
  uint256 public numberOfTokenId;

  // The converter contract.
  CryptoSagaCardSwap private swapContract;

  // Event that should be fired when card is converted.
  event CardSwap(address indexed _by, uint256 _tokenId, uint256 _rewardId);

  // @dev Set the address of the contract that represents CryptoSaga Cards.
  function setCryptoSagaCardSwapContract(address _contractAddress)
    public
    onlyOwner
  {
    swapContract = CryptoSagaCardSwap(_contractAddress);
  }

  function rankOf(uint256 _tokenId) 
    public view
    returns (uint8)
  {
    return tokenIdToRank[_tokenId];
  }

  // @dev Mint a new card.
  function mint(address _beneficiary, uint256 _amount, uint8 _rank)
    onlyAccessMint
    public
  {
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_beneficiary, numberOfTokenId);
      tokenIdToRank[numberOfTokenId] = _rank;
      numberOfTokenId ++;
    }
  }

  // @dev Swap this card for reward.
  //  The card will be burnt.
  function swap(uint256 _tokenId)
    onlyOwnerOf(_tokenId)
    public
    returns (uint256)
  {
    require(address(swapContract) != address(0));

    var _rank = tokenIdToRank[_tokenId];
    var _rewardId = swapContract.swapCardForReward(this, _rank);
    CardSwap(ownerOf(_tokenId), _tokenId, _rewardId);
    _burn(_tokenId);
    return _rewardId;
  }

}