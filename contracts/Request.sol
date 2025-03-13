// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the Registration contract to avoid direct dependency
interface IRegistration {
    function isParticipantRegistered(address participant) external view returns (bool);
    function getParticipantDetails(address participant) external view returns (string memory uniqueId, string memory name, string memory role);
}

contract RequestContract {
    // Enum for access types (same as in AccessControlContract)
    enum AccessType { Read, Write, Both }

    // Struct to hold request details
    struct Request {
        uint requestId;
        address hospital;
        address patient;
        string[] fileList;
        uint deadline;
        AccessType accessType;
        bool isProcessed;
    }

    // Global mapping of all requests by requestId
    mapping(uint => Request) public requests;

    // Counter for generating unique request IDs
    uint public requestCounter;

    // Mapping of request IDs for each patient (to allow patients to view requests)
    mapping(address => uint[]) private patientRequestIds;

    // Mapping of request IDs for each hospital (to allow hospitals to view their requests)
    mapping(address => uint[]) private hospitalRequestIds;

    // Reference to the Registration contract
    IRegistration public registration;

    // Event emitted when a request is made
    event RequestMade(
        uint indexed requestId,
        address indexed patient,
        address indexed hospital,
        string[] fileList,
        uint deadline,
        AccessType accessType,
        bool isProcessed
    );

    // Constructor to set the Registration contract address
    constructor(address _registration) {
        registration = IRegistration(_registration);
        requestCounter = 0;
    }

    // Function for hospitals to make a request
    function makeRequest(
        address patient,
        string[] memory fileList,
        uint deadline,
        AccessType accessType
    ) external returns (uint) {
        // Verify the caller is a registered hospital
        require(registration.isParticipantRegistered(msg.sender), "Caller must be a registered participant");
        (,, string memory callerRole) = registration.getParticipantDetails(msg.sender);
        require(
            keccak256(abi.encodePacked(callerRole)) == keccak256(abi.encodePacked("hospital")),
            "Caller must be a hospital"
        );

        // Verify the target patient is a registered patient
        require(registration.isParticipantRegistered(patient), "Patient must be a registered participant");
        (,, string memory patientRole) = registration.getParticipantDetails(patient);
        require(
            keccak256(abi.encodePacked(patientRole)) == keccak256(abi.encodePacked("patient")),
            "Target must be a patient"
        );

        // Generate a new request ID
        requestCounter++;
        uint newRequestId = requestCounter;

        // Create the Request struct
        Request memory newRequest = Request({
            requestId: newRequestId,
            hospital: msg.sender,
            patient: patient,
            fileList: fileList,
            deadline: deadline,
            accessType: accessType,
            isProcessed: false
        });

        // Store the request
        requests[newRequestId] = newRequest;

        // Add the request ID to the patient's and hospital's lists
        patientRequestIds[patient].push(newRequestId);
        hospitalRequestIds[msg.sender].push(newRequestId);

        // Emit the RequestMade event
        emit RequestMade(
            newRequestId,
            patient,
            msg.sender,
            fileList,
            deadline,
            accessType,
            false
        );

        return newRequestId;
    }

    // Function for patients to view all requests made for them
    function getPatientRequests() external view returns (Request[] memory) {
        // Verify the caller is a registered patient
        require(registration.isParticipantRegistered(msg.sender), "Caller must be a registered participant");
        (,, string memory callerRole) = registration.getParticipantDetails(msg.sender);
        require(
            keccak256(abi.encodePacked(callerRole)) == keccak256(abi.encodePacked("patient")),
            "Caller must be a patient"
        );

        // Get the list of request IDs for the patient
        uint[] memory requestIds = patientRequestIds[msg.sender];
        Request[] memory patientRequests = new Request[](requestIds.length);

        // Retrieve each request
        for (uint i = 0; i < requestIds.length; i++) {
            patientRequests[i] = requests[requestIds[i]];
        }

        return patientRequests;
    }

    // Function for hospitals to view all requests they have made
    function getHospitalRequests() external view returns (Request[] memory) {
        // Verify the caller is a registered hospital
        require(registration.isParticipantRegistered(msg.sender), "Caller must be a registered participant");
        (,, string memory callerRole) = registration.getParticipantDetails(msg.sender);
        require(
            keccak256(abi.encodePacked(callerRole)) == keccak256(abi.encodePacked("hospital")),
            "Caller must be a hospital"
        );

        // Get the list of request IDs for the hospital
        uint[] memory requestIds = hospitalRequestIds[msg.sender];
        Request[] memory hospitalRequests = new Request[](requestIds.length);

        // Retrieve each request
        for (uint i = 0; i < requestIds.length; i++) {
            hospitalRequests[i] = requests[requestIds[i]];
        }

        return hospitalRequests;
    }

    // Helper function to retrieve a request by ID
    function getRequest(uint requestId) external view returns (Request memory) {
        require(requestId > 0 && requestId <= requestCounter, "Invalid request ID");
        return requests[requestId];
    }

    // Helper function to mark a request as processed
    function setRequestProcessed(uint requestId) external {
        require(requestId > 0 && requestId <= requestCounter, "Invalid request ID");
        Request storage req = requests[requestId];
        // Add access control if needed (e.g., only callable by AccessControlContract)
        require(!req.isProcessed, "Request already processed");
        req.isProcessed = true;
    }
}