// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Dai.sol";
import "./Cdp.sol";
import "./Auction.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PseudoMaker {
    
    DAI dai;
    Auction auction;
    mapping (address => CDP[]) private addressCDP;
    address[] private users;
    
    AggregatorV3Interface internal priceFeed;

    modifier OnlyAuction() {
        require(msg.sender == address(auction));
        _;
    }
    
    function getLatestPrice() public view returns (uint256) {
        (, int256 price,,, ) = priceFeed.latestRoundData();
        return uint256(price);
    }
    
    constructor() {
        dai = new DAI();
        auction = new Auction();
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }
    
    function wethDaiRate() public view returns (uint256) {
        (, int256 price,,, ) = priceFeed.latestRoundData();
        return uint256(price);
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
            if (address(_cdps[i]) == _cdp) {
                return(true, i);
            }
        }
        return(false, 0);
    } 
    
    function fund(uint256 amount) public payable returns(CDP) {
        CDP _cdp = new CDP(msg.sender);
        _cdp.fund{value:msg.value}(amount);
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
    
    function deleteCdpFromUser(address usr, address _cdp) private {
        require(CDP(_cdp).isOpen() == false);
        (bool _in, uint256 _idx) = _searchInCdpArray(_cdp, addressCDP[usr]);
        require(_in == true);
        uint len = addressCDP[usr].length;
        addressCDP[usr][_idx] = addressCDP[usr][len - 1];
        addressCDP[usr].pop();
    } 

    function addCDPAuction(address _cdpAddress) public OnlyAuction returns(bool) {
        return(CDP(_cdpAddress).reCalculateFundCloseCDPAuction());
    }
    
    function bidAuctionCDP(address _cdpAddress, address sender) public OnlyAuction {
        dai.burn(sender, CDP(_cdpAddress).daiBorrowed());
        CDP(_cdpAddress).destroyByAuction(sender);
        deleteCdpFromUser(CDP(_cdpAddress).getCreator(), _cdpAddress);
    }
}
