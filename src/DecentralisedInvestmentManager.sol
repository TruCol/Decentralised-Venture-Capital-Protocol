// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import "@openzeppelin/contracts/utils/Strings.sol";
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";

import { SaasPaymentProcessor } from "../src/SaasPaymentProcessor.sol";
import { DecentralisedInvestmentHelper } from "../src/Helper.sol";
import { CustomPaymentSplitter } from "../src/CustomPaymentSplitter.sol";
import { ReceiveCounterOffer } from "../src/ReceiveCounterOffer.sol";
import { Offer } from "../src/ReceiveCounterOffer.sol";

import "forge-std/src/console2.sol"; // Import the console library

interface Interface {
  function receiveSaasPayment() external payable;

  function receiveInvestment() external payable;

  function receiveAcceptedOffer(address payable offerInvestor) external payable;

  function withdraw(uint256 amount) external;

  function getTierInvestmentLength() external returns (uint256 nrOfTierInvestments);

  function increaseCurrentMultipleInstantly(uint256 newMultiple) external;

  function getPaymentSplitter() external returns (CustomPaymentSplitter paymentSplitter);

  function getCumReceivedInvestments() external returns (uint256 cumReceivedInvestments);

  function getCumRemainingInvestorReturn() external returns (uint256 cumRemainingInvestorReturn);

  function getCurrentTier() external returns (Tier currentTier);

  function getProjectLeadFracNumerator() external returns (uint256 projectLeadFracNumerator);

  function getReceiveCounterOffer() external returns (ReceiveCounterOffer);
}

