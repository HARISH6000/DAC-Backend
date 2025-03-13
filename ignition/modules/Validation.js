const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const RegistrationModule = require("./Registration");
const AccessControlModule = require("./AccessControl");
const FileRegistryModule = require("./FileRegistry");

module.exports = buildModule("ValidationModule", (m) => {
  const { Registration } = m.useModule(RegistrationModule);
  const { AccessControl } = m.useModule(AccessControlModule);
  const { FileRegistry } = m.useModule(FileRegistryModule);

  const Validation = m.contract("ValidationContract", [Registration, AccessControl, FileRegistry]);

  return { Validation };
});