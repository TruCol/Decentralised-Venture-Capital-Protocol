// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import "forge-std/src/console2.sol"; // Import the console library
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
error ReachedInvestmentCeiling(uint256 providedVal, string errorMessage);

interface Interface {
  function computeCumRemainingInvestorReturn(
    TierInvestment[] memory tierInvestments
  ) external view returns (uint256 cumRemainingInvestorReturn);

  function getInvestmentCeiling(Tier[] memory tiers) external view returns (uint256 investmentCeiling);

  function isInRange(uint256 minVal, uint256 maxVal, uint256 someVal) external view returns (bool inRange);

  function isWholeDivision(uint256 withRounding, uint256 roundDown) external view returns (bool boolIsWholeDivision);

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
  ) external pure returns (uint256 returnCumRemainingInvestorReturn);
}

contract Helper is Interface {
  /**
  @notice This function calculates the total remaining investment return across all TierInvestments.

  @dev This function is a view function and does not modify the contract's state. It iterates through a provided array
  of `TierInvestment` objects and accumulates the `getRemainingReturn` values from each TierInvestment.

  @param tierInvestments An array of `TierInvestment` objects representing an investment in a specific investment Tier.

  @return cumRemainingInvestorReturn The total amount of WEI remaining to be returned to all investors across all
  tiers.
  */
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

  /**
  @notice This function retrieves the investment ceiling amount from the provided investment tiers.

  @dev This function is a view function and does not modify the contract's state. It assumes that the investment tiers
  are ordered with the highest tier at the end of the provided `tiers` array. The function retrieves the `getMaxVal`
  from the last tier in the array, which represents the maximum investment allowed according to the configured tiers.

  @param tiers An array of `Tier` structs representing the investment tiers and their configurations.

  @return investmentCeiling The investment ceiling amount (in WEI) defined by the highest tier.
  */
  function getInvestmentCeiling(Tier[] memory tiers) public view override returns (uint256 investmentCeiling) {
    // Access the last tier in the array

    uint256 lastIndex = tiers.length - 1;

    investmentCeiling = tiers[lastIndex].getMaxVal();

    return investmentCeiling;
  }

  /**
  @notice This function determines if the total amount of received investments has reached the investment ceiling.

  @dev This function is a view function and does not modify the contract's state. It compares the provided `cumReceivedInvestments` (total received WEI) to the investment ceiling retrieved by calling `getInvestmentCeiling(tiers)`.

  @param cumReceivedInvestments The cumulative amount of WEI received from investors.
  @param tiers An array of `Tier` structs representing the investment tiers and their configurations.

  @return reachedInvestmentCeiling True if the total received investments have reached or exceeded the investment ceiling, False otherwise.
  */
  function hasReachedInvestmentCeiling(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
  ) public view override returns (bool reachedInvestmentCeiling) {
    reachedInvestmentCeiling = cumReceivedInvestments >= getInvestmentCeiling(tiers);
    return reachedInvestmentCeiling;
  }

  /**
  @notice This function identifies the current investment tier based on the total received investments.

  @dev This function is a view function and does not modify the contract's state. It iterates through the provided `tiers` array to find the tier where the `cumReceivedInvestments` (total received WEI) falls within the defined investment range.

  @param cumReceivedInvestments The cumulative amount of WEI received from investors.
  @param tiers An array of `Tier` structs representing the investment tiers and their configurations.

  @return currentTier The `Tier` struct representing the current investment tier based on the received investments.

  **Important Notes:**

  * The function assumes that the `tiers` array is properly configured with increasing investment thresholds. The tier with the highest threshold should be positioned at the end of the array.
  * If the `cumReceivedInvestments` reach or exceed the investment ceiling defined by the tiers, the function reverts with a `ReachedInvestmentCeiling` error.
  */
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

    uint256 i = 0;
    while (shouldCheckNextStage(i, nrOfTiers, tiers, cumReceivedInvestments)) {
      i++;
    }
    if (i < nrOfTiers) {
      return tiers[i];
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

  /**
  @notice This function determines whether to check the next investment tier based on the current iteration index and
  the cumulative received investments.
  @dev This function is a view function and does not modify the contract's state. It checks if the cumulative received
  investments fall within the range of the current investment tier. It exists because Solidity does not do lazy
  evaluation, meaning the tiers[i] may yield an out of range error, if the i>= nrOfTiers check is not performed in
  advance. However the entire function needs to be checked in a single while loop conditional, hence the separate
  function.
  @param i The current iteration index.
  @param nrOfTiers The total number of investment tiers.
  @param tiers An array of `Tier` structs representing the investment tiers and their configurations.
  @param cumReceivedInvestments The total amount of wei received from investors.
  @return bool True if the next investment tier should be checked, false otherwise.
  */
  function shouldCheckNextStage(
    uint256 i,
    uint256 nrOfTiers,
    Tier[] memory tiers,
    uint256 cumReceivedInvestments
  ) public view returns (bool) {
    if (i >= nrOfTiers) {
      return false;
    } else {
      return !isInRange(tiers[i].getMinVal(), tiers[i].getMaxVal(), cumReceivedInvestments);
    }
  }

  /**
  @notice This function calculates the remaining amount of investment that is enough to fill the current investment
  tier.

  @dev This function is designed to be used within investment contracts to track progress towards different investment
  tiers. It assumes that the Tier struct has properties getMinVal and getMaxVal which define the minimum and maximum
  investment amounts for the tier, respectively.

  @param cumReceivedInvestments The total amount of wei received in investments so far.
  @param someTier The investment tier for which to calculate the remaining amount.

  @return remainingAmountInTier The amount of wei remaining to be invested to reach the specified tier.
  **/
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

  /**
  @notice This function calculates the remaining amount of wei available for payout to investors after the current payout is distributed.

  @dev This function considers the following factors:

      The total remaining amount available for investor payout (cumRemainingInvestorReturn).
      The investor's fractional share of the pool (investorFracNumerator / investorFracDenominator).
      The amount of wei currently being paid out (paidAmount).

  The function employs a tiered approach to determine the payout amount for investors:

      If there are no remaining funds for investors (cumRemainingInvestorReturn == 0), the function returns 0.
      If the investor's owed amount is less than the current payout (cumRemainingInvestorReturn * investorFracDenominator < paidAmount * (investorFracNumerator)), the function pays out the investor's entire remaining balance (cumRemainingInvestorReturn).
      Otherwise, the function calculates the investor's payout based on their fractional share of the current payment (paidAmount). In this case, a division with rounding-up is performed to ensure investors receive their full entitlement during their final payout.

  @param cumRemainingInvestorReturn The total amount of wei remaining for investor payout before the current distribution.
  @param investorFracNumerator The numerator representing the investor's fractional share.
  @param investorFracDenominator The denominator representing the investor's fractional share.
  @param paidAmount The amount of wei being distributed in the current payout.

  @return returnCumRemainingInvestorReturn The remaining amount of wei available for investor payout after the current distribution.

  **/
  function computeRemainingInvestorPayout(
    uint256 cumRemainingInvestorReturn,
    uint256 investorFracNumerator,
    uint256 investorFracDenominator,
    uint256 paidAmount
  ) public pure override returns (uint256 returnCumRemainingInvestorReturn) {
    require(
      investorFracDenominator >= investorFracNumerator,
      "investorFracNumerator is smaller than investorFracDenominator."
    );

    // If the investors are made whole, return 0.
    if (cumRemainingInvestorReturn == 0) {
      returnCumRemainingInvestorReturn = 0;
      return returnCumRemainingInvestorReturn;

      // Check if the investor is owed less than the amount of SAAS revenue available. If so, just pay the investor in
      // whole.
    } else if (cumRemainingInvestorReturn * investorFracDenominator < paidAmount * (investorFracNumerator)) {
      returnCumRemainingInvestorReturn = cumRemainingInvestorReturn;
      return returnCumRemainingInvestorReturn;

      // In this case, there is not enough SAAS payment received to make the investors whole with this single payment, so
      // instead they get their fraction of the SAAS payment.
    } else {
      // Perform division with roundup to ensure the invstors are paid in whole during their last payout without
      // requiring an additional 1 wei payout.
      uint256 numerator = paidAmount * investorFracNumerator;
      uint256 denominator = investorFracDenominator;
      returnCumRemainingInvestorReturn = numerator / denominator + (numerator % denominator == 0 ? 0 : 1);
      return returnCumRemainingInvestorReturn;
    }
  }

  /**
  @notice This function determines whether a division yields a whole number or not.

  @dev This function is specifically designed for scenarios where division with rounding-up is required once to ensure
  investors receive their full entitlement during their final payout. It takes two arguments:

      withRounding: The dividend in the division operation with rounding-up.
      roundDown: The result of dividing the dividend by the divisor without rounding.

  The function performs a simple comparison between the dividend and the result of the division without rounding. If
  they are equal, it implies no remainder exists after rounding-up, and the function returns false. Otherwise, a
  remainder exists, and the function returns true.

  @param withRounding The dividend to be used in the division operation with rounding-up.
  @param roundDown The result of dividing the dividend by the divisor without rounding.

  @return boolIsWholeDivision A boolean indicating whether the division with rounding-up would result in a remainder:

      true: There would be a remainder after rounding-up the division.
      false: There would be no remainder after rounding-up the division.

  **/
  function isWholeDivision(
    uint256 withRounding,
    uint256 roundDown
  ) public pure override returns (bool boolIsWholeDivision) {
    boolIsWholeDivision = withRounding != roundDown;
    return boolIsWholeDivision;
  }

  /**
  @notice This function checks whether a given value lies within a specific inclusive range.

  @dev This function is useful for validating inputs or performing operations within certain value boundaries. It takes three arguments:

      minVal: The minimum value of the inclusive range.
      maxVal: The maximum value of the inclusive range.
      someVal: The value to be checked against the range.

  @param minVal The minimum value of the inclusive range.
  @param maxVal The maximum value of the inclusive range.
  @param someVal The value to be checked against the range.

  @return inRange A boolean indicating whether the value is within the specified range:

      true: The value is within the inclusive range (minVal <= someVal < maxVal).
      false: The value is outside the inclusive range.

  **/
  function isInRange(uint256 minVal, uint256 maxVal, uint256 someVal) public pure override returns (bool inRange) {
    if (minVal <= someVal && someVal < maxVal) {
      inRange = true;
    } else {
      inRange = false;
    }
    return inRange;
  }
}
