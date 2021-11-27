// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Math.sol";


contract DAI is Ownable, IERC20 {
    
    mapping (address => uint256) private tokens;
    mapping (address => mapping (address => uint256)) private ApprovedTokens;
    
    uint256 private totalTokenSupply;
    
    function mint(address usr, uint dai) public onlyOwner {
        tokens[usr] = SafeMath.add(tokens[usr], dai);
        totalTokenSupply = SafeMath.add(totalTokenSupply, dai);
        emit Transfer(address(0), usr, dai);
    }
    
    function burn(address usr, uint dai) public onlyOwner {
        require(tokens[usr] >= dai, "Insufficient-balance");
        tokens[usr] = SafeMath.sub(tokens[usr], dai);
        totalTokenSupply = SafeMath.sub(totalTokenSupply, dai);
        emit Transfer(usr, address(0), dai);
    }

    // tokens
    function totalSupply() override public view returns (uint256) {
        return totalTokenSupply;
    }
    
    function balanceOf(address usr) override public view returns (uint256) {
        return(tokens[usr]);
    }
    
    function transfer(address dst, uint dai) override public returns (bool) {
        return transferFrom(msg.sender, dst, dai);
    }
    
    function transferFrom(address src, address dst, uint dai) override public returns (bool) {
        require(src == msg.sender || ApprovedTokens[src][msg.sender] >= dai);
        require(tokens[src] >= dai, "Insufficient-balance");
        if (src != msg.sender) {
            ApprovedTokens[src][msg.sender] -= dai;
        }
        tokens[src] = SafeMath.sub(tokens[src], dai);
        tokens[dst] = SafeMath.add(tokens[dst], dai);
        emit Transfer(src, dst, dai);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        ApprovedTokens[msg.sender][_spender] = _value;
        return(true);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return(ApprovedTokens[_owner][_spender]);
    }
}
