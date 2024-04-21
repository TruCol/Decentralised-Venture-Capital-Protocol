// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import "@openzeppelin/contracts/utils/Strings.sol";
// import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { DecentralisedInvestmentHelper } from "../src/Helper.sol";
import { CustomPaymentSplitter } from "../src/CustomPaymentSplitter.sol";
import { console2 } from "forge-std/src/console2.sol";

contract DecentralisedInvestmentManager {
  event PaymentReceived(address from, uint256 amount);
  event InvestmentReceived(address from, uint256 amount);

  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  address private _saas;
  address private _projectLead;

  //
  address[] private _withdrawers;
  uint256[] private _owedDai;

  CustomPaymentSplitter private _paymentSplitter;
  uint256 private _cumReceivedInvestments;

  // Custom attributes of the contract.
  Tier[] private _tiers;

  DecentralisedInvestmentHelper private _helper;
  TierInvestment[] private _tierInvestments;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(
    Tier[] memory tiers,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLead
  ) {
    // Store incoming arguments in contract.
    _projectLeadFracNumerator = projectLeadFracNumerator;
    _projectLeadFracDenominator = projectLeadFracDenominator;
    _projectLead = projectLead;

    // Initialise default values.
    _cumReceivedInvestments = 0;
    _paymentSplitter = _initialiseCustomPaymentSplitter(_projectLead);

    // Initialise contract helper.
    _helper = new DecentralisedInvestmentHelper();

    // Specify the different investment tiers in DAI.
    // Validate the provided tiers array (optional)
    require(tiers.length > 0, "You must provide at least one tier.");

    // Iterate through the tiers and potentially perform additional checks
    for (uint256 i = 0; i < tiers.length; i++) {
      // You can access tier properties using _tiers[i].minVal(), etc.
      if (i > 0) {
        require(
          tiers[i - 1].maxVal() == tiers[i].minVal(),
          "Error, the ceiling of the previous investment tier is not equal to the floor of the next investment tier."
        );
      }

      // Recreate the Tier objects because this contract should be the owner.
      uint256 someMin = tiers[i].minVal();
      uint256 someMax = tiers[i].maxVal();
      uint256 someMultiple = tiers[i].multiple();
      Tier tierOwnedByThisContract = new Tier(someMin, someMax, someMultiple);
      _tiers.push(tierOwnedByThisContract);
    }
  }

  function _initialiseCustomPaymentSplitter(address projectLead) private returns (CustomPaymentSplitter) {
    _withdrawers.push(projectLead);
    _owedDai.push(0);
    return new CustomPaymentSplitter(_withdrawers, _owedDai);
  }

  /**
  @notice When a saaspayment is received, the total amount the investors may
  still receive, is calculated and stored in cumRemainingInvestorReturn. */
  function receiveSaasPayment() external payable {
    require(msg.value > 0, "The SAAS payment was not larger than 0.");

    uint256 paidAmount = msg.value; // Assuming msg.value holds the received amount
    uint256 saasRevenueForProjectLead = 0;
    uint256 saasRevenueForInvestors = 0;

    // Compute how much the investors can receive together as total ROI.
    uint256 cumRemainingInvestorReturn = _helper.computeCumRemainingInvestorReturn(_tierInvestments);

    // Compute the saasRevenue for the investors.
    uint256 investorFracNumerator = _projectLeadFracDenominator - _projectLeadFracNumerator;

    saasRevenueForInvestors = _helper.computeRemainingInvestorPayout(
      cumRemainingInvestorReturn,
      investorFracNumerator,
      _projectLeadFracDenominator,
      paidAmount
    );
    saasRevenueForProjectLead = paidAmount - saasRevenueForInvestors;

    string memory errorMessage = "Error: SAAS revenue distribution mismatch.\n";
    errorMessage = string(
      abi.encodePacked(
        errorMessage,
        "In error saasRevenueForInvestors=",
        abi.encodePacked(saasRevenueForInvestors),
        ", saasRevenueForProjectLead=",
        saasRevenueForProjectLead,
        ", paidAmount=",
        paidAmount
      )
    );
    require(saasRevenueForInvestors + saasRevenueForProjectLead == paidAmount, errorMessage);

    // Distribute remaining amount to investors (if applicable)Store

    if (saasRevenueForInvestors > 0) {
      _distributeSaasPaymentFractionToInvestors(saasRevenueForInvestors, cumRemainingInvestorReturn);
    } else {}

    // Perform transaction and administration for project lead (if applicable)
    _performSaasRevenueAllocation(saasRevenueForProjectLead, _projectLead);

    emit PaymentReceived(msg.sender, msg.value);
  }

  function _distributeSaasPaymentFractionToInvestors(
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
  ) private {
    uint256 cumulativePayout = 0;

    bool hasRoundedUp = false;
    for (uint256 i = 0; i < _tierInvestments.length; i++) {
      // Compute how much an investor receives for its investment in this tier.
      (uint256 investmentReturn, bool returnHasRoundedUp) = computeInvestmentReturn(
        _tierInvestments[i].remainingReturn(),
        saasRevenueForInvestors,
        cumRemainingInvestorReturn,
        hasRoundedUp
      );
      // Booleans are passed by value, so have to overwrite it.
      hasRoundedUp = returnHasRoundedUp;

      if (investmentReturn > 0) {
        // Allocate that amount to the investor.
        _performSaasRevenueAllocation(investmentReturn, _tierInvestments[i].getInvestor());

        // Track the payout in the tierInvestment.
        _tierInvestments[i].publicSetRemainingReturn(_tierInvestments[i].getInvestor(), investmentReturn);
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
  }

  // TODO: include safe handling of gas costs.
  function _performSaasRevenueAllocation(uint256 amount, address receivingWallet) private {
    require(address(this).balance >= amount, "Error: Insufficient contract balance.");
    require(amount > 0, "The SAAS revenue allocation amount was not larger than 0.");

    // Transfer the amount to the PaymentSplitter contract
    (bool success, ) = address(_paymentSplitter).call{ value: amount }(
      abi.encodeWithSignature("deposit()", receivingWallet)
    );
    // Check for successful transfer
    require(success, "Error: Transfer to PaymentSplitter failed.");

    // TODO: transfer this to the _paymentSplitter contract.
    if (!(_paymentSplitter.isPayee(receivingWallet))) {
      _paymentSplitter.publicAddPayee(receivingWallet, amount);
    } else {
      _paymentSplitter.publicAddSharesToPayee(receivingWallet, amount);
    }
  }

  /**
  @notice when an investor makes an investment with its investmentWallet, this
  contract checks whether the contract is full, or whether it still takes in
  new investments. If the investment ceiling is reached it reverts the
  investment back to the investor. Otherwise it takes it in, and fills up the
  investment tiers that are still open until the whole investment amount is
  allocated or until Investment ceiling is reached. The remaining
  investment amount is then reverted.

  To allocate the investment over the investment tiers, first the
  allocateInvestment function finds the lowest tier that is still open/not
  full. The lowest tier has the highest multiple. The allocateInvestment
  function then distributes the investment over the first tier, and then
  recursively calls itself until the whole investment is distributed, or the
  investment ceiling is reached. In case of the latter, the remaining
  investment amount is returned.


   */
  function receiveInvestment() external payable {
    require(msg.value > 0, "The amount invested was not larger than 0.");

    require(
      !_helper.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers),
      "The investor ceiling is not reached."
    );

    _allocateInvestment(msg.value, msg.sender);

    emit InvestmentReceived(msg.sender, msg.value);
  }

  /**
  @notice If the investment ceiling is not reached, it finds the lowest open
  investment tier, and then computes how much can still be invested in that
  investment tier. If the investment amount is larger than the amount remaining
  in that tier, it fills that tier up with a part of the investment using the
  addInvestmentToCurrentTier function, and recursively calls itself until the
  investment amount is fully allocated, or Investment ceiling is reached.
  If the investment amount is equal to- or smaller than the amount remaining in
  that tier, it adds that amount to the current investment tier using the
  addInvestmentToCurrentTier. That's it.


  */
  function _allocateInvestment(
    uint256 investmentAmount,
    // uint256 remainingAmountInTier,
    address investorWallet // Tier currentTier
  ) private {
    require(investmentAmount > 0, "The amount invested was not larger than 0.");

    if (!_helper.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers)) {
      Tier currentTier = _helper.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);

      uint256 remainingAmountInTier = _helper.getRemainingAmountInCurrentTier(_cumReceivedInvestments, currentTier);

      TierInvestment tierInvestment;
      if (investmentAmount > remainingAmountInTier) {
        // Invest remaining amount in current tier
        tierInvestment = _addInvestmentToCurrentTier(investorWallet, currentTier, remainingAmountInTier);
        _tierInvestments.push(tierInvestment);

        // Invest remaining amount from user
        uint256 remainingInvestmentAmount = investmentAmount - remainingAmountInTier;

        _allocateInvestment(remainingInvestmentAmount, investorWallet);
      } else {
        // Invest full amount in current tier
        tierInvestment = _addInvestmentToCurrentTier(investorWallet, currentTier, investmentAmount);

        _tierInvestments.push(tierInvestment);
      }
    } else {
      // TODO: ensure the remaining funds are returned to the investor.
    }
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
    uint256 remainingReturn,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn,
    bool hasRoundedUp
  ) public returns (uint256, bool) {
    uint256 numerator = remainingReturn * saasRevenueForInvestors;
    uint256 denominator = cumRemainingInvestorReturn;

    // Divide with round up.
    uint256 withRoundUp = numerator / denominator + (numerator % denominator == 0 ? 0 : 1);
    // Default Solidity division is rounddown.
    uint256 roundDown = numerator / denominator;
    // uint256 investmentReturn = numerator / denominator;
    uint256 investmentReturn;
    if (isWholeDivision(withRoundUp, roundDown) && !hasRoundedUp) {
      investmentReturn = withRoundUp;
      hasRoundedUp = true;
    } else {
      investmentReturn = roundDown;
    }

    return (investmentReturn, hasRoundedUp);
  }

  function isWholeDivision(uint256 withRounding, uint256 roundDown) public returns (bool) {
    return withRounding != roundDown;
  }

  /**
  @notice This creates a tierInvestment object/contract for the current tier.
  Since it takes in the current tier, it stores the multiple used for that tier
  to specify how much the investor may retrieve. Furthermore, it tracks how
  much investment this contract has received in total using
  _cumReceivedInvestments.
   */
  function _addInvestmentToCurrentTier(
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
  ) private returns (TierInvestment) {
    TierInvestment newTierInvestment = new TierInvestment(investorWallet, newInvestmentAmount, currentTier);
    _cumReceivedInvestments += newInvestmentAmount;
    return newTierInvestment;
  }

  function increaseCurrentMultipleInstantly(uint256 newMultiple) public {
    require(
      msg.sender == _projectLead,
      "Increasing the current investment tier multiple attempted by someone other than project lead."
    );
    Tier currentTier = _helper.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);
    require(newMultiple > currentTier.multiple(), "The new multiple was not larger than the old multiple.");
    currentTier.increaseMultiple(newMultiple);
  }

  // Allow project lead to retrieve the investment.
  function withdraw(uint256 amount) public {
    // Ensure only the project lead can retrieve funds in this contract. The
    // funds in this contract are those coming from investments. Saaspayments are
    // automatically transfured into the CustomPaymentSplitter and retrieved from
    // there.
    require(msg.sender == _projectLead, "Withdraw attempted by someone other than project lead.");
    // Check if contract has sufficient balance
    require(address(this).balance >= amount, "Insufficient contract balance");

    // Transfer funds to user using call{value: } (safer approach)
    (bool success, ) = payable(msg.sender).call{ value: amount }("");
    require(success, "Investment withdraw by project lead failed");
  }

  // Assuming there's an internal function to get tier investment length
  function getTierInvestmentLength() public view returns (uint256) {
    return _tierInvestments.length;
  }

  function getPaymentSplitter() public view returns (CustomPaymentSplitter) {
    return _paymentSplitter;
  }

  function getCumReceivedInvestments() public view returns (uint256) {
    return _cumReceivedInvestments;
  }

  function getCumRemainingInvestorReturn() public view returns (uint256) {
    return _helper.computeCumRemainingInvestorReturn(_tierInvestments);
  }

  function getCurrentTier() public view returns (Tier) {
    Tier currentTier = _helper.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);
    return currentTier;
  }

  function get_projectLeadFracNumerator() public view returns (uint256) {
    return _projectLeadFracNumerator;
  }
}
