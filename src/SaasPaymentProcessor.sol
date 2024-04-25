// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { DecentralisedInvestmentHelper } from "../src/Helper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/src/console2.sol"; // Import the console library

interface Interface {
  function computeInvestorReturns(
    DecentralisedInvestmentHelper helper,
    TierInvestment[] memory tierInvestments,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
  ) external returns (TierInvestment[] memory, uint256[] memory);

  function computeInvestmentReturn(
    DecentralisedInvestmentHelper helper,
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
  ) external returns (uint256, TierInvestment newTierInvestment);
}

contract SaasPaymentProcessor is Interface {
  address private _owner;
  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "SaasPaymentProcessor: The sender of this message is not the owner.");
    _;
  }

  constructor() public {
    _owner = msg.sender;
  }

  function computeInvestorReturns(
    DecentralisedInvestmentHelper helper,
    TierInvestment[] memory tierInvestments,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
  ) public override returns (TierInvestment[] memory, uint256[] memory) {
    require(saasRevenueForInvestors > 0, "saasRevenueForInvestors is not larger than 0.");
    uint256 nrOfTierInvestments = tierInvestments.length;

    uint256[] memory _returnAmounts = new uint256[](nrOfTierInvestments);
    TierInvestment[] memory _returnTiers = new TierInvestment[](nrOfTierInvestments);

    uint256 cumulativePayout = 0;
    bool hasRoundedUp = false;

    for (uint256 i = 0; i < nrOfTierInvestments; ++i) {
      // Compute how much an investor receives for its investment in this tier.

      (uint256 investmentReturn, bool returnHasRoundedUp) = computeInvestmentReturn(
        helper,
        tierInvestments[i].getRemainingReturn(),
        saasRevenueForInvestors,
        cumRemainingInvestorReturn,
        hasRoundedUp
      );

      // Booleans are passed by value, so have to overwrite it.
      hasRoundedUp = returnHasRoundedUp;

      if (investmentReturn > 0) {
        // Allocate that amount to the investor.
        _returnAmounts[i] = investmentReturn;
        _returnTiers[i] = tierInvestments[i];
        // Track the payout in the tierInvestment.
        tierInvestments[i].publicSetRemainingReturn(tierInvestments[i].getInvestor(), investmentReturn);
        cumulativePayout += investmentReturn;
      }
    }

    require(
      cumulativePayout == saasRevenueForInvestors || cumulativePayout + 1 == saasRevenueForInvestors,
      // cumulativePayout == saasRevenueForInvestors,
      string.concat(
        "The cumulativePayout (\n",
        Strings.toString(cumulativePayout),
        ") is not equal to the saasRevenueForInvestors (\n",
        Strings.toString(saasRevenueForInvestors),
        ")."
      )
    );
    return (_returnTiers, _returnAmounts);
  }

  /**
  @notice This creates a tierInvestment object/contract for the current tier.
  Since it takes in the current tier, it stores the multiple used for that tier
  to specify how much the investor may retrieve. Furthermore, it tracks how
  much investment this contract has received in total using
  _cumReceivedInvestments.
   */
  function addInvestmentToCurrentTier(
    uint256 cumReceivedInvestments,
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
  ) public override onlyOwner returns (uint256, TierInvestment newTierInvestment) {
    newTierInvestment = new TierInvestment(investorWallet, newInvestmentAmount, currentTier);
    cumReceivedInvestments += newInvestmentAmount;
    return (cumReceivedInvestments, newTierInvestment);
  }

  /**
  @dev Since this is an integer division, which is used to allocate shares,
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
  */
  function computeInvestmentReturn(
    DecentralisedInvestmentHelper helper,
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
