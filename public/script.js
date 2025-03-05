// const Web3 = require('web3'); // Uncomment if using Node.js environment

// Check if MetaMask is installed
if (typeof window.ethereum !== 'undefined') {
  console.log('MetaMask is installed!');
} else {
  alert('Please install MetaMask to use this DApp!');
}

// Connect to MetaMask's provider
const web3 = new Web3(window.ethereum);

// Replace with your contract's ABI
const contractABI = [
  {
    "inputs": [],
    "name": "fav",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "pure",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "get",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "x",
        "type": "uint256"
      }
    ],
    "name": "set",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

// Replace with your deployed contract's address
const contractAddress = '0x38b80E72d1a223d07b23D00364a32b7A0f28F239';

// Create contract instance
const contract = new web3.eth.Contract(contractABI, contractAddress);

// Connection status element
const connectionStatus = document.getElementById('connection-status');

// Function to connect to MetaMask and get accounts
async function connectMetaMask() {
  try {
    // Request account access
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    console.log('Connected accounts:', accounts);

    // Update connection status
    connectionStatus.innerText = `Connected to MetaMask: ${accounts[0]}`;
    connectionStatus.style.color = 'green';

    return accounts[0]; // Return the first account
  } catch (error) {
    console.error('Error connecting to MetaMask:', error);
    connectionStatus.innerText = 'Error connecting to MetaMask. Please try again.';
    connectionStatus.style.color = 'red';
    return null;
  }
}

// Function to store a value
async function setString(value) {
  try {
    const account = await connectMetaMask(); // Connect to MetaMask and get the account
    if (!account) return;

    // Send transaction to the contract
    await contract.methods.set(value).send({ from: account });
    console.log('Value set successfully');
  } catch (error) {
    console.error('Error setting value:', error);
  }
}

// Function to retrieve a value
async function getString() {
  //const networkId = await web3.eth.net.getId();
  //console.log('Connected network ID:', networkId);
  //const isSyncing = await web3.eth.isSyncing();
  //console.log('Node syncing status:', isSyncing);
  
  try {
    //const code = await web3.eth.getCode(contractAddress);
    //console.log('Contract code at address:', code);

    //console.log('Contract instance:', contract);
    console.log('Calling get() function...');
    const result = await contract.methods.get().call();
    console.log('Retrieved value:', result);
    document.getElementById('output').innerText = result;
  } catch (error) {
    console.error('Error retrieving value:', error);
  }
}

async function favString(){
  const result = await contract.methods.fav().call();
  document.getElementById('output').innerText = result;
}

// Event listeners for buttons
document.getElementById('getButton').addEventListener('click', getString);
document.getElementById('favButton').addEventListener('click', favString);
document.getElementById('putButton').addEventListener('click', () => {
  const value = document.getElementById('inputString').value;
  setString(value);
});

// Connect to MetaMask when the page loads
connectMetaMask();