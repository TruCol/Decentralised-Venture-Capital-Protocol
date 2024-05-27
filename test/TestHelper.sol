// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

interface ITestHelper {
  function yieldsOverflowAdd(uint256 a, uint256 b) external pure returns (bool);

  function yieldsOverflowMultiply(uint256 a, uint256 b) external pure returns (bool);

  function sumOfNrsThrowsOverFlow(uint256[] memory numbers) external pure returns (bool);

  function sort_array_large_to_small(uint256[] memory arr_) external returns (uint256[] memory);

  function reverseArray(uint256[] memory arr) external returns (uint256[] memory);
}

contract TestHelper is ITestHelper {
  mapping(uint256 => bool) public Numbers;

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

  function getSortedUniqueArray(uint256[] memory unsortedArrWithDupes) public pure returns (uint256[] memory) {
    unsortedArrWithDupes = removeDuplicates(unsortedArrWithDupes);

    uint256 nrOfUnsortedTiers = unsortedArrWithDupes.length;
    // Store multiples in an array to assert they do not lead to an overflow when computing the investor return.
    uint256[] memory unboundedArr = new uint256[](nrOfUnsortedTiers);
    unsortedArrWithDupes = sort_array_large_to_small(unsortedArrWithDupes);
    unsortedArrWithDupes = reverseArray(unsortedArrWithDupes);
    for (uint256 i = 1; i < nrOfUnsortedTiers; ++i) {
      require(unsortedArrWithDupes[i - 1] < unsortedArrWithDupes[i], "Error, two elems were equal or not increasing.");
    }
    return unsortedArrWithDupes;
  }

  function sort_array_large_to_small(uint256[] memory arr_) public pure returns (uint256[] memory) {
    uint256 l = arr_.length;
    uint256[] memory arr = new uint256[](l);

    for (uint256 i = 0; i < l; i++) {
      arr[i] = arr_[i];
    }

    for (uint256 i = 0; i < l; i++) {
      for (uint256 j = i + 1; j < l; j++) {
        if (arr[i] < arr[j]) {
          uint256 temp = arr[j];
          arr[j] = arr[i];
          arr[i] = temp;
        }
      }
    }

    return arr;
  }

  function reverseArray(uint256[] memory arr) public pure returns (uint256[] memory) {
    uint256 left = 0;
    uint256 right = arr.length - 1;

    while (left < right) {
      uint256 temp = arr[left];
      arr[left] = arr[right];
      arr[right] = temp;
      left++;
      right--;
    }

    return arr;
  }

  function contains(uint256[] memory arr, uint256 x) public pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == x) {
        return true;
      }
    }
    return false;
  }

  function removeDuplicates(uint256[] memory arr) public pure returns (uint256[] memory) {
    uint256[] memory temp = new uint256[](arr.length);
    uint256 counter = 0;
    for (uint256 i = 0; i < arr.length; i++) {
      if (!contains(temp, arr[i])) {
        temp[counter] = arr[i];
        counter++;
      }
    }
    uint256[] memory arrWithUniqueVals = new uint256[](counter);
    for (uint256 i = 0; i < counter; i++) {
      arrWithUniqueVals[i] = temp[i];
    }
    return arrWithUniqueVals;
  }

  function maximum(uint256 a, uint256 b) public pure returns (uint256 maxVal) {
    maxVal = a > b ? a : b;
    return maxVal;
  }
}
