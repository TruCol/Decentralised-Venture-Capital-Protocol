// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { console2 } from "forge-std/src/console2.sol";

interface ITier {
  function minVal() external view returns (uint256);

  function maxVal() external view returns (uint256);

  function multiple() external view returns (uint256);
}

contract Tier is ITier {
  uint256 public minVal;
  uint256 public maxVal;
  uint256 public multiple;
  address private owner;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(uint256 _minVal, uint256 _maxVal, uint256 _multiple) {
    owner = msg.sender;
    // Improved error message using string concatenation
    string memory errorMessage = string(
      abi.encodePacked("A tier minimum amount should always be 0 or greater. Provided value:")
    );
    // This is a redundant assertion, uint (unsigned) cannot be negative.
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

  function increaseMultiple(uint256 newMultiple) public {
    console2.log("msg.sender in Tier=", msg.sender);
    console2.log("owner=", owner);
    require(msg.sender == owner, "Increasing the Tier object multiple attempted by someone other than project lead.");
    require(newMultiple > multiple, "The new multiple was not larger than the old multiple.");
    multiple = newMultiple;
  }

  function getOwner() public returns (address) {
    return owner;
  }
}
