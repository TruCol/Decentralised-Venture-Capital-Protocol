// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";
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
  address private saas;
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
    uint256 firstTierCeiling,
    uint256 secondTierCeiling,
    uint256 thirdTierCeiling,
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
    _paymentSplitter = initialiseCustomPaymentSplitter(_projectLead);

    // Initialise contract helper.
    _helper = new DecentralisedInvestmentHelper();

    // Specify the different investment tiers in DAI.
    Tier tier_0 = new Tier(0, firstTierCeiling, 10);
    _tiers.push(tier_0);
    Tier tier_1 = new Tier(firstTierCeiling, secondTierCeiling, 5);
    _tiers.push(tier_1);
    Tier tier_2 = new Tier(secondTierCeiling, thirdTierCeiling, 2);
    _tiers.push(tier_2);
  }

  function initialiseCustomPaymentSplitter(address projectLead) private returns (CustomPaymentSplitter) {
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
    console2.log(
      "BEFORE paidAmount=%s,cumRemainingInvestorReturn=%s, saasRevenueForInvestors=%s",
      paidAmount,
      cumRemainingInvestorReturn,
      saasRevenueForInvestors
    );

    // Compute the saasRevenue for the investors.
    uint256 investorFracNumerator = _projectLeadFracDenominator - _projectLeadFracNumerator;

    saasRevenueForInvestors = _helper.computeRemainingInvestorPayout(
      cumRemainingInvestorReturn,
      investorFracNumerator,
      _projectLeadFracDenominator,
      paidAmount
    );
    saasRevenueForProjectLead = paidAmount - saasRevenueForInvestors;

    console2.log(
      "paidAmount=%s,cumRemainingInvestorReturn=%s, saasRevenueForInvestors=%s",
      paidAmount,
      cumRemainingInvestorReturn,
      saasRevenueForInvestors
    );
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
    console2.log("saasRevenueForProjectLead=", saasRevenueForProjectLead);
    console2.log("saasRevenueForInvestors=", saasRevenueForInvestors);
    if (saasRevenueForInvestors > 0) {
      distributeSaasPaymentFractionToInvestors(saasRevenueForInvestors, cumRemainingInvestorReturn);
    } else {
      console2.log("Investor does not receive money.");
    }

    // Perform transaction and administration for project lead (if applicable)
    performSaasRevenueAllocation(saasRevenueForProjectLead, _projectLead);

    emit PaymentReceived(msg.sender, msg.value);
  }

  function distributeSaasPaymentFractionToInvestors(
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
  ) private {
    uint256 cumulativePayout = 0;

    for (uint256 i = 0; i < _tierInvestments.length; i++) {
      // TODO: Determine if paymentSplitter can be used to compute remaining
      // investment shares instead.
      // Compute how much an investor receives for its investment in this tier.
      uint256 tierInvestmentReturnFraction = _tierInvestments[i].remainingReturn() / cumRemainingInvestorReturn;
      console2.log("cumRemainingInvestorReturn=", cumRemainingInvestorReturn);
      console2.log("_tierInvestments[%s].remainingReturn()=", i, _tierInvestments[i].remainingReturn());
      console2.log("tierInvestmentReturnFraction=", tierInvestmentReturnFraction);

      uint256 investmentReturn = tierInvestmentReturnFraction * saasRevenueForInvestors;
      console2.log("investmentReturn=", investmentReturn);
      console2.log("_tierInvestments[%s].getInvestor()=", i, _tierInvestments[i].getInvestor());
      // Allocate that amount to the investor.
      performSaasRevenueAllocation(investmentReturn, _tierInvestments[i].getInvestor());

      // Track the payout in the tierInvestment.
      _tierInvestments[i].publicSetRemainingReturn(_tierInvestments[i].getInvestor(), investmentReturn);
      cumulativePayout += investmentReturn;
    }
    require(
      cumulativePayout == saasRevenueForInvestors,
      "The cumulativePayout is not equal to the saasRevenueForInvestors."
    );
  }

  // TODO: include safe handling of gas costs.
  function performSaasRevenueAllocation(uint256 amount, address receivingWallet) private {
    require(address(this).balance >= amount, "Error: Insufficient contract balance.");

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
  allocated or until the investment ceiling is reached. The remaining
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

    allocateInvestment(msg.value, msg.sender);

    emit InvestmentReceived(msg.sender, msg.value);
  }

  /**
  @notice If the investment ceiling is not reached, it finds the lowest open
  investment tier, and then computes how much can still be invested in that
  investment tier. If the investment amount is larger than the amount remaining
  in that tier, it fills that tier up with a part of the investment using the
  addInvestmentToCurrentTier function, and recursively calls itself until the
  investment amount is fully allocated, or the investment ceiling is reached.
  If the investment amount is equal to- or smaller than the amount remaining in
  that tier, it adds that amount to the current investment tier using the
  addInvestmentToCurrentTier. That's it.


  */
  function allocateInvestment(
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
        tierInvestment = addInvestmentToCurrentTier(investorWallet, currentTier, remainingAmountInTier);
        _tierInvestments.push(tierInvestment);

        // Invest remaining amount from user
        uint256 remainingInvestmentAmount = investmentAmount - remainingAmountInTier;

        allocateInvestment(remainingInvestmentAmount, investorWallet);
      } else {
        // Invest full amount in current tier
        tierInvestment = addInvestmentToCurrentTier(investorWallet, currentTier, investmentAmount);

        _tierInvestments.push(tierInvestment);
      }
    } else {
      console2.log("REACHED investment ceiling");
      // TODO: ensure the remaining funds are returned to the investor.
    }
  }

  /**
  @notice This creates a tierInvestment object/contract for the current tier.
  Since it takes in the current tier, it stores the multiple used for that tier
  to specify how much the investor may retrieve. Furthermore, it tracks how
  much investment this contract has received in total using
  _cumReceivedInvestments.
   */
  function addInvestmentToCurrentTier(
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
  ) private returns (TierInvestment) {
    TierInvestment newTierInvestment = new TierInvestment(investorWallet, newInvestmentAmount, currentTier);
    _cumReceivedInvestments += newInvestmentAmount;
    return newTierInvestment;
  }

  // Assuming there's an internal function to get tier investment length
  function getTierInvestmentLength() public view returns (uint256) {
    return _tierInvestments.length;
  }

  // Used to test the content of the _tierInvestments.
  function getTierInvestments() public view returns (TierInvestment[] memory) {
    return _tierInvestments;
  }

  function getContractAddress() public view returns (address) {
    return address(this);
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
}
