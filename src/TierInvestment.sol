// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";

contract TierInvestment {
  address public investor;
  uint256 public newInvestmentAmount;
  ITier private tier;

  /** The amount of DAI that is still to be returned for this investment. */
  uint256 public remainingReturn;

  /** The amount of DAI that the investor can collect as ROI. */
  uint256 public collectivleReturn;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *  */
  constructor(address _investor, uint256 _newInvestmentAmount, ITier _tier) {
    require(_newInvestmentAmount >= 1, "A new investment amount should at least be 1.");

    investor = _investor;
    newInvestmentAmount = _newInvestmentAmount;
    tier = _tier;
  }
}
