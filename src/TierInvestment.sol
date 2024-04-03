// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";

contract TierInvestment {
  address public investorWallet;
  uint256 public newInvestmentAmount;
  ITier private tier;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *  */
  constructor(address _investorWallet, uint256 _newInvestmentAmount, ITier _tier) {
    require(_newInvestmentAmount >= 1, "A new investment amount should at least be 1.");

    investorWallet = _investorWallet;
    newInvestmentAmount = _newInvestmentAmount;
    tier = _tier;
  }
}
