// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FileRegistry{
    mapping(address => mapping( string => string)) keys;

     function addKey(address entity, string[] memory fileHashes, string[] memory keyList)public returns(bool) {
        //if the write operation is a delete operation
        if(fileHashes.length>0 && keyList.length==0){
            for(uint i=0;i<fileHashes.length;i++){
                delete keys[entity][fileHashes[i]];
            }
        }
        //if files added
        else if(fileHashes.length==keyList.length){
            for(uint i = 0;i<fileHashes.length;i++){
                keys[entity][fileHashes[i]]=keyList[i];
            }
        }
        else{
            return false;
        }
        return true;
    }

    function getKeys(address entity, string[] memory fileHashes) public view returns (string[] memory) {
        string[] memory keyList = new string[](fileHashes.length);
        
        for (uint i = 0; i < fileHashes.length; i++) {
            string memory key = keys[entity][fileHashes[i]];
            require(bytes(key).length > 0, "Key not available for one or more files");
            keyList[i] = key;
        }
        
        return keyList;
    }

}