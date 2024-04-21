// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../../src/Tier.sol";

interface Interface {
  function setUp() external;

  function testTierDirectly() external;
}

contract TierTest is PRBTest, StdCheats, Interface {
  Tier internal _validTier;

  /// @dev A function invoked before each test case is run.
  function setUp() public override {
    // Instantiate the contract-under-test.
    _validTier = new Tier(0, 10_000, 10);
  }

  /**
   * Creates a tier object and then raises its value.
   */
  function testTierDirectly() public override {
    _validTier.increaseMultiple(11);
    assertEq(_validTier.multiple(), 11, "The multiple was not 11.");
  }

  function testTierDirectlyWithOtherAddress() public {
    vm.prank(address(1));
    vm.expectRevert(bytes("Increasing the Tier object multiple attempted by someone other than project lead."));
    _validTier.increaseMultiple(11);
  }

  function testTierDirectlyEqualMultiple() public {
    vm.expectRevert(bytes("The new multiple was not larger than the old multiple."));
    _validTier.increaseMultiple(10);
  }

  function testTierDirectlySmallerMultiple() public {
    vm.expectRevert(bytes("The new multiple was not larger than the old multiple."));
    _validTier.increaseMultiple(4);
  }
}
