// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../../src/Tier.sol";

contract TierTest is PRBTest, StdCheats {
  Tier internal validTier;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the contract-under-test.
    validTier = new Tier(0, 10_000, 10);
  }

  /**
   * Creates a tier object and then raises its value.
   */
  function testTierDirectly() public {
    validTier.increaseMultiple(11);
    assertEq(validTier.multiple(), 11, "The multiple was not 11.");
  }

  function testTierDirectlyWithOtherAddress() public {
    vm.prank(address(1));
    vm.expectRevert(bytes("Increasing the Tier object multiple attempted by someone other than project lead."));
    validTier.increaseMultiple(11);
  }

  function testTierDirectlyEqualMultiple() public {
    vm.expectRevert(bytes("The new multiple was not larger than the old multiple."));
    validTier.increaseMultiple(10);
  }

  function testTierDirectlySmallerMultiple() public {
    vm.expectRevert(bytes("The new multiple was not larger than the old multiple."));
    validTier.increaseMultiple(4);
  }
}
