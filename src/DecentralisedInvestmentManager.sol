// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25; // Specifies the Solidity compiler version.

import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { SaasPaymentProcessor } from "../src/SaasPaymentProcessor.sol";
import { Helper } from "../src/Helper.sol";
import { CustomPaymentSplitter } from "../src/CustomPaymentSplitter.sol";
import { WorkerGetReward } from "../src/WorkerGetReward.sol";
import { ReceiveCounterOffer } from "../src/ReceiveCounterOffer.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IDim {
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

  function getReceiveCounterOffer() external returns (ReceiveCounterOffer receiveCounterOffer);

  function getWorkerGetReward() external returns (WorkerGetReward workerGetReward);

  function triggerReturnAll() external;
}

// solhint-disable-next-line max-states-count
contract DecentralisedInvestmentManager is IDim, ReentrancyGuard {
  uint256 private immutable _PROJECT_LEAD_FRAC_NUMERATOR;
  uint256 private immutable _PROJECT_LEAD_FRAC_DENOMINATOR;
  address private immutable _PROJECT_LEAD;

  address[] private _withdrawers;
  uint256[] private _owedDai;

  CustomPaymentSplitter private immutable _PAYMENT_SPLITTER;
  uint256 private _cumReceivedInvestments;

  // Custom attributes of the contract.
  Tier[] private _tiers;

  ReceiveCounterOffer private immutable _RECEIVE_COUNTER_OFFER;

  Helper private immutable _HELPER;

  SaasPaymentProcessor private immutable _SAAS_PAYMENT_PROCESSOR;
  TierInvestment[] private _tierInvestments;

  uint256 private immutable _START_TIME;
  uint32 private immutable _RAISE_PERIOD;
  uint256 private immutable _INVESTMENT_TARGET;
  WorkerGetReward private immutable _WORKER_GET_REWARD;

  event PaymentReceived(address indexed from, uint256 indexed amount);
  event InvestmentReceived(address indexed from, uint256 indexed amount);

  // Modifier to check if the delay has passed and investment target is unmet
  modifier onlyAfterDelayAndUnderTarget() {
    // miners can manipulate time(stamps) seconds, not hours/days.
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp >= _START_TIME + _RAISE_PERIOD, "The fund raising period has not passed yet.");
    require(_cumReceivedInvestments < _INVESTMENT_TARGET, "Investment target reached!");
    _; // Allows execution of the decorated (triggerReturnAll) function.
  }

  /**
  @notice This contract manages a decentralized investment process.

  @dev This contract facilitates fundraising for a project by allowing investors to contribute
  currency based on predefined tiers. It tracks the total amount raised, distributes rewards,
  and handles withdrawals for the project lead and potentially other parties.

  @param tiers: An array of `Tier` objects defining the different investment tiers.
  @param projectLeadFracNumerator: Numerator representing the project lead's revenue share.
  @param projectLeadFracDenominator: Denominator representing the project lead's revenue share.
  @param projectLead: The address of the project lead.
  @param raisePeriod: The duration of the fundraising campaign in seconds (uint32).
  @param investmentTarget: The total amount of DAI the campaign aims to raise.
  */
  // solhint-disable-next-line comprehensive-interface
  // solhint-disable-next-line comprehensive-interface
  constructor(
    Tier[] memory tiers,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLead,
    uint32 raisePeriod,
    uint256 investmentTarget
  ) public {
    uint256 nrOfTiers = tiers.length;
    require(nrOfTiers > 0, "You must provide at least one tier.");
    _PROJECT_LEAD_FRAC_NUMERATOR = projectLeadFracNumerator;
    _PROJECT_LEAD_FRAC_DENOMINATOR = projectLeadFracDenominator;
    require(projectLead != address(0), "Error, project lead address can't be 0.");
    _PROJECT_LEAD = projectLead;
    // miners can manipulate time(stamps) seconds, not hours/days.
    // solhint-disable-next-line not-rely-on-time
    _START_TIME = block.timestamp;
    _RAISE_PERIOD = raisePeriod;
    _INVESTMENT_TARGET = investmentTarget;
    _HELPER = new Helper();
    _SAAS_PAYMENT_PROCESSOR = new SaasPaymentProcessor();
    _cumReceivedInvestments = 0;

    // Add the project lead to the withdrawers and set its amount owed to 0.
    _withdrawers.push(projectLead);
    _owedDai.push(0);
    _PAYMENT_SPLITTER = new CustomPaymentSplitter(_withdrawers, _owedDai);
    _WORKER_GET_REWARD = new WorkerGetReward(_PROJECT_LEAD, 8 weeks);

    for (uint256 i = 0; i < nrOfTiers; ++i) {
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
      Tier tierOwnedByThisContract = new Tier({ minVal: someMin, maxVal: someMax, multiple: someMultiple });
      _tiers.push(tierOwnedByThisContract);
    }
    _RECEIVE_COUNTER_OFFER = new ReceiveCounterOffer(projectLead);
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
  // function _RECEIVE_COUNTER_OFFER() {}

  /**
  @notice When a saaspayment is received, the total amount the investors may
  still receive, is calculated and stored in cumRemainingInvestorReturn. */
  function receiveSaasPayment() external payable override {
    require(msg.value > 0, "The SAAS payment was not larger than 0.");
    uint256 paidAmount = msg.value; // Assuming msg.value holds the received amount
    uint256 saasRevenueForProjectLead = 0;
    uint256 saasRevenueForInvestors = 0;

    // Compute how much the investors can receive together as total ROI.
    uint256 cumRemainingInvestorReturn = _HELPER.computeCumRemainingInvestorReturn(_tierInvestments);

    // Compute the saasRevenue for the investors.
    uint256 investorFracNumerator = _PROJECT_LEAD_FRAC_DENOMINATOR - _PROJECT_LEAD_FRAC_NUMERATOR;
    saasRevenueForInvestors = _HELPER.computeRemainingInvestorPayout(
      cumRemainingInvestorReturn,
      investorFracNumerator,
      _PROJECT_LEAD_FRAC_DENOMINATOR,
      paidAmount
    );
    saasRevenueForProjectLead = paidAmount - saasRevenueForInvestors;

    string memory errorMessage = "Error: SAAS revenue distribution mismatch.\n";
    errorMessage = string(
      // solhint-disable-next-line func-named-parameters
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

    // Distribute remaining amount to investors (if applicable).
    if (saasRevenueForInvestors > 0) {
      (TierInvestment[] memory returnTiers, uint256[] memory returnAmounts) = _SAAS_PAYMENT_PROCESSOR
        .computeInvestorReturns(_HELPER, _tierInvestments, saasRevenueForInvestors, cumRemainingInvestorReturn);

      // Perform the allocations.
      uint256 nrOfReturnTiers = returnTiers.length;
      for (uint256 i = 0; i < nrOfReturnTiers; ++i) {
        if (returnAmounts[i] > 0) {
          _performSaasRevenueAllocation(returnAmounts[i], returnTiers[i].getInvestor());
        }
      }
    }

    // Perform transaction and administration for project lead (if applicable)
    _performSaasRevenueAllocation(saasRevenueForProjectLead, _PROJECT_LEAD);
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
  @notice This function is called to process a SAAS payment received by the contract.
  It splits the revenue between the project lead and investors based on a predefined
  ratio.

  When an investor makes an investment with its investmentWallet, this
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

  @dev This function first validates that the received SAAS payment is greater than
  zero. Then, it calculates the revenue distribution for the project lead and investors
  using helper functions. It performs a sanity check to ensure the distribution matches
  the total received amount. Finally, it distributes the investor's portion
  (if any) based on their investment tier and remaining return.


  */
  function receiveInvestment() external payable override {
    require(msg.value > 0, "The amount invested was not larger than 0.");

    require(
      !_HELPER.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers),
      "The investor ceiling is not reached."
    );

    _allocateInvestment(msg.value, msg.sender);

    emit InvestmentReceived(msg.sender, msg.value);
  }

  /**
  @notice This function allows an investor to finalize an investment based on a
  previously accepted counter-offer. This can only be called by the
  _RECEIVE_COUNTER_OFFER contract.

  @dev This function validates that the investment amount is greater than zero
  and the caller is authorized (the `ReceiveCounterOffer` contract). It also checks
  if the investment ceiling has not been reached. If all requirements are met,
  the function allocates the investment and emits an `InvestmentReceived` event.
  TODO: specify and test exactly what happens if a single investment overshoots
  the investment ceiling.

  @param offerInvestor The address of the investor finalizing the investment.


  */
  function receiveAcceptedOffer(address payable offerInvestor) public payable override {
    require(msg.value > 0, "The amount invested was not larger than 0.");
    require(
      msg.sender == address(_RECEIVE_COUNTER_OFFER),
      "The contract calling this function was not counterOfferContract."
    );
    require(!_HELPER.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers), "The investor ceiling is reached.");
    _allocateInvestment(msg.value, offerInvestor);

    emit InvestmentReceived(offerInvestor, msg.value);
  }

  /**
  @notice This function allows the project lead to instantly increase the current
  investment tier multiplier. (An ROI decrease is not possible.) It does not
  increase the ROI multiple of previous investments, it only increases the ROI
  multiple of any new investments.

  @dev This function restricts access to the project lead only. It validates that
  the new multiplier is strictly greater than the current tier's multiplier.
  If the requirements are met, it directly updates the current tier's multiplier
  with the new value.

  @param newMultiple The new multiplier to be applied to the current investment tier.


  */
  function increaseCurrentMultipleInstantly(uint256 newMultiple) public override {
    require(
      msg.sender == _PROJECT_LEAD,
      "Increasing the current investment tier multiple attempted by someone other than project lead."
    );
    Tier currentTier = _HELPER.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);
    require(newMultiple > currentTier.getMultiple(), "The new multiple was not larger than the old multiple.");
    currentTier.increaseMultiple(newMultiple);
  }

  /**
  @notice This function allows the project lead to withdraw funds from the investment pool.

  @dev This function restricts access to the project lead only. It verifies that
  the contract has sufficient balance and the investment target has been reached
  before allowing a withdrawal. It then transfers the requested amount to the
  project lead's address using a secure `call{value: }` approach.

  @param amount The amount of DAI the project lead wants to withdraw.


  */
  function withdraw(uint256 amount) public override {
    // Ensure only the project lead can retrieve funds in this contract. The
    // funds in this contract are those coming from investments. Saaspayments are
    // automatically transfured into the CustomPaymentSplitter and retrieved from
    // there.
    require(msg.sender == _PROJECT_LEAD, "Withdraw attempted by someone other than project lead.");
    // Check if contract has sufficient balance
    require(address(this).balance >= amount, "Insufficient contract balance");
    require(_cumReceivedInvestments >= _INVESTMENT_TARGET, "Investment target is not yet reached.");

    payable(msg.sender).transfer(amount);
  }

  /**
  @notice This function allows the project lead to initiate a full investor return
  in case the fundraising target is not met by the deadline.

  @dev This function can only be called by the project lead after the fundraising
  delay has passed and the investment target has not been reached. It iterates
  through all investment tiers and transfers the invested amounts back to the
  corresponding investors using a secure `transfer` approach. Finally, it verifies
  that the contract balance is zero after the return process.

  **Important Notes:**

  * This function is designed as a safety measure and should only be called if
  the project fails to reach its funding target.
  * Project owners should carefully consider the implications of returning funds
  before calling this function.


  */
  function triggerReturnAll() public override onlyAfterDelayAndUnderTarget {
    require(msg.sender == _PROJECT_LEAD, "Someone other than projectLead tried to return all investments.");
    uint256 nrOfTierInvestments = _tierInvestments.length;
    for (uint256 i = 0; i < nrOfTierInvestments; ++i) {
      // Transfer the amount to the PaymentSplitter contract
      payable(_tierInvestments[i].getInvestor()).transfer(_tierInvestments[i].getNewInvestmentAmount());
    }
    // require(address(this).balance == 0, "After returning investments, there is still money in the contract.");
  }

  /**
  @notice This function retrieves the total number of investment tiers currently
  registered in the contract.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It fetches the length of the internal `_tierInvestments` array
  which stores information about each investment tier.

  @return nrOfTierInvestments The total number of registered investment tiers.
  */
  function getTierInvestmentLength() public view override returns (uint256 nrOfTierInvestments) {
    nrOfTierInvestments = _tierInvestments.length;
    return nrOfTierInvestments;
  }

  /**
  @notice This function retrieves the address of the `CustomPaymentSplitter` contract
  used for managing project lead and investor withdrawals.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It returns the address stored in the internal `_PAYMENT_SPLITTER`
  variable.

  @return paymentSplitter The address of the `CustomPaymentSplitter` contract.
  */
  function getPaymentSplitter() public view override returns (CustomPaymentSplitter paymentSplitter) {
    paymentSplitter = _PAYMENT_SPLITTER;
    return paymentSplitter;
  }

  /**
  @notice This function retrieves the total amount of wei currently raised by the
  investment campaign.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It returns the value stored in the internal `_cumReceivedInvestments`
  variable which keeps track of the total amount of investments received.

  @return cumReceivedInvestments The total amount of wei collected through investments.
  */
  function getCumReceivedInvestments() public view override returns (uint256 cumReceivedInvestments) {
    cumReceivedInvestments = _cumReceivedInvestments;
    return cumReceivedInvestments;
  }

  /**
  @notice This function retrieves the total remaining return amount available for
  investors based on the current investment pool and defined tiers.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It utilizes the helper contract `_HELPER` to calculate the cumulative
  remaining investor return based on the current investment tiers and the total
  amount of wei raised.

  @return cumRemainingInvestorReturn The total remaining amount of wei available for investor returns.
  */
  function getCumRemainingInvestorReturn() public view override returns (uint256 cumRemainingInvestorReturn) {
    return _HELPER.computeCumRemainingInvestorReturn(_tierInvestments);
  }

  /**
  @notice This function retrieves the investment tier that corresponds to the current
  total amount of wei raised.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It utilizes the helper contract `_HELPER` to determine the current tier
  based on the predefined investment tiers and the total amount collected through
  investments (`_cumReceivedInvestments`).

  @return currentTier An object representing the current investment tier.
  */
  function getCurrentTier() public view override returns (Tier currentTier) {
    currentTier = _HELPER.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);
    return currentTier;
  }

  /**
  @notice This function retrieves the fraction of the total revenue allocated to
  the project lead.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It returns the value stored in the internal
  `_PROJECT_LEAD_FRAC_NUMERATOR` variable, which represents the numerator of the
  fraction defining the project lead's revenue share (expressed in WEI).

  @return projectLeadFracNumerator The numerator representing the project lead's revenue share fraction (WEI).
  */
  function getProjectLeadFracNumerator() public view override returns (uint256 projectLeadFracNumerator) {
    projectLeadFracNumerator = _PROJECT_LEAD_FRAC_NUMERATOR;
    return projectLeadFracNumerator;
  }

  /**
  @notice This function retrieves the `ReceiveCounterOffer` contract
  used for processing counter-offers made to investors.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It returns the address stored in the internal `_RECEIVE_COUNTER_OFFER`
  variable.

  @return receiveCounterOffer contract.
  */
  function getReceiveCounterOffer() public view override returns (ReceiveCounterOffer receiveCounterOffer) {
    receiveCounterOffer = _RECEIVE_COUNTER_OFFER;
    return receiveCounterOffer;
  }

  /**
  @notice This function retrieves the `WorkerGetReward` contract
  used for managing project worker reward distribution.

  @dev This function is a view function, meaning it doesn't modify the contract's
  state. It returns the address stored in the internal `_WORKER_GET_REWARD`
  variable.

  @return workerGetReward address The address of the `WorkerGetReward` contract.
  */
  function getWorkerGetReward() public view override returns (WorkerGetReward workerGetReward) {
    workerGetReward = _WORKER_GET_REWARD;
    return workerGetReward;
  }

  /**
  @notice This internal function allocates a received investment to the appropriate
  tierInvestment contract(s).

  @dev This function first validates that the investment amount is greater than
  zero. It then checks if the investment ceiling has been reached. If not, it
  determines the current investment tier and the remaining amount available in that
  tier. It allocates the investment following these steps:

  1. If the investment amount is greater than the remaining amount in the current
  tier:
    - Invest the remaining amount in the current tier.
    - Recursively call `_allocateInvestment` with the remaining investment amount
      to allocate the remaining funds to subsequent tiers.

  2. If the investment amount is less than or equal to the remaining amount in the
  current tier:
    - Invest the full amount in the current tier.

  The function utilizes the helper contract `_SAAS_PAYMENT_PROCESSOR` to perform the
  tier-based investment allocation and keeps track of all investments using the
  `_tierInvestments` array.

  @param investmentAmount The amount of WEI invested by the investor.
  @param investorWallet The address of the investor's wallet.
  */
  function _allocateInvestment(uint256 investmentAmount, address investorWallet) internal {
    require(investmentAmount > 0, "The amount invested was not larger than 0.");

    if (!_HELPER.hasReachedInvestmentCeiling(_cumReceivedInvestments, _tiers)) {
      Tier currentTier = _HELPER.computeCurrentInvestmentTier(_cumReceivedInvestments, _tiers);

      uint256 remainingAmountInTier = _HELPER.getRemainingAmountInCurrentTier(_cumReceivedInvestments, currentTier);

      TierInvestment tierInvestment;
      if (investmentAmount > remainingAmountInTier) {
        // Invest remaining amount in current tier
        (_cumReceivedInvestments, tierInvestment) = _SAAS_PAYMENT_PROCESSOR.addInvestmentToCurrentTier(
          _cumReceivedInvestments,
          investorWallet,
          currentTier,
          remainingAmountInTier
        );

        require(
          tierInvestment.getOwner() == address(_SAAS_PAYMENT_PROCESSOR),
          "The TierInvestment was not created through this contract 0."
        );
        _tierInvestments.push(tierInvestment);

        // Invest remaining amount from user
        uint256 remainingInvestmentAmount = investmentAmount - remainingAmountInTier;

        _allocateInvestment(remainingInvestmentAmount, investorWallet);
      } else {
        // Invest full amount in current tier
        (_cumReceivedInvestments, tierInvestment) = _SAAS_PAYMENT_PROCESSOR.addInvestmentToCurrentTier(
          _cumReceivedInvestments,
          investorWallet,
          currentTier,
          investmentAmount
        );
        require(
          tierInvestment.getOwner() == address(_SAAS_PAYMENT_PROCESSOR),
          "The TierInvestment was not created through this contract 1."
        );
        _tierInvestments.push(tierInvestment);
      }
    } else {
      revert("Remaining funds should be returned if the investment ceiling is reached.");
    }
  }

  /**
  @notice This internal function allocates SAAS revenue to a designated wallet address.

  @dev This function performs the following actions:

  1. Validates that the contract has sufficient balance to cover the allocation amount
  and that the allocation amount is greater than zero.

  2. Transfers the allocation amount (in WEI) to the `CustomPaymentSplitter` contract
  using a secure `call{value: }` approach. The call includes the `deposit` function
  signature and the receiving wallet address as arguments.

  3. Verifies the success of the transfer.

  4. Checks if the receiving wallet is already registered as a payee in the
  `CustomPaymentSplitter` contract.

    - If not, it calls the `publicAddPayee` function of the `CustomPaymentSplitter`
      contract to add the receiving wallet as a payee with the allocated amount as
      its initial share.

    - If the receiving wallet is already a payee, it calls the
      `publicAddSharesToPayee` function of the `CustomPaymentSplitter` contract to
      increase the existing payee's share by the allocated amount.

  **Important Notes:**

  * This function assumes the existence of a `CustomPaymentSplitter` contract
  deployed and properly configured for managing project revenue distribution.

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

  @param amount The amount of WEI to be allocated as SAAS revenue.
  @param receivingWallet The address of the wallet that should receive the allocation.
  */
  function _performSaasRevenueAllocation(uint256 amount, address receivingWallet) internal {
    require(address(this).balance >= amount, "Error: Insufficient contract balance.");
    require(amount > 0, "The SAAS revenue allocation amount was not larger than 0.");
    _PAYMENT_SPLITTER.deposit{ value: amount }();

    // TODO: transfer this to the _PAYMENT_SPLITTER contract.
    if (!(_PAYMENT_SPLITTER.isPayee(receivingWallet))) {
      _PAYMENT_SPLITTER.publicAddPayee(receivingWallet, amount);
    } else {
      _PAYMENT_SPLITTER.publicAddSharesToPayee(receivingWallet, amount);
    }
  }
}
