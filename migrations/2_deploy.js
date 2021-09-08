// migrations/2_deploy.js
// SPDX-License-Identifier: MIT
const PhanerozoicTest = artifacts.require("PhanerozoicTest");

module.exports = function(deployer) {
  deployer.deploy(PhanerozoicTest);
};
