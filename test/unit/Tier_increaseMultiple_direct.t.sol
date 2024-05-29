// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;
import { console2 } from "forge-std/src/console2.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../../src/Tier.sol";

error ReachedInvestmentCeiling(uint256 providedVal, string errorMessage);

interface ITierTest {
  function setUp() external;

  function testTierDirectly() external;

  function testTierDirectlyWithOtherAddress() external;

  function testTierDirectlyEqualMultiple() external;

  function testTierDirectlySmallerMultiple() external;
}

contract TierTest is PRBTest, StdCheats, ITierTest {
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
    assertEq(_validTier.getMultiple(), 11, "The multiple was not 11.");
  }

  function testTierDirectlyWithOtherAddress() public override {
    vm.prank(address(1));
    vm.expectRevert(
      abi.encodeWithSignature(
        "MultipleIncreaseByOtherThanOwner(string,address,address)",
        "Only owner can increase ROI multiple.",
        address(1),
        address(this)
      )
    );
    _validTier.increaseMultiple(11);
  }

  function testTierDirectlyEqualMultiple() public override {
    vm.expectRevert(
      abi.encodeWithSignature("DecreasingMultiple(string,uint256,uint256)", "Can only increase ROI multiple.", 10, 10)
    );
    _validTier.increaseMultiple(10);
  }

  function testTierDirectlySmallerMultiple() public override {
    vm.expectRevert(
      abi.encodeWithSignature("DecreasingMultiple(string,uint256,uint256)", "Can only increase ROI multiple.", 10, 4)
    );
    _validTier.increaseMultiple(4);
  }
}
