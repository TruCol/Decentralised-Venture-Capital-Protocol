// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { Tier } from "../src/Tier.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
  function runTier() public broadcast returns (Tier tier) {
    tier = new Tier(address(0), 0, 10_000, 10);
  }
}
