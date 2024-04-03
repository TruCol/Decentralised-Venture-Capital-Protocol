// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

// import "truffle/Assert.sol"; // Assuming Truffle for testing framework
// import "truffle/Assert.sol"; // Assuming Truffle for testing framework
// import "forge-std/Test.sol"; // Import Forge's testing functionalities

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
  function testAttributes() public {
    assertEq(validTier.minVal(), 0, "The minVal was not as expected");
    assertEq(validTier.maxVal(), 10000, "The maxVal was not as expected");
    assertEq(validTier.multiple(), 10, "The multiple was not as expected.");
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
  function testThrowsOnMaxValLargerThanMinVal() public {
    // Act (call the function that might throw)
    bool didThrow;
    // Pass invalid maxVal 9 which is smaller than minVal (10)
    try new Tier(10, 9, 11) {
      // Reaching this statement means the constructor did not throw an error.
      didThrow = false;
    } catch Error(string memory reason) {
      didThrow = true;
      assertEq(reason, "The maximum amount should be larger than the minimum.");
    } catch (bytes memory) {
      // Catch unexpected exceptions.
      didThrow = true;
    }

    // Assert (verify the expected outcome)
    assert(didThrow);
  }

  /**
   * Test the tier object throws an error if the multiple is 1 or smaller.
   */
  function testThrowsOnZeroMultiple() public {
    // Act (call the function that might throw)
    bool didThrow;
    // Pass invalid multiple (0)
    try new Tier(2, 9, 0) {
      // Reaching this statement means the constructor did not throw an error.
      didThrow = false;
    } catch Error(string memory reason) {
      didThrow = true;
      // You can use Forge's assertEq for string comparison.
      assertEq(reason, "A ROI multiple should be at larger than 1.");
    } catch (bytes memory) {
      // Catch unexpected exceptions.
      didThrow = true;
    }

    // Assert (verify the expected outcome)
    assert(didThrow);
  }

  /**
   * The only possible values for which the multiple can fail are 0 and 1,
   * because it is an unsigned integer, which means it is 0 or positive and
   * an integer. So the smallest two values are 0 and 1, after that the
   * multiple is large enough.
   */
  function testThrowsOnOneMultiple() public {
    // Act (call the function that might throw)
    bool didThrow;
    // Pass invalid multiple (1)
    try new Tier(2, 9, 1) {
      // Reaching this statement means the constructor did not throw an error.
      didThrow = false;
    } catch Error(string memory reason) {
      didThrow = true;
      // You can use Forge's assertEq for string comparison.
      assertEq(reason, "A ROI multiple should be at larger than 1.");
    } catch (bytes memory) {
      // Catch unexpected exceptions
      didThrow = true;
    }

    // Assert (verify the expected outcome)
    assert(didThrow);
  }
}
