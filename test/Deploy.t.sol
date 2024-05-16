// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Deploy } from "../../script/Deploy.s.sol";

interface Interface {
  function setUp() external;

  function testRunTier() external;
}

contract TestDeploy is PRBTest, Interface {
  Deploy private _deploy;

  function setUp() public override {
    _deploy = new Deploy();
  }

  function testRunTier() public override {
    _deploy.runTier(); // Call the run0 function to deploy Tier.sol
  }
}
