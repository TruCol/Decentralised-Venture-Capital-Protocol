// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { console2 } from "forge-std/src/console2.sol";
import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";

contract DecentralisedInvestmentHelper {
  constructor() {}

  function computeCumRemainingInvestorReturn(TierInvestment[] memory tierInvestments) public view returns (uint256) {
    uint256 cumRemainingInvestorReturn = 0;

    for (uint256 i = 0; i < tierInvestments.length; i++) {
      // TODO: assert tierInvestments[i].remainingReturn() >= 0.
      cumRemainingInvestorReturn += tierInvestments[i].remainingReturn();
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

  function getInvestmentCeiling(Tier[] memory tiers) public view returns (uint256) {
    // Access the last tier in the array

    uint256 lastIndex = tiers.length - 1;

    uint256 investmentCeiling = tiers[lastIndex].maxVal();

    return investmentCeiling;
  }

  function hasReachedInvestmentCeiling(uint256 cumReceivedInvestments, Tier[] memory tiers) public view returns (bool) {
    return cumReceivedInvestments >= getInvestmentCeiling(tiers);
  }

  function computeCurrentInvestmentTier(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
  ) public view returns (Tier) {
    // Check for exceeding investment ceiling.

    require(!hasReachedInvestmentCeiling(cumReceivedInvestments, tiers));

    // Validate positive investment amount.
    require(cumReceivedInvestments >= 0, "Error: Negative investments not allowed.");

    // Find the matching tier
    for (uint256 i = 0; i < tiers.length; i++) {
      if (tiers[i].minVal() <= cumReceivedInvestments && cumReceivedInvestments < tiers[i].maxVal()) {
        return tiers[i];
      }
    }
    // Should not reach here with valid tiers
    revert("Unexpected state: No matching tier found.");
  }

  function getRemainingAmountInCurrentTier(
    uint256 cumReceivedInvestments,
    Tier currentTier
  ) public view returns (uint256) {
    // TODO: Add assertion for current tier validation

    // Validate input values
    require(
      currentTier.minVal() <= cumReceivedInvestments,
      "Error: Tier's minimum value exceeds received investments."
    );
    require(
      currentTier.maxVal() > cumReceivedInvestments,
      "Error: Tier's maximum value is not larger than received investments."
    );

    // Calculate remaining amount
    return currentTier.maxVal() - cumReceivedInvestments;
  }
}
