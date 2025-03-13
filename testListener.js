const Web3 = require('web3');

// Connect to Ganache via WebSocket
const web3 = new Web3('ws://127.0.0.1:8545'); // WebSocket for subscriptions

// Contract details
const contractAddress = '0x5F9fc342f7C9B20F6077c62E4600145c01456c4E';
const contractABI = [
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "address", "name": "", "type": "address"},
            {"indexed": false, "internalType": "uint256", "name": "value", "type": "uint256"}
        ],
        "name": "setted",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "get",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "y", "type": "uint256"}],
        "name": "set",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];

// Initialize the contract
const contract = new web3.eth.Contract(contractABI, contractAddress);

// Listen for setted events in real-time
function listenForEvents() {
    console.log('Starting event listener for setted events...');
    contract.events.setted({
        fromBlock: 'latest'
    })
    .on('data', (event) => {
        console.log('New setted event detected:');
        console.log(`- Sender: ${event.returnValues[0]}`);
        console.log(`- Value: ${event.returnValues.value}`);
        console.log(`- Transaction Hash: ${event.transactionHash}`);
    })
    .on('error', (error) => {
        console.error('Error in event listener:', error);
    });
}

// Main execution flow
function main() {
    listenForEvents();
    console.log('Event listener is running. Trigger set() calls to see events. Press Ctrl+C to stop.');
}

// Run the script
main();