// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage{
    uint x=6;
    event setted(address indexed, uint value);

    function set(uint y) public returns(bool){
        x=y;
        emit setted(msg.sender, x);
        return true;
    }
    function get() public view returns(uint){
        return x;
    }
}