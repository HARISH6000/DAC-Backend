// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for RequestContract to retrieve request details
interface IRequestContract {
    enum AccessType { Read, Write, Both }
    
    struct Request {
        uint requestId;
        address hospital;
        address patient;
        string[] fileList;
        uint deadline;
        AccessType accessType;
        bool isAll;
        bool isProcessed;
    }
    
    function getRequest(uint requestId) external view returns (Request memory);
    function setRequestProcessed(uint requestId) external;
}

contract AccessControlContract {
    enum AccessType {NoAccess, Read, Write, Both}
    struct ValidationInfo {
        AccessType accessType;
        bool isAll;
        uint deadline;
        uint writeDeadline;
        string[] keys; 
        uint lastCleanUp;
    }

    IRequestContract public requestContract;

    // Constructor to initialize RequestContract address
    constructor(address _requestContract) {
        requestContract = IRequestContract(_requestContract);
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
        if (accessType==AccessType.Write || accessType== AccessType.Both){
            info.writeDeadline=block.timestamp+deadline;
        }

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

    // Function for patients to process a request and grant access
    function processRequest(uint requestId) external returns (bool) {
        // Retrieve the request from RequestContract
        IRequestContract.Request memory req = requestContract.getRequest(requestId);

        // Validate that the caller is the targeted patient
        require(req.patient == msg.sender, "Only the targeted patient can process this request");

        // Validate that the request hasn't been processed
        require(!req.isProcessed, "Request already processed");

        // Map RequestContract AccessType to AccessControlContract AccessType
        // Since RequestContract AccessType (Read=0, Write=1, Both=2) needs to map to
        // AccessControlContract AccessType (NoAccess=0, Read=1, Write=2, Both=3)
        AccessType accessType;
        if (uint(req.accessType) == 0) { // Read in RequestContract
            accessType = AccessType.Read; // Read=1 in AccessControlContract
        } else if (uint(req.accessType) == 1) { // Write in RequestContract
            accessType = AccessType.Write; // Write=2 in AccessControlContract
        } else if (uint(req.accessType) == 2) { // Both in RequestContract
            accessType = AccessType.Both; // Both=3 in AccessControlContract
        } else {
            revert("Invalid access type");
        }

        // Call grantAccess with the request details
        bool success = grantAccess(
            req.hospital,
            accessType,
            req.isAll,
            req.fileList,
            req.deadline
        );

        // Mark the request as processed in RequestContract
        if (success) {
            requestContract.setRequestProcessed(requestId);
        }

        return success;
    }

    function verifyFileAccess(address patient, address hospital, string[] memory fileHashes) external view returns (bool) {
        ValidationInfo storage info = permissionList[patient][hospital];
        
        // Check if there are any permissions at all
        if (info.deadline == 0) {
            return false;
        }

        // If hospital has "isAll" access with appropriate permissions
        if (info.isAll && info.deadline > block.timestamp) {
            // Check if access type is sufficient (Read or Both)
            return (info.accessType == AccessType.Read || info.accessType == AccessType.Both);
        }

        // For specific file access, verify each file hash
        for (uint i = 0; i < fileHashes.length; i++) {
            uint deadline = accessList[patient][hospital][fileHashes[i]];
            if (deadline == 0 || deadline <= block.timestamp) {
                return false; // If any file is inaccessible, return false
            }
        }

        // Check if access type permits reading (Read or Both)
        return (info.accessType == AccessType.Read || info.accessType == AccessType.Both);
    }

    function verifyFileWriteAccess(address patient, address hospital) external view returns (bool) {
        ValidationInfo storage info = permissionList[patient][hospital];
        
        if (info.writeDeadline == 0 || info.writeDeadline <= block.timestamp) {
            return false;
        }

        return info.accessType == AccessType.Write || info.accessType == AccessType.Both;
    }

}

