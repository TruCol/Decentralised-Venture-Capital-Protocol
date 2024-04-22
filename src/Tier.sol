// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
error InvalidMinVal(uint256 providedVal, string errorMessage);

interface ITier {
  function increaseMultiple(uint256 newMultiple) external;

  function getMinVal() external view returns (uint256 _minVal);

  function getMaxVal() external view returns (uint256 _maxVal);

  function getMultiple() external view returns (uint256 _multiple);
}

contract Tier is ITier {
  uint256 private _minVal;
  uint256 private _maxVal;
  uint256 private _multiple;
  address private _owner;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(uint256 minVal, uint256 maxVal, uint256 multiple) public {
    _owner = msg.sender;
    // Improved error message using string concatenation
    string memory errorMessage = string(
      abi.encodePacked("A tier minimum amount should always be 0 or greater. Provided value:")
    );
    // This is a redundant assertion, uint (unsigned) cannot be negative.
    // require(minVal >= 0, errorMessage);
    if (minVal < 0) {
      revert InvalidMinVal(minVal, errorMessage);
    }

    require(maxVal > minVal, "The maximum amount should be larger than the minimum.");
    require(multiple > 1, "A ROI multiple should be at larger than 1.");

    // The minVal is public, so you can get it directly from another
    // contract.
    // The _minVal is private, so you cannot access it from another
    // contract.
    _minVal = minVal;
    _maxVal = maxVal;
    _multiple = multiple;
  }

  function increaseMultiple(uint256 newMultiple) public virtual override {
    require(msg.sender == _owner, "Increasing the Tier object multiple attempted by someone other than project lead.");
    require(newMultiple > _multiple, "The new multiple was not larger than the old multiple.");
    _multiple = newMultiple;
  }

  function getMinVal() public view override returns (uint256 minVal) {
    minVal = _minVal;
    return minVal;
  }

  function getMaxVal() public view override returns (uint256 maxVal) {
    maxVal = _maxVal;
    return maxVal;
  }

  function getMultiple() public view override returns (uint256 multiple) {
    multiple = _multiple;
    return multiple;
  }
}
