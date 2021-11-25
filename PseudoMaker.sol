// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Dai.sol";
import "./Cdp.sol";
import "./Auction.sol";

contract PseudoMaker {
    
    DAI dai;
    Auction auction;
    mapping (address => CDP[]) private addressCDP;
    address[] private users;
    uint256 private rate = 0; // how much weth by 1$
    
    modifier OnlyAuction() {
        require(msg.sender == address(auction));
        _;
    }
    
    constructor() {
        dai = new DAI();
        auction = new Auction();
        reNewRate(10);
    }
    
    function wethDaiRate() public view returns(uint256) {
        return rate;
    }
    
    function daiAddress() public view returns(address) {
        return(address(dai));
    }

    function auctionAddress() public view returns(address) {
        return(address(auction));
    }
    
    function _searchInArray(address _usr, address[] memory _users) private pure returns(bool, uint256) {
        for (uint i = 0; i < _users.length; i++) {
            if (_users[i] == _usr) {
                return(true, i);
            }
        }
        return(false, 0);
    } 

    function _searchInCdpArray(address _cdp, CDP[] memory _cdps) private pure returns(bool, uint256) {
        for (uint i = 0; i < _cdps.length; i++) {
            if (_cdps[i] == CDP(_cdp)) {
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
    
    function back(address cdpAddress) public returns(bool) {
        require(CDP(cdpAddress).isOpen());
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
        return(addressCDP[usr]);
    }
    
    function deleteCdp(address usr, address _cdp) public {
        require(CDP(_cdp).isOpen() == false);
        (bool _in, uint256 _idx) = _searchInCdpArray(_cdp, addressCDP[usr]);
        require(_in == true);
        uint len = addressCDP[usr].length;
        addressCDP[usr][_idx] = addressCDP[usr][len - 1];
        addressCDP[usr].pop();
    } 

    // Now everyone can set a price - this is done for debugging. In fact, inside the oracle should be called, which will put rate
    function reNewRate(uint256 _rate) public {
        rate = _rate; // there should be an oracle
    }

    function addCDPAuction(address _cdpAddress) public OnlyAuction returns(bool) {
        return(CDP(_cdpAddress).reCalculateFundCloseCDPAuction());
    }
    
    function bidAuctionCDP(address _cdpAddress, address sender) public OnlyAuction {
        dai.burn(sender, CDP(_cdpAddress).daiBorrowed());
        CDP(_cdpAddress).destroyByAuction(sender);
    }
}
