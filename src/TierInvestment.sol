// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";

contract TierInvestment {
  uint256 public minVal;
  uint256 public maxVal;
  uint256 public multiple;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *  */
  constructor(address investor_wallet, uint256 _newInvestmentAmount, ITier _tier) {}
}
