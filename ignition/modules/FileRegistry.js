const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("FileRegistryModule", (m) => {
  const FileRegistry = m.contract("FileRegistry", []);

  return { FileRegistry };
});