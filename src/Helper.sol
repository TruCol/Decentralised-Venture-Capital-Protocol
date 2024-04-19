// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { console2 } from "forge-std/src/console2.sol";

contract DecentralisedInvestmentHelper {
  constructor() {}

  function computeCumRemainingInvestorReturn(TierInvestment[] memory tierInvestments) public view returns (uint256) {
    uint256 cumRemainingInvestorReturn = 0;

    for (uint256 i = 0; i < tierInvestments.length; i++) {
      console2.log("tierInvestments[i].remainingReturn()=%s", tierInvestments[i].remainingReturn());

      // TODO: assert tierInvestments[i].remainingReturn() >= 0.
      cumRemainingInvestorReturn += tierInvestments[i].remainingReturn();
    }
    // TODO: assert no integer overvlow has occurred.
    return cumRemainingInvestorReturn;
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

  /**
  @dev Implements the following Python logic:
if cum_remaining_investor_return == 0:
      # Perform transaction and administration towards project lead.
      amount_for_project_lead = paid_amount
  elif cum_remaining_investor_return <= paid_amount * (
      1 - self.project_lead_fraction
  ):
      amount_for_investors = cum_remaining_investor_return
      amount_for_project_lead = (
          paid_amount - cum_remaining_investor_return
      )
  else:
      amount_for_project_lead = paid_amount * self.project_lead_fraction
      amount_for_investors = paid_amount - amount_for_project_lead
  if amount_for_investors + amount_for_project_lead != paid_amount:
      raise ValueError(
          "Error, all the SAAS revenues should be distributed to "
          "investors and project lead."
      )
   */
  function computeRemainingInvestorPayout(
    uint256 cumRemainingInvestorReturn,
    uint256 investorFracNumerator,
    uint256 investorFracDenominator,
    uint256 paidAmount
  ) public view returns (uint256) {
    require(investorFracNumerator >= 0, "investorFracNumerator is smaller than 0.");
    require(investorFracDenominator >= 0, "investorFracDenominator is smaller than 0.");
    require(paidAmount >= 0, "paidAmount is smaller than 0.");
    require(
      investorFracDenominator >= investorFracNumerator,
      "investorFracNumerator is smaller than investorFracNumerator."
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