contract DecentralisedInvestmentManager is Interface {
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  address private _saas;
  address private _projectLead;

  address[] private _withdrawers;
  uint256[] private _owedDai;

  CustomPaymentSplitter private _paymentSplitter;
  uint256 private _cumReceivedInvestments;

  // Custom attributes of the contract.
  Tier[] private _tiers;

  ReceiveCounterOffer private _receiveCounterOffer;

  DecentralisedInvestmentHelper private _helper;

  SaasPaymentProcessor private _saasPaymentProcessor;
  TierInvestment[] private _tierInvestments;

  uint256 private _startTime;
  uint32 private _raisePeriod;
  uint256 private _investmentTarget;

  uint256 private _offerInvestmentAmount;
  uint16 private _offerMultiplier;
  uint256 private _offerDuration; // Time in seconds for project lead to decide
  uint256 private _offerStartTime;
  bool private _offerIsAccepted;

  event PaymentReceived(address indexed from, uint256 indexed amount);
  event InvestmentReceived(address indexed from, uint256 indexed amount);

  // Modifier to check if the delay has passed and investment target is unmet
  modifier onlyAfterDelayAndUnderTarget() {
    require(block.timestamp >= _startTime + _raisePeriod, "The fund raising period has not passed yet.");
    require(_cumReceivedInvestments < _investmentTarget, "Investment target reached!");
    _; // Allows execution of the decorated (triggerReturnAll) function.
  }

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(
    Tier[] memory tiers,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLead,
    uint32 raisePeriod,
    uint256 investmentTarget
  ) public {
    // Store incoming arguments in contract.
    _projectLeadFracNumerator = projectLeadFracNumerator;
    _projectLeadFracDenominator = projectLeadFracDenominator;
    _projectLead = projectLead;

    // Initialise contract helper.
    _helper = new DecentralisedInvestmentHelper();
    _saasPaymentProcessor = new SaasPaymentProcessor();

    _startTime = block.timestamp;
    _raisePeriod = raisePeriod;
    _investmentTarget = investmentTarget;

    // Initialise default values.
    _cumReceivedInvestments = 0;

    // Add the project lead to the withdrawers and set its amount owed to 0.
    _withdrawers.push(projectLead);
    _owedDai.push(0);
    _paymentSplitter = new CustomPaymentSplitter(_withdrawers, _owedDai);

    // Specify the different investment tiers in DAI.
    // Validate the provided tiers array (optional)
    require(tiers.length > 0, "You must provide at least one tier.");

    // Iterate through the tiers and potentially perform additional checks
    uint256 nrOfTiers = tiers.length;
    for (uint256 i = 0; i < nrOfTiers; ++i) {
      // You can access tier properties using _tiers[i].getMinVal(), etc.
      if (i > 0) {
        require(
          tiers[i - 1].getMaxVal() == tiers[i].getMinVal(),
          "Error, the ceiling of the previous investment tier is not equal to the floor of the next investment tier."
        );
      }

      // Recreate the Tier objects because this contract should be the owner.
      uint256 someMin = tiers[i].getMinVal();
      uint256 someMax = tiers[i].getMaxVal();
      uint256 someMultiple = tiers[i].getMultiple();
      Tier tierOwnedByThisContract = new Tier(someMin, someMax, someMultiple);
      _tiers.push(tierOwnedByThisContract);
    }
    _receiveCounterOffer = new ReceiveCounterOffer(projectLead);
  }

  /**
  Permit counter offer. Allows investors to propose a counter offer that locks
  up their funds during a period they choose, for a potential ROI multiple that
  they desire. Within this period, the project lead can decide whether to accept,
  reject or ignore this offer. If the project lead accepts the offer, it will be
  added as a tierInvestment. If the project lead rejects the offer, the funds are
  returned to the investor. If the project lead ignores the offer, the funds are
  returned to the investor after the lockup period has ended.

  If the proposed ROI multiple is below the current ROI and the investment ceiling
  has not yet been reached, the offer is accepted automatically at the proposed
  ROI multiple up to the amount to reach the investment ceiling, or up to the tier
  whose multiple is lower than the proposed multiple. The remaining investment amount
  above the investment ceiling will be returned automatically, the remaining investment
  amount in a tier with a lower multiple than the proposed multiple will be up for
  acceptance/rejection/ignore for the project lead for the lockup duration,
  after which the funds will be automatically returned to the investor, if the
  proposal is not accepted.
  */
  // function _receiveCounterOffer() {}

  /**
  @notice When a saaspayment is received, the total amount the investors may
  still receive, is calculated and stored in cumRemainingInvestorReturn. */
  function receiveSaasPayment() external payable override {
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
      (TierInvestment[] memory returnTiers, uint256[] memory returnAmounts) = _saasPaymentProcessor
        .computeInvestorReturns(_helper, _tierInvestments, saasRevenueForInvestors, cumRemainingInvestorReturn);

      // Perform the allocations.
      for (uint256 i = 0; i < returnTiers.length; i++) {
        if (returnAmounts[i] > 0) {
          _performSaasRevenueAllocation(returnAmounts[i], returnTiers[i].getInvestor());
        }
      }
    }

    // Perform transaction and administration for project lead (if applicable)

    _performSaasRevenueAllocation(saasRevenueForProjectLead, _projectLead);

    emit PaymentReceived(msg.sender, msg.value);
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
  function receiveInvestment() external payable override {
    require(msg.value > 0, "The amount invested was not larger than 0.");

    require(
      !_helper.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers),
      "The investor ceiling is not reached."
    );

    _allocateInvestment(msg.value, msg.sender);

    emit InvestmentReceived(msg.sender, msg.value);
  }

  function receiveAcceptedOffer(address payable offerInvestor) public payable override {
    require(msg.value > 0, "The amount invested was not larger than 0.");
    require(
      msg.sender == address(_receiveCounterOffer),
      "The contract calling this function was not counterOfferContract."
    );
    require(!_helper.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers), "The investor ceiling is reached.");
    _allocateInvestment(msg.value, offerInvestor);

    emit InvestmentReceived(offerInvestor, msg.value);
  }

  function increaseCurrentMultipleInstantly(uint256 newMultiple) public override {
    require(
      msg.sender == _projectLead,
      "Increasing the current investment tier multiple attempted by someone other than project lead."
    );
    Tier currentTier = _helper.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);
    require(newMultiple > currentTier.getMultiple(), "The new multiple was not larger than the old multiple.");
    currentTier.increaseMultiple(newMultiple);
  }

  // Allow project lead to retrieve the investment.
  function withdraw(uint256 amount) public override {
    // Ensure only the project lead can retrieve funds in this contract. The
    // funds in this contract are those coming from investments. Saaspayments are
    // automatically transfured into the CustomPaymentSplitter and retrieved from
    // there.
    require(msg.sender == _projectLead, "Withdraw attempted by someone other than project lead.");
    // Check if contract has sufficient balance
    require(address(this).balance >= amount, "Insufficient contract balance");
    require(_cumReceivedInvestments >= _investmentTarget, "Investment target is not yet reached.");

    // Transfer funds to user using call{value: } (safer approach)
    (bool success, ) = payable(msg.sender).call{ value: amount }("");
    require(success, "Investment withdraw by project lead failed");
  }

  // Assuming there's an internal function to get tier investment length
  function getTierInvestmentLength() public view override returns (uint256 nrOfTierInvestments) {
    nrOfTierInvestments = _tierInvestments.length;
    return nrOfTierInvestments;
  }

  function getPaymentSplitter() public view override returns (CustomPaymentSplitter paymentSplitter) {
    paymentSplitter = _paymentSplitter;
    return paymentSplitter;
  }

  function getCumReceivedInvestments() public view override returns (uint256 cumReceivedInvestments) {
    cumReceivedInvestments = _cumReceivedInvestments;
    return cumReceivedInvestments;
  }

  function getCumRemainingInvestorReturn() public view override returns (uint256 cumRemainingInvestorReturn) {
    return _helper.computeCumRemainingInvestorReturn(_tierInvestments);
  }

  function getCurrentTier() public view override returns (Tier currentTier) {
    currentTier = _helper.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);
    return currentTier;
  }

  function getProjectLeadFracNumerator() public view override returns (uint256 projectLeadFracNumerator) {
    projectLeadFracNumerator = _projectLeadFracNumerator;
    return projectLeadFracNumerator;
  }

  function getReceiveCounterOffer() public view override returns (ReceiveCounterOffer) {
    return _receiveCounterOffer;
  }

  // Function that can be called externally to trigger returnAll if conditions are met
  function triggerReturnAll() public onlyAfterDelayAndUnderTarget {
    // TODO: return all investments.
    uint256 nrOfTierInvestments = _tierInvestments.length;
    for (uint256 i = 0; i < nrOfTierInvestments; ++i) {
      // Transfer the amount to the PaymentSplitter contract
      payable(_tierInvestments[i].getInvestor()).transfer(_tierInvestments[i].getNewInvestmentAmount());
    }
    require(address(this).balance == 0, "After returning investments, there is still money in the contract.");
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

  Made internal instead of private for testing purposes.
  */
  function _allocateInvestment(uint256 investmentAmount, address investorWallet) internal {
    require(investmentAmount > 0, "The amount invested was not larger than 0.");

    if (!_helper.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers)) {
      Tier currentTier = _helper.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);

      uint256 remainingAmountInTier = _helper.getRemainingAmountInCurrentTier(_cumReceivedInvestments, currentTier);

      TierInvestment tierInvestment;
      if (investmentAmount > remainingAmountInTier) {
        // Invest remaining amount in current tier
        (_cumReceivedInvestments, tierInvestment) = _saasPaymentProcessor.addInvestmentToCurrentTier(
          _cumReceivedInvestments,
          investorWallet,
          currentTier,
          remainingAmountInTier
        );

        require(
          tierInvestment.getOwner() == address(_saasPaymentProcessor),
          "The TierInvestment was not created through this contract 0."
        );
        _tierInvestments.push(tierInvestment);

        // Invest remaining amount from user
        uint256 remainingInvestmentAmount = investmentAmount - remainingAmountInTier;

        _allocateInvestment(remainingInvestmentAmount, investorWallet);
      } else {
        // Invest full amount in current tier
        (_cumReceivedInvestments, tierInvestment) = _saasPaymentProcessor.addInvestmentToCurrentTier(
          _cumReceivedInvestments,
          investorWallet,
          currentTier,
          investmentAmount
        );
        require(
          tierInvestment.getOwner() == address(_saasPaymentProcessor),
          "The TierInvestment was not created through this contract 1."
        );
        _tierInvestments.push(tierInvestment);
      }
    } else {
      revert("Remaining funds should be returned if the investment ceiling is reached.");
    }
  }

  /**
  This contract does not check who calls it, which sounds risky, but it is an internal contract,
  which means it can only be called by this contract or contracts that derive from this one.
  I assume contracts that derive from this contract are contracts that are initialised within this
  contract. So as long as this, and those contracts do not allow calling this function with
  values that are not consistent with the proper use of this function, it is safe.
  In essence, other functions should not allow calling this function with an amount or
  wallet address that did not correspond to a SAAS payment. Since this function is only
  called by receiveSaasPayment function (w.r.t. non-test functions), which contains the
   logic to only call this if a avlid SAAS payment is received, this is safe.

   Ideally one would make it private instead of internal, such that only this contract is
   able to call this function, however, to also allow tests to reach this contract, it is
   made internal.
  TODO: include safe handling of gas costs.
   */
  function _performSaasRevenueAllocation(uint256 amount, address receivingWallet) internal {
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

  function addWorkerReward(uint256 amount) public {
    require(msg.sender == _projectLead, "Other than projectLead tried to reward worker.");
  }
}
