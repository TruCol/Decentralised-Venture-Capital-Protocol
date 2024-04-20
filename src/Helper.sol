// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";

interface Interface {
  function computeCumRemainingInvestorReturn(
    TierInvestment[] memory tierInvestments
  ) external view returns (uint256 cumRemainingInvestorReturn);

  function getInvestmentCeiling(Tier[] memory tiers) external view returns (uint256 investmentCeiling);
}

contract DecentralisedInvestmentHelper is Interface {
  function computeCumRemainingInvestorReturn(
    TierInvestment[] memory tierInvestments
  ) public view override returns (uint256 cumRemainingInvestorReturn) {
    cumRemainingInvestorReturn = 0;
    uint256 nrOfTierInvestments = tierInvestments.length;
    for (uint256 i = 0; i < nrOfTierInvestments; ++i) {
      // TODO: assert tierInvestments[i].remainingReturn() >= 0.
      cumRemainingInvestorReturn += tierInvestments[i].remainingReturn();
    }
    // TODO: assert no integer overvlow has occurred.
    return cumRemainingInvestorReturn;
  }

  function getInvestmentCeiling(Tier[] memory tiers) public view override returns (uint256 investmentCeiling) {
    // Access the last tier in the array

    uint256 lastIndex = tiers.length - 1;

    investmentCeiling = tiers[lastIndex].maxVal();

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

    require(!hasReachedInvestmentCeiling(cumReceivedInvestments, tiers), "Investment ceiling is reached.");

    // Find the matching tier
    for (uint256 i = 0; i < tiers.length; ++i) {
      if (tiers[i].minVal() <= cumReceivedInvestments && cumReceivedInvestments < tiers[i].maxVal()) {
        return tiers[i];
      }
    }
    // Should not reach here with valid tiers
    revert(
      "Unexpected state: No matching tier found, the lowest investment tier starting point was larger than the cumulative received investments. All (Tier) arrays should start at 0."
    );
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

  function computeRemainingInvestorPayout(
    uint256 cumRemainingInvestorReturn,
    uint256 investorFracNumerator,
    uint256 investorFracDenominator,
    uint256 paidAmount
  ) public pure returns (uint256) {
    require(
      investorFracDenominator >= investorFracNumerator,
      "investorFracNumerator is smaller than investorFracDenominator."
    );

    if (cumRemainingInvestorReturn == 0) {
      return 0;

      // Check if the amount to be paid to the investor is smaller than the
      // amount the investors can receive based on the investorFraction and the
      // incoming SAAS payment amount. If so, just pay out what the investors
      // can receive in whole.
    } else if (cumRemainingInvestorReturn * investorFracDenominator < paidAmount * (investorFracNumerator)) {
      // In this case, the investors fraction of the SAAS payment is more than
      // what they still can get, so just return what they can still receive.
      return cumRemainingInvestorReturn;
    } else {
      // In this case, there is not enough SAAS payment received to make the
      // investors whole with this single payment, so instead they get their
      // fraction of the SAAS payment.

      // Perform division with roundup to ensure the invstors are paid in whole
      // during their last payout without requiring an additional 1 wei payout.
      uint256 numerator = paidAmount * investorFracNumerator;
      uint256 denominator = investorFracDenominator;
      return numerator / denominator + (numerator % denominator == 0 ? 0 : 1);
    }
  }
}
