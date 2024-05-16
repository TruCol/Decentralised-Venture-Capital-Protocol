// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { Helper } from "../src/Helper.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface Interface {
  function computeInvestorReturns(
    Helper helper,
    TierInvestment[] memory tierInvestments,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
  ) external returns (TierInvestment[] memory returnTiers, uint256[] memory returnAmounts);

  function computeInvestmentReturn(
    Helper helper,
    uint256 remainingReturn,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn,
    bool incomingHasRoundedUp
  ) external returns (uint256 investmentReturn, bool returnedHasRoundedUp);

  function addInvestmentToCurrentTier(
    uint256 cumReceivedInvestments,
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
  ) external returns (uint256 updatedCumReceivedInvestments, TierInvestment newTierInvestment);
}

contract SaasPaymentProcessor is Interface, ReentrancyGuard {
  address private _owner;
  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "SaasPaymentProcessor: The sender of this message is not the owner.");
    _;
  }

  /**
  @notice Initializes the SaasPaymentProcessor contract by setting the contract creator as the owner.
  @dev This constructor sets the sender of the transaction as the owner of the contract.
  */
  // solhint-disable-next-line comprehensive-interface
  constructor() public {
    _owner = msg.sender;
  }

  /**
  @notice Computes the payout for investors based on their tier investments and the SAAS revenue and stores it as the
  remaining return in the TierInvestment objects.
  @dev This function calculates the returns for investors in each tierInvestment based on their investments and the
  total SAAS revenue. It ensures that the cumulative payouts match the SAAS revenue. The ROIs are then stored in the
  tierInvestment  objects as remaining return.

  @param helper An instance of the Helper contract.
  @param tierInvestments An array of `TierInvestment` structs representing the investments made by investors in each
  tier.
  @param saasRevenueForInvestors The total SAAS revenue allocated for investor returns.
  @param cumRemainingInvestorReturn The cumulative remaining return amount for investors.

  @return returnTiers An array of `TierInvestment` structs representing the tiers for which returns are computed.
  @return returnAmounts An array of uint256 values representing the computed returns for each tier.
  */
  function computeInvestorReturns(
    Helper helper,
    TierInvestment[] memory tierInvestments,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
  ) public override returns (TierInvestment[] memory returnTiers, uint256[] memory returnAmounts) {
    require(saasRevenueForInvestors > 0, "saasRevenueForInvestors is not larger than 0.");
    uint256 nrOfTierInvestments = tierInvestments.length;

    returnAmounts = new uint256[](nrOfTierInvestments);
    returnTiers = new TierInvestment[](nrOfTierInvestments);

    uint256 cumulativePayout = 0;
    bool hasRoundedUp = false;

    for (uint256 i = 0; i < nrOfTierInvestments; ++i) {
      // Compute how much an investor receives for its investment in this tier.
      (uint256 investmentReturn, bool returnHasRoundedUp) = computeInvestmentReturn({
        helper: helper,
        remainingReturn: tierInvestments[i].getRemainingReturn(),
        saasRevenueForInvestors: saasRevenueForInvestors,
        cumRemainingInvestorReturn: cumRemainingInvestorReturn,
        incomingHasRoundedUp: hasRoundedUp
      });

      // Booleans are passed by value, so have to overwrite it.
      hasRoundedUp = returnHasRoundedUp;

      if (investmentReturn > 0) {
        // Allocate that amount to the investor.
        returnAmounts[i] = investmentReturn;
        returnTiers[i] = tierInvestments[i];
        // Track the payout in the tierInvestment.
        tierInvestments[i].publicSetRemainingReturn(tierInvestments[i].getInvestor(), investmentReturn);
        cumulativePayout += investmentReturn;
      }
    }

    require(
      cumulativePayout == saasRevenueForInvestors || cumulativePayout + 1 == saasRevenueForInvestors,
      // solhint-disable-next-line func-named-parameters
      string.concat(
        "The cumulativePayout (\n",
        Strings.toString(cumulativePayout),
        ") is not equal to the saasRevenueForInvestors (\n",
        Strings.toString(saasRevenueForInvestors),
        ")."
      )
    );
    return (returnTiers, returnAmounts);
  }

  /**
  @notice Creates TierInvestment & updates total investment.

  @dev Creates a new TierInvestment for an investor in the current tier. Then increments total investment received.
  Since it takes in the current tier, it stores the multiple used for that current tier.
  Furthermore, it tracks how much investment this contract has received in total using _cumReceivedInvestments.

  @param cumReceivedInvestments Total investment received before this call.
  @param investorWallet Address of the investor.
  @param currentTier The tier the investment belongs to.
  @param newInvestmentAmount The amount of wei invested.

  @return updatedCumReceivedInvestments The new cumulatively received investment.
  @return newTierInvestment The newly created TierInvestment object.
  **/
  function addInvestmentToCurrentTier(
    uint256 cumReceivedInvestments,
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
  ) public override onlyOwner returns (uint256 updatedCumReceivedInvestments, TierInvestment newTierInvestment) {
    newTierInvestment = new TierInvestment(investorWallet, newInvestmentAmount, currentTier);
    cumReceivedInvestments += newInvestmentAmount;
    updatedCumReceivedInvestments = cumReceivedInvestments;
    return (updatedCumReceivedInvestments, newTierInvestment);
  }

  /**
  @dev
  */
  /**
  @notice Calculates investment return for investors based on remaining return and investor share.

  @dev This function computes the investment return for investors based on the remaining return available for
  distribution and the total cumulative remaining investor return. It employs integer division, which discards
  decimals.

  Since this is an integer division, which is used to allocate shares,
  the decimals that are discarded by the integer division, in total would add
  up to 1, if the shares are not exact division. Therefore, this function
  compares the results of the division, with round down vs round up. If the two
  divisions are the same, it is an exact division of shares. Otherwise, there
  is one Wei that needs to be added to one of the investor returns to ensure
  the sum of the fractions add up to the whole original.

  It is currently not clear which investor gets this +1 raise. I tried just
  checking it only for the first investor, (as I incorrectly assumed if the
  division is not whole, all investor shares should be not whole). However,
  that led to an off-by one error. I expect this occurred because, by chance the
  fraction of the first investor share was whole, whereas another investor
  share was not whole. So the first investor with a non-whole remaining share
  fraction gets +1 wei to ensure all the numbers add up correctly. A
  difference of +- wei is considederd negligible w.r.t. to the investor return,
  yet critical in the safe evaluation of this contract.


  @param helper (Helper): A reference to a helper contract likely containing the isWholeDivision function.
  @param remainingReturn (uint256): The total remaining wei to be distributed to investors.
  @param saasRevenueForInvestors (uint256): The total SaaS revenue allocated to investors.
  @param cumRemainingInvestorReturn (uint256): The total cumulative remaining investor return used as the divisor for
  calculating share ratios.
  @param incomingHasRoundedUp (bool): A boolean flag indicating if a previous calculation rounded up.

  @return investmentReturn The calculated investment return for the current investor (uint256).
  @return returnedHasRoundedUp A boolean indicating if this function rounded up the share (bool).
  **/
  function computeInvestmentReturn(
    Helper helper,
    uint256 remainingReturn,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn,
    bool incomingHasRoundedUp
  ) public view override returns (uint256 investmentReturn, bool returnedHasRoundedUp) {
    uint256 numerator = remainingReturn * saasRevenueForInvestors;
    uint256 denominator = cumRemainingInvestorReturn;
    require(denominator > 0, "Denominator not larger than 0");

    // Divide with round up.
    uint256 withRoundUp = numerator / denominator + (numerator % denominator == 0 ? 0 : 1);
    // Default Solidity division is rounddown.
    uint256 roundDown = numerator / denominator;
    // uint256 investmentReturn = numerator / denominator;

    if (helper.isWholeDivision(withRoundUp, roundDown) && !incomingHasRoundedUp) {
      investmentReturn = withRoundUp;
      returnedHasRoundedUp = true;
    } else {
      investmentReturn = roundDown;
    }

    return (investmentReturn, returnedHasRoundedUp);
  }
}
