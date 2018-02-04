pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Claimable.sol";
import "./AccessMint.sol";

/**
 * @title Gold
 * @dev ERC20 Token that can be minted.
 */
contract Gold is StandardToken, Claimable, AccessMint {

  string public constant name = "Gold";
  string public constant symbol = "G";
  uint8 public constant decimals = 18;

  // Event that is fired when minted.
  event Mint(
    address indexed _to,
    uint256 indexed _tokenId
  );

  // @dev Mint tokens with _amount to the address.
  function mint(address _to, uint256 _amount) 
    onlyAccessMint
    public 
    returns (bool) 
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

}