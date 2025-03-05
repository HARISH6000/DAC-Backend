// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControlContract {
    enum AccessType {Read, Write, Both, NoAccess}
    struct ValidationInfo {
        AccessType accessType;
        bool isAll;
        uint deadline;
        string[] keys;
        mapping (string => uint) accessList;
    }
    mapping (address => mapping(string => ValidationInfo)) public permissionList;

    function grantAccess(string memory uid, AccessType accessType,bool isAll, string[] memory accessList,uint deadline)public returns(bool){
        
        ValidationInfo storage info = permissionList[msg.sender][uid];
        info.accessType=accessType;
        info.isAll=isAll;
        info.deadline=block.timestamp+deadline;

        if (!isAll){
            for (uint i=0; i<accessList.length;i++){
                if(info.accessList[accessList[i]]==0){
                    info.keys.push(accessList[i]);
                }
                info.accessList[accessList[i]]=block.timestamp + deadline;
            }
        }   
        return true;
    }

    function getAccessList(string memory uid)public view returns(string memory){
        ValidationInfo storage info = permissionList[msg.sender][uid];
        string memory t="";
        for(uint i=0; i<info.keys.length;i++){
            t = string(abi.encodePacked(t, info.keys[i], "-", uint2str(info.accessList[info.keys[i]]), ";"));
        }
        return t;
    }

    function removeAccess(string memory uid, string[] memory list)public {
        ValidationInfo storage info = permissionList[msg.sender][uid];
        for(uint i=0;i<list.length;i++){
            if(info.accessList[list[i]]!=0){
                info.accessList[list[i]]=block.timestamp;
            }
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function getAccessType(string memory uid)public view returns (uint){
        ValidationInfo storage info = permissionList[msg.sender][uid];
        return uint(info.accessType);
    }

    
}

