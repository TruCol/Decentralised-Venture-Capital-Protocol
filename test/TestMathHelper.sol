// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

interface ITestMathHelper {
  function sumOfNrsThrowsOverFlow(uint256[] memory numbers) external pure returns (bool cumArrSumYieldsOverflow);

  function yieldsOverflowAdd(uint256 a, uint256 b) external pure returns (bool yieldsOverflowInAddition);

  function yieldsOverflowMultiply(uint256 a, uint256 b) external pure returns (bool yieldsOverFlowInMultiplication);

  function getSortedUniqueArray(
    uint256[] memory unsortedArrWithDupes
  ) external pure returns (uint256[] memory sortedArrWithDupes);

  function sortArrahLargeToSmall(
    uint256[] memory unsortedArray
  ) external pure returns (uint256[] memory sortedArrayLargeToSmall);

  function reverseArray(uint256[] memory arr) external pure returns (uint256[] memory reversedArray);

  function contains(uint256[] memory arr, uint256 x) external pure returns (bool arrContainsVal);

  function removeDuplicates(uint256[] memory arr) external pure returns (uint256[] memory arrWithUniqueVals);

  function maximum(uint256 a, uint256 b) external pure returns (uint256 maxVal);
}

contract TestMathHelper is ITestMathHelper {
  function sumOfNrsThrowsOverFlow(
    uint256[] memory numbers
  ) public pure override returns (bool cumArrSumYieldsOverflow) {
    cumArrSumYieldsOverflow = false;
    uint256 currentSum = 0; // Initialize current sum to 0
    uint256 nrOfNumbers = numbers.length;
    for (uint256 i = 0; i < nrOfNumbers; ++i) {
      // Check for overflow with the current sum
      if (yieldsOverflowAdd(currentSum, numbers[i])) {
        cumArrSumYieldsOverflow = true; // Overflow detected, return true
      }
      currentSum = currentSum + numbers[i]; // Update the current sum
    }

    return cumArrSumYieldsOverflow;
  }

  function yieldsOverflowAdd(uint256 a, uint256 b) public pure override returns (bool yieldsOverflowInAddition) {
    uint256 typeMax = type(uint256).max;
    uint256 remaining = typeMax - b;
    // TODO: determine whether the = should be included or not.
    yieldsOverflowInAddition = (a <= remaining);
    return yieldsOverflowInAddition;
  }

  function yieldsOverflowMultiply(
    uint256 a,
    uint256 b
  ) public pure override returns (bool yieldsOverFlowInMultiplication) {
    // Check for special cases where overflow won't occur
    if (a == 0 || b == 0) {
      yieldsOverFlowInMultiplication = false;
    }

    // Use a more efficient check for common overflow scenario (a > typeMax / b)
    uint256 typeMax = type(uint256).max;
    yieldsOverFlowInMultiplication = a > typeMax / b;
    return yieldsOverFlowInMultiplication;
  }

  function getSortedUniqueArray(
    uint256[] memory unsortedArrWithDupes
  ) public pure override returns (uint256[] memory sortedArrWithDupes) {
    sortedArrWithDupes = removeDuplicates(unsortedArrWithDupes);

    uint256 nrOfUnsortedTiers = sortedArrWithDupes.length;
    // Store multiples in an array to assert they do not lead to an overflow when computing the investor return.
    sortedArrWithDupes = sortArrahLargeToSmall(sortedArrWithDupes);
    sortedArrWithDupes = reverseArray(sortedArrWithDupes);
    for (uint256 i = 1; i < nrOfUnsortedTiers; ++i) {
      require(sortedArrWithDupes[i - 1] < sortedArrWithDupes[i], "Error, two elems were equal or not increasing.");
    }
    return sortedArrWithDupes;
  }

  function sortArrahLargeToSmall(
    uint256[] memory unsortedArray
  ) public pure override returns (uint256[] memory sortedArrayLargeToSmall) {
    uint256 nrOfElements = unsortedArray.length;
    sortedArrayLargeToSmall = new uint256[](nrOfElements);

    for (uint256 i = 0; i < nrOfElements; ++i) {
      sortedArrayLargeToSmall[i] = unsortedArray[i];
    }

    for (uint256 i = 0; i < nrOfElements; ++i) {
      for (uint256 j = i + 1; j < nrOfElements; ++j) {
        if (sortedArrayLargeToSmall[i] < sortedArrayLargeToSmall[j]) {
          uint256 temp = sortedArrayLargeToSmall[j];
          sortedArrayLargeToSmall[j] = sortedArrayLargeToSmall[i];
          sortedArrayLargeToSmall[i] = temp;
        }
      }
    }

    return sortedArrayLargeToSmall;
  }

  function reverseArray(uint256[] memory arr) public pure override returns (uint256[] memory reversedArray) {
    uint256 nrOfElements = arr.length;
    reversedArray = new uint256[](nrOfElements);
    for (uint256 i = 0; i < nrOfElements; ++i) {
      reversedArray[nrOfElements - 1 - i] = arr[i];
    }
    return reversedArray;
  }

  function contains(uint256[] memory arr, uint256 x) public pure override returns (bool arrContainsVal) {
    uint256 nrOfElements = arr.length;
    arrContainsVal = false;
    for (uint256 i = 0; i < nrOfElements; ++i) {
      if (arr[i] == x) {
        arrContainsVal = true;
      }
    }

    return arrContainsVal;
  }

  function removeDuplicates(uint256[] memory arr) public pure override returns (uint256[] memory arrWithUniqueVals) {
    uint256 nrOfElements = arr.length;
    uint256[] memory temp = new uint256[](nrOfElements);
    uint256 counter = 0;
    for (uint256 i = 0; i < nrOfElements; ++i) {
      if (!contains(temp, arr[i])) {
        temp[counter] = arr[i];
        ++counter;
      }
    }
    arrWithUniqueVals = new uint256[](counter);
    for (uint256 i = 0; i < counter; ++i) {
      arrWithUniqueVals[i] = temp[i];
    }
    return arrWithUniqueVals;
  }

  function maximum(uint256 a, uint256 b) public pure override returns (uint256 maxVal) {
    maxVal = a > b ? a : b;
    return maxVal;
  }
}
