import { ethers } from 'ethers';

const PRIVATE_KEY = "0x3cb00e847b54f63416d4483c2a926139ecc9a6cad1232f556c8756719996e9b2";
const RPC_URL = "http://127.0.0.1:8545";
const CONTRACT_ADDRESS = "0x030b5cA4A4E6236b6Ebbb2c6815Ae772C2cD4c2F";
const CONTRACT_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "entity", "type": "address" },
            { "internalType": "string[]", "name": "fileHashes", "type": "string[]" },
            { "internalType": "string[]", "name": "keyList", "type": "string[]" }
        ],
        "name": "addKey",
        "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "entity", "type": "address" },
            { "internalType": "string[]", "name": "fileHashes", "type": "string[]" }
        ],
        "name": "doesFilesExist",
        "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "entity", "type": "address" },
            { "internalType": "string[]", "name": "fileHashes", "type": "string[]" }
        ],
        "name": "getKeys",
        "outputs": [{ "internalType": "string[]", "name": "", "type": "string[]" }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{ "internalType": "address[]", "name": "_allowedContract", "type": "address[]" }],
        "name": "setAllowedContract",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, wallet);

async function main() {
    await contract.setAllowedContract([
        "0x185787e1575F6Dc68cD99b8656e7093d15A146D2",
        "0xE3Fef1272E85Fe09bFAb88D4Fee026F6c597C07F"
    ], { gasLimit: 500000 });
    console.log("Allowed contracts set successfully.");
}

main().catch(console.error);
