// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";

contract MockTier is ITier {
  uint256 public minValOverride;
  uint256 public maxValOverride;
  uint256 public multipleOverride;

  constructor(uint256 _minVal, uint256 _maxVal, uint256 _multiple) {
    minValOverride = _minVal;
    maxValOverride = _maxVal;
    multipleOverride = _multiple;
  }

  function minVal() public view override returns (uint256) {
    return minValOverride;
  }

  function maxVal() public view override returns (uint256) {
    return maxValOverride;
  }

  function multiple() public view override returns (uint256) {
    return multipleOverride;
  }
}
