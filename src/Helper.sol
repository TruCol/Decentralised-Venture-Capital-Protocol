// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { CustomPaymentSplitter } from "../src/CustomPaymentSplitter.sol";
error ReachedInvestmentCeiling(uint256 providedVal, string errorMessage);

interface Interface {
  function computeCumRemainingInvestorReturn(
    TierInvestment[] memory tierInvestments
  ) external view returns (uint256 cumRemainingInvestorReturn);

  function getInvestmentCeiling(Tier[] memory tiers) external view returns (uint256 investmentCeiling);

  function isInRange(uint256 minVal, uint256 maxVal, uint256 someVal) external view returns (bool inRange);

  function hasReachedInvestmentCeiling(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
  ) external view returns (bool reachedInvestmentCeiling);

  function computeCurrentInvestmentTier(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
  ) external view returns (Tier currentTier);

  function getRemainingAmountInCurrentTier(
    uint256 cumReceivedInvestments,
    Tier someTier
  ) external view returns (uint256 remainingAmountInTier);

  function computeRemainingInvestorPayout(
    uint256 cumRemainingInvestorReturn,
    uint256 investorFracNumerator,
    uint256 investorFracDenominator,
    uint256 paidAmount
  ) external pure returns (uint256 returneCumRemainingInvestorReturn);
}

contract DecentralisedInvestmentHelper is Interface {
  function computeCumRemainingInvestorReturn(
    TierInvestment[] memory tierInvestments
  ) public view override returns (uint256 cumRemainingInvestorReturn) {
    // Initialise cumRemainingInvestorReturn.
    // cumRemainingInvestorReturn = 0;

    // Sum the returns of all tiers.
    uint256 nrOfTierInvestments = tierInvestments.length;
    for (uint256 i = 0; i < nrOfTierInvestments; ++i) {
      // TODO: assert tierInvestments[i].getRemainingReturn() >= 0.
      cumRemainingInvestorReturn += tierInvestments[i].getRemainingReturn();
    }

    // TODO: assert no integer overflow has occurred.
    return cumRemainingInvestorReturn;
  }

  function getInvestmentCeiling(Tier[] memory tiers) public view override returns (uint256 investmentCeiling) {
    // Access the last tier in the array

    uint256 lastIndex = tiers.length - 1;

    investmentCeiling = tiers[lastIndex].getMaxVal();

    return investmentCeiling;
  }

  function hasReachedInvestmentCeiling(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
  ) public view override returns (bool reachedInvestmentCeiling) {
    reachedInvestmentCeiling = cumReceivedInvestments >= getInvestmentCeiling(tiers);
    return reachedInvestmentCeiling;
  }

  function isInRange(uint256 minVal, uint256 maxVal, uint256 someVal) public pure override returns (bool inRange) {
    if (minVal <= someVal && someVal < maxVal) {
      inRange = true;
    } else {
      inRange = false;
    }
    return inRange;
  }

  function computeCurrentInvestmentTier(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
  ) public view override returns (Tier currentTier) {
    uint256 nrOfTiers = tiers.length;
    require(nrOfTiers > 0, "There were no investmentTiers received.");

    // Check for exceeding investment ceiling.
    if (hasReachedInvestmentCeiling(cumReceivedInvestments, tiers)) {
      revert ReachedInvestmentCeiling(cumReceivedInvestments, "Investment ceiling is reached.");
    }

    // Find the matching tier
    for (uint256 i = 0; i < nrOfTiers; ++i) {
      uint256 minVal = tiers[i].getMinVal();
      uint256 maxVal = tiers[i].getMaxVal();
      if (isInRange(minVal, maxVal, cumReceivedInvestments)) {
        currentTier = tiers[i];
        return currentTier;
      }
    }
    // Should not reach here with valid tiers
    revert(
      string(
        abi.encodePacked(
          "Unexpected state: No matching tier found, the lowest ",
          "investment tier starting point was larger than the ",
          "cumulative received investments. All (Tier) arrays should start at 0."
        )
      )
    );
  }

  function getRemainingAmountInCurrentTier(
    uint256 cumReceivedInvestments,
    Tier someTier
  ) public view override returns (uint256 remainingAmountInTier) {
    // TODO: Add assertion for current tier validation

    // Validate input values
    require(
      someTier.getMinVal() <= cumReceivedInvestments,
      "Error: Tier's minimum value exceeds received investments."
    );
    require(
      someTier.getMaxVal() > cumReceivedInvestments,
      "Error: Tier's maximum value is not larger than received investments."
    );

    // Calculate remaining amount
    remainingAmountInTier = someTier.getMaxVal() - cumReceivedInvestments;
    return remainingAmountInTier;
  }

  function computeRemainingInvestorPayout(
    uint256 cumRemainingInvestorReturn,
    uint256 investorFracNumerator,
    uint256 investorFracDenominator,
    uint256 paidAmount
  ) public pure override returns (uint256 returneCumRemainingInvestorReturn) {
    require(
      investorFracDenominator >= investorFracNumerator,
      "investorFracNumerator is smaller than investorFracDenominator."
    );

    if (cumRemainingInvestorReturn == 0) {
      returneCumRemainingInvestorReturn = 0;
      return returneCumRemainingInvestorReturn;

      // Check if the amount to be paid to the investor is smaller than the
      // amount the investors can receive based on the investorFraction and the
      // incoming SAAS payment amount. If so, just pay out what the investors
      // can receive in whole.
    } else if (cumRemainingInvestorReturn * investorFracDenominator < paidAmount * (investorFracNumerator)) {
      // In this case, the investors fraction of the SAAS payment is more than
      // what they still can get, so just return what they can still receive.
      returneCumRemainingInvestorReturn = cumRemainingInvestorReturn;
      return returneCumRemainingInvestorReturn;
    } else {
      // In this case, there is not enough SAAS payment received to make the
      // investors whole with this single payment, so instead they get their
      // fraction of the SAAS payment.

      // Perform division with roundup to ensure the invstors are paid in whole
      // during their last payout without requiring an additional 1 wei payout.
      uint256 numerator = paidAmount * investorFracNumerator;
      uint256 denominator = investorFracDenominator;
      returneCumRemainingInvestorReturn = numerator / denominator + (numerator % denominator == 0 ? 0 : 1);
      return returneCumRemainingInvestorReturn;
    }
  }

  /**
  TODO: assert the address[] private _withdrawers; is passed by reference, meaning
  it is updated after the function is completed, without returning the value.
  Same for dai.*/

  function initialiseCustomPaymentSplitter(
    address[] memory withdrawers,
    uint256[] memory owedDai,
    address projectLead
  ) public returns (CustomPaymentSplitter customPaymentSplitter) {
    customPaymentSplitter = new CustomPaymentSplitter(withdrawers, owedDai);
    return customPaymentSplitter;
  }

  function isWholeDivision(uint256 withRounding, uint256 roundDown) public pure returns (bool boolIsWholeDivision) {
    boolIsWholeDivision = withRounding != roundDown;
    return boolIsWholeDivision;
  }
}
