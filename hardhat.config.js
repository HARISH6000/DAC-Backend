require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    localnet: {
      url: 'http://127.0.0.1:8545',
      accounts: ['0x568cf19a13ad7be03e5adc2976ead55202cd6e0daa86c6160701f69f91b3b167'] //Replace with account private key
    }
  }
};
