// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";

contract DecentralisedInvestmentHelper {
  constructor() {}

  function computeCumRemainingInvestorReturn(TierInvestment[] memory tier_investments) public view returns (uint256) {
    uint256 cumRemainingInvestorReturn = 0;
    for (uint256 i = 0; i < tier_investments.length; i++) {
      // TODO: assert tier_investments[i].remainingReturn() >= 0.
      cumRemainingInvestorReturn += tier_investments[i].remainingReturn();
    }
    // TODO: assert no integer overvlow has occurred.
    return cumRemainingInvestorReturn;
  }

  function aTimesBOverC(uint256 a, uint256 b, uint256 c) public pure returns (uint256) {
    uint256 multiplication = a * b;
    uint256 output = multiplication / c;
    return output;
  }

  function aTimes1MinusBOverC(uint256 a, uint256 b, uint256 c) public pure returns (uint256) {
    // Substitute 1 = c/c and then get the c "buiten haakjes".
    // 1-b/c = c/c - b/c = (c-b)/c
    uint256 fraction = (c - b) / c;
    uint256 output = a * fraction;
    return output;
  }
}
