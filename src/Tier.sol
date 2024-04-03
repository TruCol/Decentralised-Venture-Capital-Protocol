// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

contract Tier {
  uint256 public minVal;
  uint256 public maxVal;
  uint256 public multiple;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *  */
  constructor(uint256 _minVal, uint256 _maxVal, uint256 _multiple) {
    // Improved error message using string concatenation
    string memory errorMessage = string(
      abi.encodePacked("A tier minimum amount should always be 0 or greater. Provided value:")
    );
    require(_minVal >= 0, errorMessage);
    require(_maxVal > _minVal, "The maximum amount should be larger than the minimum.");
    require(_multiple > 1, "A ROI multiple should be at larger than 1.");

    // The minVal is public, so you can get it directly from another
    // contract.
    // The _minVal is private, so you cannot access it from another
    // contract.
    minVal = _minVal;
    maxVal = _maxVal;
    multiple = _multiple;
  }
}
