// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Deploy } from "../../script/Deploy.s.sol";

interface ITestHelper {
  function yieldsOverflowAdd(uint256 a, uint256 b) external pure returns (bool);

  function yieldsOverflowMultiply(uint256 a, uint256 b) external pure returns (bool);

  function sumOfNrsThrowsOverFlow(uint256[] memory numbers) external pure returns (bool);
}

contract TestHelper is PRBTest, ITestHelper {
  function sumOfNrsThrowsOverFlow(uint256[] memory numbers) public pure returns (bool) {
    uint256 currentSum = 0; // Initialize current sum to 0

    for (uint256 i = 0; i < numbers.length; ++i) {
      // Check for overflow with the current sum
      if (yieldsOverflowAdd(currentSum, numbers[i])) {
        return true; // Overflow detected, return true
      }
      currentSum = currentSum + numbers[i]; // Update the current sum
    }

    // No overflow detected in the loop
    return false;
  }

  function yieldsOverflowAdd(uint256 a, uint256 b) public pure returns (bool) {
    uint256 typeMax = type(uint256).max;
    uint256 remaining = typeMax - b;
    // TODO: determine whether the = should be included or not.
    return a <= remaining;
  }

  function yieldsOverflowMultiply(uint256 a, uint256 b) public pure returns (bool) {
    // Check for special cases where overflow won't occur
    if (a == 0 || b == 0) {
      return false;
    }

    // Use a more efficient check for common overflow scenario (a > typeMax / b)
    uint256 typeMax = type(uint256).max;
    return a > typeMax / b;
  }
}
