// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Deploy } from "../../script/Deploy.s.sol";

contract TestDeploy is PRBTest {
  Deploy deploy;

  function setUp() public {
    deploy = new Deploy();
  }

  function testRunTier() public {
    deploy.runTier(); // Call the run0 function to deploy Tier.sol
  }
}
