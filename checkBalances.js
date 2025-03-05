const Web3 = require('web3');
const web3 = new Web3("http://127.0.0.1:54600"); // Connect to your Geth RPC endpoint

async function unlockAccount() {
    try {
        await web3.eth.personal.unlockAccount("0x3bb380cd2f80e098044534ef11fef235bb3f3bac", "chintu26", 300);
        console.log("Account unlocked successfully!");
    } catch (error) {
        console.error("Error unlocking account:", error);
    }
}

unlockAccount();
