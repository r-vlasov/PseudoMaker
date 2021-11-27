// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./WEther.sol";
import "./Math.sol";
import "./PseudoMaker.sol";

contract CDP {
  
    address creator;
    address owner;
    address makerAddress;  
    WEther weth;
    uint256 rate;
    uint256 wethBalance = 0;
    uint256 tokenBorrowed = 0;
    uint256 constant WETH = 10 ** 18;
    uint256 constant WETH_RESERVED = 11 * 10**17; // for reservation (like Maker)
    uint256 constant CHAINLINK_ETH_USD = 10 ** 8;
    
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
        return(status == StatusType.BORROWED);
    }
    
    function fund(uint256 _amount) payable public OnlyMaker returns(uint256) {
        require(status == StatusType.OPENED);
        uint256 _maxTokenBorrowed = SafeMath.div(
            SafeMath.div(
                SafeMath.mul(PseudoMaker(makerAddress).wethDaiRate(), msg.value),
                CHAINLINK_ETH_USD 
            ), WETH
        );
        require(_amount < _maxTokenBorrowed);
        
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

    function reCalculateFundCloseCDPAuction() public OnlyMaker returns(bool) {
        if (status != StatusType.BORROWED) {
            return(false);
        } 
        uint256 _currRateDaiBorrowed = SafeMath.div(SafeMath.mul(PseudoMaker(makerAddress).wethDaiRate(), wethDeposit()), WETH_RESERVED);
        if (daiBorrowed() > _currRateDaiBorrowed) {
            owner = makerAddress;
            status = StatusType.AUCTIONED;
            weth.changeOwner(makerAddress);
            return(true);
        }
        return(false);
    }

    function destroyByAuction(address _newOwner) public OnlyMaker {
        weth.changeOwner(_newOwner);
        back();
        status = StatusType.CLOSED;
    }
}
