// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../../src/Tier.sol";

interface ITierTest {
  function setUp() external;

  function testAttributes() external;

  function testThrowsOnMaxValLargerThanMinVal() external;

  function testThrowsOnZeroMultiple() external;

  function testThrowsOnOneMultiple() external;
}

contract TierTest is PRBTest, StdCheats, ITierTest {
  Tier internal _validTier;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Instantiate the contract-under-test.
    _validTier = new Tier(0, 10_000, 10);
  }

  /**
   * Test the tier object can be created with valid values, and that its public
   * parameters are available, and that its private parameters are not
   * available.
   *
   */
  function testAttributes() public override {
    assertEq(_validTier.getMinVal(), 0, "The minVal was not as expected");
    assertEq(_validTier.getMaxVal(), 10_000, "The maxVal was not as expected");
    assertEq(_validTier.getMultiple(), 10, "The multiple was not as expected.");
  }

  /**
   * Test the tier object throws an error if the minimum is smaller than 0.
   * This test is ignored, because the Tier object takes in a uint256, which
   * stands for unsigned integer, which means there is no + or - sign before
   * the 256 bits of value, meaning it is always positive, so it is not
   * possible to pass it a negative value.
   */

  /**
   * Test the tier object throws an error if the maxValue is larger than the minValue.
   */
  function testThrowsOnMaxValLargerThanMinVal() public override {
    vm.expectRevert(
      abi.encodeWithSignature("TierMinNotBelowMax(string,uint256,uint256)", "Tier's min not below tier max.", 10, 9)
    );
    new Tier(10, 9, 11);
  }

  /**
   * Test the tier object throws an error if the multiple is 1 or smaller.
   */
  function testThrowsOnZeroMultiple() public override {
    vm.expectRevert(
      abi.encodeWithSignature("MultipleTooSmall(string,uint256)", "ROI multiple should be larger than 1.", 0)
    );
    new Tier(2, 9, 0);
  }

  /**
   * The only possible values for which the multiple can fail are 0 and 1,
   * because it is an unsigned integer, which means it is 0 or positive and
   * an integer. So the smallest two values are 0 and 1, after that the
   * multiple is large enough.
   */
  function testThrowsOnOneMultiple() public override {
    vm.expectRevert(
      abi.encodeWithSignature("MultipleTooSmall(string,uint256)", "ROI multiple should be larger than 1.", 1)
    );
    new Tier(2, 9, 1);
  }
}
