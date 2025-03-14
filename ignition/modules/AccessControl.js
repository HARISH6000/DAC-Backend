const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const RequestModule = require("./Request");
const FileRegistryModule = require("./FileRegistry");

module.exports = buildModule("AccessControlModule", (m) => {
  const { Request } = m.useModule(RequestModule);
  const { FileRegistry } = m.useModule(FileRegistryModule);
  const AccessControl = m.contract("AccessControlContract", [Request,FileRegistry]);

  return { AccessControl };
});