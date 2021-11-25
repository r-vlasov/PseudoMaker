// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Cdp.sol";
import "./PseudoMaker.sol";

contract Auction {
    
    address[] private auctionCDP;
    address makerAddress;

    constructor () {
        makerAddress = msg.sender;
    }
    
    function _searchInArray(address _cdpAddress, address[] memory _auction) private pure returns(bool, uint256) {
        for (uint i = 0; i < _auction.length; i++) {
            if (_auction[i] == _cdpAddress) {
                return(true, i);
            }
        }
        return(false, 0);
    } 

    function addCDP(address _cdpAddress) public {
        CDP cdp = CDP(_cdpAddress);
        require(cdp.isOpen() == true);
        require(PseudoMaker(makerAddress).addCDPAuction(_cdpAddress) == true);
        auctionCDP.push(_cdpAddress);
    }

    function lotsCDP() public view returns(address[] memory) {
        return(auctionCDP);
    }
    
    function buyCDP(address _cdpAddress) public {
        (bool _in, uint256 _idx) = _searchInArray(_cdpAddress, auctionCDP);        
        require(_in == true);
        PseudoMaker(makerAddress).bidAuctionCDP(_cdpAddress, msg.sender);
        auctionCDP[_idx] = auctionCDP[auctionCDP.length - 1];
        auctionCDP.pop();
    }
}