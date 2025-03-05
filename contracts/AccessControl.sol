// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControlContract {
    enum AccessType {NoAccess, Read, Write, Both}
    struct ValidationInfo {
        AccessType accessType;
        bool isAll;
        uint deadline;
        string[] keys;
        uint lastCleanUp;
    }

    mapping (address => mapping (address => mapping (string=>uint))) private accessList;
    mapping (address => mapping(address => ValidationInfo)) private permissionList;

    event AccessGranted(address indexed patient, address hospitalAddress, AccessType accessType, bool isAll, string[] keys, uint deadline);
    event AccessRemoved(address indexed patient, address hospitalAddress, string[] keys);
    event ExpiredKeysCleaned(address indexed patient, address hospitalAddress, uint numKeysRemoved);
    event AllAccessRemoved(address indexed patient, address hospitalAddress);

    function grantAccess(address hospitalAddress, AccessType accessType,bool isAll, string[] memory fileList,uint deadline)public returns(bool){
        
        ValidationInfo storage info = permissionList[msg.sender][hospitalAddress];
        info.accessType=accessType;
        info.isAll=isAll;
        info.deadline=block.timestamp+deadline;

        if(info.lastCleanUp==0){
            info.lastCleanUp=block.timestamp;
        }

        if (!isAll){
            for (uint i=0; i<fileList.length;i++){
                if(accessList[msg.sender][hospitalAddress][fileList[i]]==0){
                    info.keys.push(fileList[i]);
                }
                accessList[msg.sender][hospitalAddress][fileList[i]]=block.timestamp + deadline;
            }
        }
        emit AccessGranted(msg.sender, hospitalAddress, accessType, isAll, fileList, info.deadline);
        if (info.lastCleanUp<block.timestamp-100 days){
            cleanupExpiredKeys(hospitalAddress);
            info.lastCleanUp=block.timestamp;
        }
        return true;
    }

    function getAccessList(address hospitalAddress) public view returns (string[] memory keys, uint[] memory deadlines) {
        ValidationInfo storage info = permissionList[msg.sender][hospitalAddress];
        uint[] memory deadlinesArray = new uint[](info.keys.length);
        for (uint i = 0; i < info.keys.length; i++) {
            deadlinesArray[i] = accessList[msg.sender][hospitalAddress][info.keys[i]];
        }
        return (info.keys, deadlinesArray);
    }

    function removeAccess(address hospitalAddress, string[] memory list)public {
        ValidationInfo storage info = permissionList[msg.sender][hospitalAddress];
        for(uint i=0;i<list.length;i++){
            if(accessList[msg.sender][hospitalAddress][list[i]]!=0){
                accessList[msg.sender][hospitalAddress][list[i]]=block.timestamp;
            }
        }
        if (info.lastCleanUp<block.timestamp-100 days){
            cleanupExpiredKeys(hospitalAddress);
            info.lastCleanUp=block.timestamp;
        }
        emit AccessRemoved(msg.sender, hospitalAddress, list);
    }

    function removeAllAcess(address hospitalAddress)public{
        ValidationInfo storage info=permissionList[msg.sender][hospitalAddress];
        require(info.deadline > 0, "No access permissions exist for this hospital");
        for (uint i = 0; i < info.keys.length; i++) {
            string memory key = info.keys[i];
            delete accessList[msg.sender][hospitalAddress][key]; // Clear each entry
        }
        emit AllAccessRemoved(msg.sender, hospitalAddress);
        delete permissionList[msg.sender][hospitalAddress];
    }

    function getAccessType(address hospitalAddress)public view returns (uint){
        ValidationInfo storage info = permissionList[msg.sender][hospitalAddress];
        return uint(info.accessType);
    }

    function cleanupExpiredKeys(address hospitalAddress) public {
        ValidationInfo storage info = permissionList[msg.sender][hospitalAddress];
        uint i = 0;
        uint numRemoved = 0;
        while (i < info.keys.length) {
            string memory key = info.keys[i];
            if (accessList[msg.sender][hospitalAddress][key] <= block.timestamp) {
                // Swap-and-pop to remove the key
                info.keys[i] = info.keys[info.keys.length - 1];
                info.keys.pop();
                delete accessList[msg.sender][hospitalAddress][key]; // Clear storage
                numRemoved++;
            } else {
                i++;
            }
        }
        if (numRemoved > 0) {
            emit ExpiredKeysCleaned(msg.sender, hospitalAddress, numRemoved);
        }
    }

}

