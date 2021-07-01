// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import '../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './MTGYSpend.sol';

/**
 * @title MTGYAirdropper
 * @dev Allows sending an ERC20 token to multiple addresses in different amounts
 */
contract MTGYAirdropper {
  ERC20 private _mtgy;
  MTGYSpend private _mtgySpend;

  address public creator;
  address public mtgyTokenAddy;
  address public mtgySpendAddy;
  uint256 public mtgyServiceCost = 5000 * 10**18;

  struct Receiver {
    address userAddress;
    uint256 amountToReceive;
  }

  constructor(address _mtgyTokenAddy, address _mtgySpendAddy) {
    creator = msg.sender;
    mtgyTokenAddy = _mtgyTokenAddy;
    mtgySpendAddy = _mtgySpendAddy;
    _mtgy = ERC20(_mtgyTokenAddy);
    _mtgySpend = MTGYSpend(_mtgySpendAddy);
  }

  function changeMtgyTokenAddy(address _tokenAddy) public {
    require(
      msg.sender == creator,
      'changeMtgyTokenAddy user must be contract creator'
    );
    mtgyTokenAddy = _tokenAddy;
    _mtgy = ERC20(_tokenAddy);
  }

  function changeMtgySpendAddy(address _spendAddy) public {
    require(
      msg.sender == creator,
      'changeMtgyTokenAddy user must be contract creator'
    );
    mtgySpendAddy = _spendAddy;
    _mtgySpend = MTGYSpend(_spendAddy);
  }

  function changeServiceCost(uint256 _newCost) public {
    require(msg.sender == creator, 'user needs to be the contract creator');
    mtgyServiceCost = _newCost;
  }

  function bulkSendMainTokens(Receiver[] memory _addressesAndAmounts)
    public
    payable
    returns (bool)
  {
    _payForService();

    bool _wasSent = true;

    for (uint256 _i = 0; _i < _addressesAndAmounts.length; _i++) {
      Receiver memory _user = _addressesAndAmounts[_i];
      (bool sent, ) =
        _user.userAddress.call{ value: _user.amountToReceive }('');
      _wasSent = _wasSent == false ? false : sent;
    }
    return _wasSent;
  }

  function bulkSendErc20Tokens(
    address _tokenAddress,
    Receiver[] memory _addressesAndAmounts
  ) public returns (bool) {
    _payForService();

    ERC20 _token = ERC20(_tokenAddress);
    for (uint256 _i = 0; _i < _addressesAndAmounts.length; _i++) {
      Receiver memory _user = _addressesAndAmounts[_i];
      _token.transferFrom(msg.sender, _user.userAddress, _user.amountToReceive);
    }
    return true;
  }

  function _payForService() private {
    _mtgy.transferFrom(msg.sender, address(this), mtgyServiceCost);
    _mtgy.approve(mtgySpendAddy, mtgyServiceCost);
    _mtgySpend.spendOnProduct(mtgyServiceCost);
  }
}