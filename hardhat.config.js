require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    localnet: {
      url: 'http://127.0.0.1:8545',
      accounts: ['0x3cb00e847b54f63416d4483c2a926139ecc9a6cad1232f556c8756719996e9b2'] //Replace with account private key
    }
  }
};
