// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25; // Specifies the Solidity compiler version.
error InvalidMinVal(uint256 providedVal, string errorMessage);

interface Interface {
  function increaseMultiple(uint256 newMultiple) external;

  function getMinVal() external view returns (uint256 _minVal);

  function getMaxVal() external view returns (uint256 _maxVal);

  function getMultiple() external view returns (uint256 _multiple);
}

contract Tier is Interface {
  uint256 private _minVal;
  uint256 private _maxVal;
  uint256 private _multiple;
  address private _owner;

  /**
  @notice Constructor for creating a Tier instance with specified configuration parameters.
  @dev This constructor initializes a Tier instance with the provided minimum value, maximum value, and ROI multiple.
  The values cannot be changed after creation.

  Consecutive Tier objects are expected to have touching maxVal and minVal values respectively.
  @param minVal The minimum investment amount for this tier.
  @param maxVal The maximum investment amount for this tier.
  @param multiple The ROI multiple for this tier.
  */
  // solhint-disable-next-line comprehensive-interface
  constructor(uint256 minVal, uint256 maxVal, uint256 multiple) public {
    _owner = msg.sender;
    // Improved error message using string concatenation
    string memory errorMessage = string(
      abi.encodePacked("A tier minimum amount should always be 0 or greater. Provided value:")
    );

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

  /**
  @notice Increases the ROI multiple for this Tier object.
  @dev This function allows the project lead to increase the ROI multiple for this Tier object. It requires that the
  caller is the owner of the Tier object and that the new integer multiple is larger than the current integer multiple.
  @param newMultiple The new ROI multiple to set for this Tier object.
  */
  function increaseMultiple(uint256 newMultiple) public virtual override {
    require(msg.sender == _owner, "Increasing the Tier object multiple attempted by someone other than project lead.");
    require(newMultiple > _multiple, "The new multiple was not larger than the old multiple.");
    _multiple = newMultiple;
  }

  /**
  @notice This function retrieves the investment starting amount at which this Tier begins.

  @dev This value can be used to determine if the current investment level is in this tier or not.

  @return minVal The minimum allowed value.
  */
  function getMinVal() public view override returns (uint256 minVal) {
    minVal = _minVal;
    return minVal;
  }

  /**
  @notice This function retrieves the investment ceiling amount at which this Tier ends.

  @dev This value can be used to determine if the current investment level is in this tier or not.

  @return maxVal The minimum allowed value.
  */
  function getMaxVal() public view override returns (uint256 maxVal) {
    maxVal = _maxVal;
    return maxVal;
  }

  /**
  @notice This function retrieves the current ROI multiple that is used for all investments that are allocated in this
  Tier.

  @dev This value is used to compute how much  an investor may receive as return on investment. An investment of
  5 ether at a multiple of 6 yields can yield a maximum profit of 25 ether, if sufficient SAAS revenue comes in.

  @return multiple The current multiplication factor.
  */
  function getMultiple() public view override returns (uint256 multiple) {
    multiple = _multiple;
    return multiple;
  }
}
