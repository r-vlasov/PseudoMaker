// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./WEther.sol";
import "./Math.sol";


contract CDP {
  
  address creator;
  address owner;
  address makerAddress;
  WEther weth;
  uint256 rate;
  uint256 wethBalance = 0;
  uint256 tokenBorrowed = 0;
  uint256 constant WETH = 10**18;
  uint256 constant WETH_RESERVED = 11 * 10**17; // for reservation (like Maker)
  
  enum StatusType {
      OPENED, 
      BORROWED, 
      CLOSED,
      AUCTIONED
  }
  StatusType status;
   
  modifier OnlyMaker() {
    require(msg.sender == makerAddress);
    _;
  }
  
  constructor (address _creator) {
      creator = _creator;
      owner = creator;
      // msg.sender is withdraw
      makerAddress = msg.sender;
      weth = new WEther(creator); // only PseudoMaker can withdraw
      status = StatusType.OPENED;
  }
  
  function wethDeposit() public view returns(uint256) {
      require(wethBalance == weth.getBalance());
      return(weth.getBalance());
  }
  
  function daiBorrowed() public view returns(uint256) {
      return(tokenBorrowed);
  }
  
  function getCreator() public view returns(address) {
      return(creator);
  }
  
  function getMakerAddress() public view returns(address) {
      return(makerAddress);
  }
  
    
  function isOpen() public view returns(bool) {
      return(status == StatusType.CLOSED);
  }
  
  function fund(uint256 _amount, uint256 _rate) payable public OnlyMaker returns(uint256) {
      require(status == StatusType.OPENED);
      rate = _rate;
      uint256 _tokenBorrowed = SafeMath.mul(rate, SafeMath.div(msg.value, WETH));
      require(_amount < _tokenBorrowed);
    
      wethBalance = msg.value;
      tokenBorrowed = _amount;
      weth.deposit{value:msg.value}();
      status = StatusType.BORROWED;
      return(tokenBorrowed);
  }
  
  function back() public OnlyMaker {
      weth.withdraw();
      status = StatusType.CLOSED;
  }

  // TRUE -> close CDP
  // FALSE -> everything is OK
  function reCalculateFundCloseCDP(uint256 _rate) public OnlyMaker returns(bool) {
      if (status != StatusType.BORROWED) {
          return(false);
      }
      uint256 _currRateDaiBorrowed = SafeMath.mul(_rate, SafeMath.div(wethDeposit(), WETH_RESERVED));
      if (daiBorrowed() > _currRateDaiBorrowed) {
          owner = makerAddress;
          status = StatusType.AUCTIONED;
          weth.changeOwner(makerAddress);
          return(true);
      } else {
          return(false);
      }
  }
  
  function destroyByAuction(address _newOwner) public OnlyMaker {
      weth.changeOwner(_newOwner);
      back();
      status = StatusType.CLOSED;
  }
}
