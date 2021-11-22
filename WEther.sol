// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract WEther is Ownable{
    
    address weth_owner;

    constructor (address _own) {
        weth_owner = _own;
    }
        
    function changeOwner(address _newOwner) public onlyOwner {
        weth_owner = _newOwner;
    }
    
    function withdraw() public onlyOwner {
        // new version of solidity requires payable_address
        payable(weth_owner).transfer(getBalance());
    }

    function deposit() payable public onlyOwner {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
 
}
