// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../src/Tier.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract TierTest is PRBTest, StdCheats {
  Tier internal validTier;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the contract-under-test.
    validTier = new Tier(0, 10000, 10);
  }

  /**
   * Test the tier object can be created with valid values, and that its public
   * parameters are available, and that its private parameters are not
   * available.
   *
   */
  function testMinVal() public {
    assertEq(validTier.minVal(), 0);
    assertEq(validTier.maxVal(), 10000);
    assertEq(validTier.multiple(), 10);
  }
  /**
   * Test the tier object throws an error if the minimum is smaller than 0.
   */

  /**
   * Test the tier object throws an error if the maxValue is larger than the minValue.
   */

  /**
   * Test the tier object throws an error if the multiple is 1 or smaller.
   */
}
