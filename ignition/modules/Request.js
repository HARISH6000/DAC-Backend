// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

// Import the RegistrationModule
const RegistrationModule = require("./Registration");

module.exports = buildModule("RequestModule", (m) => {
  // Use the Registration contract from RegistrationModule
  const { Registration } = m.useModule(RegistrationModule);

  // Deploy the RequestContract, passing the Registration contract address as an argument
  const Request = m.contract("RequestContract", [Registration]);

  // Return the deployed Request contract
  return { Request };
});