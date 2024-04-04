// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { DecentralisedInvestmentHelper } from "../src/Helper.sol";
import { CustomPaymentSplitter } from "../src/CustomPaymentSplitter.sol";

contract DecentralisedInvestmentManager {
  event PaymentReceived(address from, uint256 amount);
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

  TierInvestment[] private _tierInvestments;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *  */

  constructor(uint256 projectLeadFracNumerator, uint256 projectLeadFracDenominator, address projectLead) {
    // Store incoming arguments in contract.
    _projectLeadFracNumerator = projectLeadFracNumerator;
    _projectLeadFracDenominator = projectLeadFracDenominator;
    _projectLead = projectLead;

    // Initialise default values.
    _cumReceivedInvestments = 0;
    _paymentSplitter = initialiseCustomPaymentSplitter(_projectLead);

    // Specify the different investment tiers in DAI.
    Tier tier_0 = new Tier(0, 10000, 10);
    _tiers.push(tier_0);
    Tier tier_1 = new Tier(10000, 50000, 5);
    _tiers.push(tier_1);
    Tier tier_2 = new Tier(50000, 100000, 2);
    _tiers.push(tier_2);
  }

  function initialiseCustomPaymentSplitter(address projectLead) private returns (CustomPaymentSplitter) {
    _withdrawers.push(projectLead);
    _owedDai.push(0);
    return new CustomPaymentSplitter(_withdrawers, _owedDai);
  }

  function distributeSaasPaymentFractionToInvestors() private {
    uint256 cumulativePayout = 0;
    for (uint256 i = 0; i < _tierInvestments.length; i++) {
      uint256 tierInvestmentReturnFraction = _tierInvestments[i].remainingReturn();
    }
  }

  function receiveSaasPayment() external payable {
    require(msg.value > 0, "The amount paid was not larger than 0.");

    emit PaymentReceived(msg.sender, msg.value);

    uint256 paidAmount = msg.value; // Assuming msg.value holds the received amount
    uint256 amountForProjectLead = 0;
    uint256 amountForInvestors = 0;

    // Initialise the helper contract, and compute how much the investors can
    // receive together as total ROI.
    DecentralisedInvestmentHelper helper = new DecentralisedInvestmentHelper();
    uint256 cumRemainingInvestorReturn = helper.computeCumRemainingInvestorReturn(_tierInvestments);

    if (cumRemainingInvestorReturn == 0) {
      amountForProjectLead = paidAmount;
    } else if (
      cumRemainingInvestorReturn <=
      helper.aTimes1MinusBOverC(paidAmount, _projectLeadFracNumerator, _projectLeadFracDenominator)
    ) {
      amountForInvestors = cumRemainingInvestorReturn;
      amountForProjectLead = paidAmount - cumRemainingInvestorReturn;
    } else {
      amountForProjectLead =
        paidAmount *
        helper.aTimesBOverC(paidAmount, _projectLeadFracNumerator, _projectLeadFracDenominator);
      amountForInvestors = paidAmount - amountForProjectLead;
    }

    require(amountForInvestors + amountForProjectLead != paidAmount, "Error: SAAS revenue distribution mismatch.");

    // Perform transaction and administration for project lead (if applicable)
    performSaasRevenueAllocation(amountForProjectLead, _projectLead);

    // Distribute remaining amount to investors (if applicable)Store
    if (amountForInvestors > 0) {}
  }

  function performSaasRevenueAllocation(uint256 amount, address receivingWallet) private {
    // TODO: include safe handling of gas costs.
    require(address(this).balance >= amount, "Error: Insufficient contract balance.");

    if (!(_paymentSplitter.isPayee(receivingWallet))) {
      _paymentSplitter.publicAddPayee(receivingWallet, amount);
    } else {
      _paymentSplitter.publicAddSharesToPayee(receivingWallet, amount);
    }
  }
}
