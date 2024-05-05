// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { Tier } from "../src/Tier.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
  function runTier() public broadcast returns (Tier tier) {
    tier = new Tier(0, 10_000, 10);
  }

  // To make forge coverage skip this file.
  // solhint-disable-next-line no-empty-blocks
  function test() public override {}
}
