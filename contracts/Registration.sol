// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registration{
    // Struct to hold participant details
    struct Participant {
        string uniqueId; // Unique ID generated using SHA-256 of personal data
        string name;     // Participant's name
        string role;
        bool isRegistered; // Registration status
    }

    // Mapping from blockchain address to participant details
    mapping(address => Participant) private participants;
    mapping(string => bool) private uidList;

    // Event to notify when a new participant is registered
    event ParticipantRegistered(
        address indexed participantAddress,
        string uniqueId,
        string name,
        string role
    );

    // Modifier to check if the participant is already registered
    modifier notRegistered(address participantAddress) {
        require(
            !participants[participantAddress].isRegistered,
            "Participant already registered"
        );
        _;
    }

    // Function to register a new participant
    function registerParticipant(
        string memory uniqueId,
        string memory name,
        string memory role
    ) public notRegistered(msg.sender) {
        require(
            keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("patient")) ||
            keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("hospital")),
            "Invalid role. Must be 'patient' or 'hospital'."
        );

        // Store participant details
        participants[msg.sender] = Participant({
            uniqueId: uniqueId,
            name: name,
            role: role,
            isRegistered: true
        });

        uidList[uniqueId]=true;

        emit ParticipantRegistered(msg.sender, uniqueId, name, role);
    }

    // Function to validate if a participant is registered
    function isParticipantRegistered(address participantAddress)
        public
        view
        returns (bool)
    {
        return participants[participantAddress].isRegistered;
    }

    // Function to get participant details
    function getParticipantDetails(address participantAddress)
        public
        view
        returns (
            string memory uniqueId,
            string memory name,
            string memory role
        )
    {
        require(
            participants[participantAddress].isRegistered,
            "Participant is not registered"
        );

        Participant memory participant = participants[participantAddress];
        return (
            participant.uniqueId,
            participant.name,
            participant.role
        );
    }

    function isValidUid(address requester, string memory uid) public view returns(bool){
        require(participants[requester].isRegistered,"Not a registered user");
        return uidList[uid];
    }
}
