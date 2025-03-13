const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const RequestModule = require("./Request");

module.exports = buildModule("AccessControlModule", (m) => {
  const { Request } = m.useModule(RequestModule);

  const AccessControl = m.contract("AccessControlContract", [Request]);

  return { AccessControl };
});