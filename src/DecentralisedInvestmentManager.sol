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
  uint256 _cumReceivedInvestments;

  // Custom attributes of the contract.
  Tier[] private _tiers;

  DecentralisedInvestmentHelper private _helper;
  TierInvestment[] private _tierInvestments;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(uint256 projectLeadFracNumerator, uint256 projectLeadFracDenominator, address projectLead) {
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
    Tier tier_0 = new Tier(0, 10_000, 10);
    _tiers.push(tier_0);
    Tier tier_1 = new Tier(10_000, 50_000, 5);
    _tiers.push(tier_1);
    Tier tier_2 = new Tier(50_000, 100_000, 2);
    _tiers.push(tier_2);
  }

  function initialiseCustomPaymentSplitter(address projectLead) private returns (CustomPaymentSplitter) {
    _withdrawers.push(projectLead);
    _owedDai.push(0);
    return new CustomPaymentSplitter(_withdrawers, _owedDai);
  }

  function receiveSaasPayment() external payable {
    require(msg.value > 0, "The amount paid was not larger than 0.");

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
    if (cumRemainingInvestorReturn == 0) {
      saasRevenueForProjectLead = paidAmount;
    } else if (
      cumRemainingInvestorReturn <=
      _helper.aTimes1MinusBOverC(paidAmount, _projectLeadFracNumerator, _projectLeadFracDenominator)
    ) {
      saasRevenueForInvestors = cumRemainingInvestorReturn;
      saasRevenueForProjectLead = paidAmount - cumRemainingInvestorReturn;
    } else {
      saasRevenueForProjectLead =
        paidAmount *
        _helper.aTimesBOverC(paidAmount, _projectLeadFracNumerator, _projectLeadFracDenominator);
      saasRevenueForInvestors = paidAmount - saasRevenueForProjectLead;
    }
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
    if (saasRevenueForInvestors > 0) {
      console2.log("Investors can has money.");
      distributeSaasPaymentFractionToInvestors(saasRevenueForInvestors, cumRemainingInvestorReturn);
    } else {
      console2.log("No money for investors.");
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
      uint256 investmentReturn = tierInvestmentReturnFraction * saasRevenueForInvestors;
      console2.log("i={0}, investmentReturn={1}", investmentReturn);
      // Allocate that amount to the investor.
      performSaasRevenueAllocation(investmentReturn, _tierInvestments[i].investor());

      // Track the payout in the tierInvestment.
      _tierInvestments[i].publicSetRemainingReturn(_tierInvestments[i].investor(), investmentReturn);
      cumulativePayout += investmentReturn;
    }
    require(
      cumulativePayout == saasRevenueForInvestors,
      "The cumulativePayout is not equal to the saasRevenueForInvestors."
    );
  }

  function performSaasRevenueAllocation(uint256 amount, address receivingWallet) private {
    // TODO: include safe handling of gas costs.
    require(address(this).balance >= amount, "Error: Insufficient contract balance.");

    if (!(_paymentSplitter.isPayee(receivingWallet))) {
      _paymentSplitter.publicAddPayee(receivingWallet, amount);
    } else {
      _paymentSplitter.publicAddSharesToPayee(receivingWallet, amount);
      console2.log("Adding shares to payee.");
    }
  }

  function receiveInvestment() external payable {
    require(msg.value > 0, "The amount invested was not larger than 0.");

    require(msg.sender == 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, "The sender was unexpected.");

    require(
      !_helper.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers),
      "The investor ceiling is not reached."
    );

    allocateInvestment(msg.value, msg.sender);

    emit InvestmentReceived(msg.sender, msg.value);
  }

  function allocateInvestment(
    uint256 investmentAmount,
    // uint256 remainingAmountInTier,
    address investorWallet // Tier currentTier
  ) private {
    require(investmentAmount > 0, "The amount invested was not larger than 0.");

    console2.log("investmentAmount={0}, investorWallet={1}", investmentAmount, investorWallet);
    if (!_helper.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers)) {
      Tier currentTier = _helper.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);

      uint256 remainingAmountInTier = _helper.getRemainingAmountInCurrentTier(_cumReceivedInvestments, currentTier);

      TierInvestment tierInvestment;

      if (investmentAmount > remainingAmountInTier) {
        // Invest remaining amount in current tier
        tierInvestment = createAnInvestmentInCurrentTier(investorWallet, currentTier, remainingAmountInTier);
        console2.log("ADDED tierInvestment");
        _tierInvestments.push(tierInvestment);

        // Invest remaining amount from user
        uint256 remainingInvestmentAmount = investmentAmount - remainingAmountInTier;

        allocateInvestment(remainingInvestmentAmount, investorWallet);
      } else {
        // Invest full amount in current tier
        tierInvestment = createAnInvestmentInCurrentTier(investorWallet, currentTier, investmentAmount);

        _tierInvestments.push(tierInvestment);
      }
    } else {
      console2.log("REACHED investment ceiling");
      // TODO: ensure the remaining funds are returned to the investor.
    }
  }

  function createAnInvestmentInCurrentTier(
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
}
