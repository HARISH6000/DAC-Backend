const Web3 = require('web3');

// Connect to Ganache
const web3 = new Web3('http://127.0.0.1:8545'); // HTTP is fine for calls/transactions

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

// Account details
const privateKey = '0x9c315ea91c6457728a41b395e6920dc6bb52546f2c375dbe2d059a1008538bc7';
const account = web3.eth.accounts.privateKeyToAccount(privateKey);

// Call the get function
async function callGetFunction() {
    try {
        const result = await contract.methods.get().call();
        console.log('Value of x:', result);
    } catch (error) {
        console.error('Error calling get function:', error);
    }
}

// Call the set function
async function callSetFunction(newValue) {
    try {
        const tx = {
            from: account.address,
            to: contractAddress,
            gas: 200000,
            data: contract.methods.set(newValue).encodeABI(),
        };

        const signedTx = await account.signTransaction(tx);
        const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
        console.log('Set transaction successful. Transaction hash:', receipt.transactionHash);
        return receipt;
    } catch (error) {
        console.error('Error calling set function:', error);
    }
}

// Main execution flow
async function main() {
    console.log('Initial state:');
    await callGetFunction();

    console.log('Setting x');
    await callSetFunction(6);

    console.log('After setting:');
    await callGetFunction();
}

// Run the script
main();

const { ethers } = require("ethers");
const wallet = new ethers.Wallet(privateKey);
const publicKey = wallet.publicKey; // Uncompressed, 0x04 + 64 bytes
console.log("Public Key:", publicKey);
console.log("Address:", wallet.address);