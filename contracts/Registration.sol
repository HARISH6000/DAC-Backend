// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registration {
    enum Role { Patient, Hospital }

    struct Participant {
        string uniqueId; // Unique ID generated using SHA-256 of personal data
        string name;     // Participant's name
        Role role;       // Participant's role (Patient or Hospital)
    }

    // Mapping from blockchain address to participant details
    mapping(address => Participant) private participants;

    // Mapping to track registration status (default false)
    mapping(address => bool) private isRegistered;

    // Mapping to track if a unique ID is already in use
    mapping(string => bool) private uidList;

    // Mappings to map unique IDs to addresses for patients and hospitals
    mapping(string => address) private patientList;
    mapping(string => address) private hospitalList;

    // Event to notify when a new participant is registered
    event ParticipantRegistered(
        address indexed participantAddress,
        string uniqueId,
        string name,
        string role
    );

    // Modifier to check if the participant is not already registered
    modifier notRegistered() {
        require(
            !isRegistered[msg.sender],
            "Participant already registered"
        );
        _;
    }

    // Function to register a new participant
    function registerParticipant(
        string memory uniqueId,
        string memory name,
        string memory role
    ) public notRegistered {
        // Validate role and convert to enum
        Role participantRole;
        if (keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("patient"))) {
            participantRole = Role.Patient;
            require(patientList[uniqueId] == address(0), "Unique ID already used for a patient");
            patientList[uniqueId] = msg.sender;
        } else if (keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("hospital"))) {
            participantRole = Role.Hospital;
            require(hospitalList[uniqueId] == address(0), "Unique ID already used for a hospital");
            hospitalList[uniqueId] = msg.sender;
        } else {
            revert("Invalid role. Must be 'patient' or 'hospital'.");
        }

        // Store participant details
        participants[msg.sender] = Participant({
            uniqueId: uniqueId,
            name: name,
            role: participantRole
        });

        // Mark as registered
        isRegistered[msg.sender] = true;

        // Mark the unique ID as used
        uidList[uniqueId] = true;

        emit ParticipantRegistered(msg.sender, uniqueId, name, role);
    }

    // Function to validate if a participant is registered
    function isParticipantRegistered(address participantAddress)
        public
        view
        returns (bool)
    {
        return isRegistered[participantAddress];
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
            isRegistered[participantAddress],
            "Participant is not registered"
        );

        Participant memory participant = participants[participantAddress];
        string memory roleStr = participant.role == Role.Patient ? "patient" : "hospital";
        return (
            participant.uniqueId,
            participant.name,
            roleStr
        );
    }

    // Function to validate if a unique ID exists
    function isValidUid(address requester, string memory uid)
        public
        view
        returns (bool)
    {
        require(isRegistered[requester], "Not a registered user");
        return uidList[uid];
    }
}