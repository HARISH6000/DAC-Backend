// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistration {
    function isParticipantRegistered(address participant) external view returns (bool);
    function getParticipantDetails(address participant) external view returns (
        string memory uniqueId,
        string memory name,
        string memory role,
        string memory publicKey
    );
    function getPublicKey(address participant) external view returns (string memory);
}

interface IAccessControl {
    function verifyFileAccess(address patient, address hospital, string[] memory fileHashes) external view returns (bool);
    function verifyFileWriteAccess(address patient, address hospital) external view returns (bool);
}

interface IFileRegistry {
    function addKey(address entity, string[] calldata fileHashes, string[] calldata keyList) external returns (bool);
    function getKeys(address entity, string[] calldata fileHashes) external view returns (string[] memory);
    function doesFilesExist(address entity, string[] calldata fileHashes)external view returns(bool);
}

contract ValidationContract {
    struct Token {
        bytes32 tokenHash;
        address hospital;
        address patient;
        uint expiry;
        bool isUsed;
    }

    mapping(bytes32 => Token) private tokens;
    mapping(address => uint) private nonces;

    IRegistration public registration;
    IAccessControl public accessControl;
    IFileRegistry public fileRegistry;

    event ReadAccessTokenGenerated(bytes32 indexed tokenHash, address indexed hospital, address indexed patient, string[] fileHashes, uint expiry);
    event TokenValidated(bytes32 indexed tokenHash, address indexed hospital);
    event WriteAccessTokenGenerated(bytes32 indexed tokenHash, address indexed hospital, address indexed patient, uint expiry);

    constructor(address _registration, address _accessControl,address _fileRegistry) {
        registration = IRegistration(_registration);
        accessControl = IAccessControl(_accessControl);
        fileRegistry = IFileRegistry(_fileRegistry);
    }

    function requestFileReadAccessToken(address patient, string[] memory fileHashes) external returns (bytes32) {
        address hospital = msg.sender;

        require(registration.isParticipantRegistered(hospital), "Hospital not registered");
        (,, string memory role,) = registration.getParticipantDetails(hospital);
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("hospital")), "Caller must be a hospital");

        require(registration.isParticipantRegistered(patient), "Patient not registered");
        require(fileHashes.length > 0, "File hash list cannot be empty");

        require(accessControl.verifyFileAccess(patient, hospital, fileHashes), "No access to requested files");

        uint nonce = nonces[hospital]++;
        bytes32 tokenHash = keccak256(abi.encodePacked(hospital, patient, fileHashes[0], block.timestamp, nonce));
        uint expiry = block.timestamp + 1 hours;

        tokens[tokenHash] = Token({
            tokenHash: tokenHash,
            hospital: hospital,
            patient: patient,
            expiry: expiry,
            isUsed: false
        });

        emit ReadAccessTokenGenerated(tokenHash, hospital, patient, fileHashes, expiry);
        return tokenHash;
    }

    function validateToken(bytes32 tokenHash, bytes memory signature, bool isWrite, string[] memory fileHashes, string[] memory keyList) external returns (bool) {
        Token storage token = tokens[tokenHash];
        require(token.tokenHash != bytes32(0), "Invalid token");
        require(!token.isUsed, "Token already used");
        require(token.expiry > block.timestamp, "Token expired");

        string memory publicKey = registration.getPublicKey(token.hospital);
        require(bytes(publicKey).length > 0, "Public key not found");

        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", tokenHash));
        bytes32 r;
        bytes32 s;
        uint8 v;
        require(signature.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        address signer = ecrecover(messageHash, v, r, s);
        require(signer == token.hospital, "Invalid signature");

        token.isUsed = true;
        emit TokenValidated(tokenHash, token.hospital);
        if(isWrite){
            require(fileRegistry.addKey(token.patient,fileHashes,keyList),"fileList length and KeyList length does not match");
        }
        return true;
    }

    function requestFileWriteAccessToken(address patient) external returns (bytes32) {
        address hospital = msg.sender;
        require(registration.isParticipantRegistered(hospital), "Hospital not registered");
        (,, string memory role,) = registration.getParticipantDetails(hospital);
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("hospital")), "Caller must be a hospital");
        require(registration.isParticipantRegistered(patient), "Patient not registered");
        (,, string memory pRole,) = registration.getParticipantDetails(patient);
        require(keccak256(abi.encodePacked(pRole)) == keccak256(abi.encodePacked("patient")), "patient address doesnt corresspond to patient role");
        require(accessControl.verifyFileWriteAccess(patient, hospital), "No write access");

        uint nonce = nonces[hospital]++;
        bytes32 tokenHash = keccak256(abi.encodePacked(hospital, patient, "write", block.timestamp, nonce));
        uint expiry = block.timestamp + 1 hours;

        tokens[tokenHash] = Token({
            tokenHash: tokenHash,
            hospital: hospital,
            patient: patient,
            expiry: expiry,
            isUsed: false
        });

        emit WriteAccessTokenGenerated(tokenHash, hospital, patient, expiry);
        return tokenHash;
    }

    function requestOwnFilesReadToken(string[] memory fileHashes)public returns(bytes32){
        require(registration.isParticipantRegistered(msg.sender), "Patient not registered");
        require(fileHashes.length > 0, "File hash list cannot be empty");
        require(fileRegistry.doesFilesExist(msg.sender,fileHashes),"Requested file/files doesnt exist");

        uint nonce = nonces[msg.sender]++;
        bytes32 tokenHash = keccak256(abi.encodePacked(msg.sender, msg.sender, fileHashes[0], block.timestamp, nonce));
        uint expiry = block.timestamp + 1 hours;

        tokens[tokenHash] = Token({
            tokenHash: tokenHash,
            hospital: msg.sender,
            patient: msg.sender,
            expiry: expiry,
            isUsed: false
        });

        emit ReadAccessTokenGenerated(tokenHash, msg.sender, msg.sender, fileHashes, expiry);
        return tokenHash;
        
    }

    function requestOwnFilesWriteToken()public returns(bytes32){
        require(registration.isParticipantRegistered(msg.sender), "Patient not registered");
        
        uint nonce = nonces[msg.sender]++;
        bytes32 tokenHash = keccak256(abi.encodePacked(msg.sender, msg.sender, "write", block.timestamp, nonce));
        uint expiry = block.timestamp + 1 hours;

        tokens[tokenHash] = Token({
            tokenHash: tokenHash,
            hospital: msg.sender,
            patient: msg.sender,
            expiry: expiry,
            isUsed: false
        });

        emit WriteAccessTokenGenerated(tokenHash, msg.sender, msg.sender, expiry);
        return tokenHash;
        
    }

    function cleanupExpiredTokens(bytes32[] memory tokenHashes) external {
        for (uint i = 0; i < tokenHashes.length; i++) {
            Token storage token = tokens[tokenHashes[i]];
            if (token.expiry <= block.timestamp && token.tokenHash != bytes32(0)) {
                delete tokens[tokenHashes[i]];
            }
        }
    }
}