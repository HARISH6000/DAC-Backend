require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    localnet: {
      url: 'http://127.0.0.1:8545',
      accounts: ['0x4a324aaaf138dce74659cbb138fc61cd60f46170ed0b00fe74e2a9e5e4515a61'] //Replace with account private key
    }
  }
};
