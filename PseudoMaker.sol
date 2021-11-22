// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Dai.sol";
import "./Cdp.sol";

contract PseudoMaker {
    
    DAI dai;
    mapping (address => CDP[]) private addressCDP;
    address[] private users;
    uint256 private rate = 0; // how much weth by 1$
    address[] private auctionCDP;
    
    constructor() {
        dai = new DAI();
        reNewRate(10);
    }
    
    function wethDaiRate() public view returns(uint256) {
        return rate;
    }
    
    function daiAddress() public view returns(address) {
        return(address(dai));
    }
    
    function _searchInArray(address _usr, address[] memory _users) private view returns(bool, uint256) {
        for (uint i = 0; i < users.length; i++) {
            if (_users[i] == _usr) {
                return(true, i);
            }
        }
        return(false, 0);
    } 
    
    function fund(uint256 amount) public payable returns(CDP) {
        CDP _cdp = new CDP(msg.sender);
        _cdp.fund{value:msg.value}(amount, rate);
        dai.mint(msg.sender, amount);
        
        addressCDP[msg.sender].push(_cdp);
        (bool _in, uint256 _idx) = _searchInArray(msg.sender, users); _idx = 0;
        if (_in == false) {
            users.push(msg.sender);
        }
        return(_cdp);
    }
    
    function back(address cdpAddress) public returns(bool){
        uint256 len = addressCDP[msg.sender].length;
        for (uint i = 0; i < addressCDP[msg.sender].length; i++) {
            CDP _cdp = addressCDP[msg.sender][i];
            if (address(_cdp) == cdpAddress) {
                dai.burn(msg.sender, _cdp.daiBorrowed());
                _cdp.back();
                addressCDP[msg.sender][i] = addressCDP[msg.sender][len - 1];
                addressCDP[msg.sender].pop();
                return(true);
            }
        }
        return(false);
    }

    function cdpByAddress(address usr) public view returns(CDP[] memory) {
        return addressCDP[usr];
    }
    
    // Now everyone can set a price - this is done for debugging. In fact, inside the oracle should be called, which will put rate
    function reNewRate(uint256 _rate) public {
        rate = _rate; // there should be oracle
        refreshAllCDP(rate);
    }
    
    function refreshAllCDP(uint256 _rate) private {
        for (uint i = 0; i < users.length; i++) {
            for (uint j = 0; j < addressCDP[users[i]].length; j++) {
                if (refreshCDP(addressCDP[users[i]][j], _rate) == true) {
                    uint256 len = addressCDP[users[i]].length;
                    addressCDP[users[i]][j] = addressCDP[users[i]][len - 1];
                    addressCDP[users[i]].pop();
                }
            }
        }
    }
    
    function refreshCDP(CDP _cdp, uint256 _rate) private returns(bool) {
        if (_cdp.reCalculateFundCloseCDP(_rate) == true) {
            auctionCDP.push(address(_cdp));
            return(true);
        }
        return(false);
    }
    
    function auction() public view returns(address[] memory) {
        return(auctionCDP);
    }
    
    function bidAuctionCDP(address _cdpAddress) public {
        (bool _in, uint256 _idx) = _searchInArray(_cdpAddress, auctionCDP);        
        require(_in == true);
        dai.burn(msg.sender, CDP(_cdpAddress).daiBorrowed());
        CDP(_cdpAddress).destroyByAuction(msg.sender);
        auctionCDP[_idx] = auctionCDP[auctionCDP.length - 1];
        auctionCDP.pop();
    }
}