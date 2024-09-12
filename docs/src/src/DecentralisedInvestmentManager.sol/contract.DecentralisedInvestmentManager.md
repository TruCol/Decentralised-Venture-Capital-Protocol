# DecentralisedInvestmentManager

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/DecentralisedInvestmentManager.sol)

**Inherits:**
[Interface](/src/CustomPaymentSplitter.sol/interface.Interface.md)

## State Variables

### \_projectLeadFracNumerator

```solidity
uint256 private _projectLeadFracNumerator;
```

### \_projectLeadFracDenominator

```solidity
uint256 private _projectLeadFracDenominator;
```

### \_saas

```solidity
address private _saas;
```

### \_projectLead

```solidity
address private _projectLead;
```

### \_withdrawers

```solidity
address[] private _withdrawers;
```

### \_owedDai

```solidity
uint256[] private _owedDai;
```

### \_paymentSplitter

```solidity
CustomPaymentSplitter private _paymentSplitter;
```

### \_cumReceivedInvestments

```solidity
uint256 private _cumReceivedInvestments;
```

### \_tiers

```solidity
Tier[] private _tiers;
```

### \_receiveCounterOffer

```solidity
ReceiveCounterOffer private _receiveCounterOffer;
```

### \_helper

```solidity
Helper private _helper;
```

### \_saasPaymentProcessor

```solidity
SaasPaymentProcessor private _saasPaymentProcessor;
```

### \_tierInvestments

```solidity
TierInvestment[] private _tierInvestments;
```

### \_startTime

```solidity
uint256 private _startTime;
```

### \_raisePeriod

```solidity
uint32 private _raisePeriod;
```

### \_investmentTarget

```solidity
uint256 private _investmentTarget;
```

### \_offerInvestmentAmount

```solidity
uint256 private _offerInvestmentAmount;
```

### \_offerMultiplier

```solidity
uint16 private _offerMultiplier;
```

### \_offerDuration

```solidity
uint256 private _offerDuration;
```

### \_offerStartTime

```solidity
uint256 private _offerStartTime;
```

### \_offerIsAccepted

```solidity
bool private _offerIsAccepted;
```

### \_workerGetReward

```solidity
WorkerGetReward private _workerGetReward;
```

## Functions

### onlyAfterDelayAndUnderTarget

```solidity
modifier onlyAfterDelayAndUnderTarget();
```

### constructor

This contract manages a decentralized investment process.

*This contract facilitates fundraising for a project by allowing investors to contribute
currency based on predefined tiers. It tracks the total amount raised, distributes rewards,
and handles withdrawals for the project lead and potentially other parties.*

```solidity
constructor(
    Tier[] memory tiers,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLead,
    uint32 raisePeriod,
    uint256 investmentTarget
)
    public;
```

**Parameters**

| Name                         | Type      | Description |
| ---------------------------- | --------- | ----------- |
| `tiers`                      | `Tier[]`  |             |
| `projectLeadFracNumerator`   | `uint256` |             |
| `projectLeadFracDenominator` | `uint256` |             |
| `projectLead`                | `address` |             |
| `raisePeriod`                | `uint32`  |             |
| `investmentTarget`           | `uint256` |             |

### receiveSaasPayment

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

When a saaspayment is received, the total amount the investors may
still receive, is calculated and stored in cumRemainingInvestorReturn.

```solidity
function receiveSaasPayment() external payable override;
```

### receiveInvestment

This function is called to process a SAAS payment received by the contract.
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

*This function first validates that the received SAAS payment is greater than
zero. Then, it calculates the revenue distribution for the project lead and investors
using helper functions. It performs a sanity check to ensure the distribution matches
the total received amount. Finally, it distributes the investor's portion
(if any) based on their investment tier and remaining return.*

```solidity
function receiveInvestment() external payable override;
```

### receiveAcceptedOffer

This function allows an investor to finalize an investment based on a
previously accepted counter-offer. This can only be called by the
\_receiveCounterOffer contract.

*This function validates that the investment amount is greater than zero
and the caller is authorized (the `ReceiveCounterOffer` contract). It also checks
if the investment ceiling has not been reached. If all requirements are met,
the function allocates the investment and emits an `InvestmentReceived` event.
TODO: specify and test exactly what happens if a single investment overshoots
the investment ceiling.*

```solidity
function receiveAcceptedOffer(address payable offerInvestor) public payable override;
```

**Parameters**

| Name            | Type              | Description                                            |
| --------------- | ----------------- | ------------------------------------------------------ |
| `offerInvestor` | `address payable` | The address of the investor finalizing the investment. |

### increaseCurrentMultipleInstantly

This function allows the project lead to instantly increase the current
investment tier multiplier. (An ROI decrease is not possible.) It does not
increase the ROI multiple of previous investments, it only increases the ROI
multiple of any new investments.

*This function restricts access to the project lead only. It validates that
the new multiplier is strictly greater than the current tier's multiplier.
If the requirements are met, it directly updates the current tier's multiplier
with the new value.*

```solidity
function increaseCurrentMultipleInstantly(uint256 newMultiple) public override;
```

**Parameters**

| Name          | Type      | Description                                                      |
| ------------- | --------- | ---------------------------------------------------------------- |
| `newMultiple` | `uint256` | The new multiplier to be applied to the current investment tier. |

### withdraw

This function allows the project lead to withdraw funds from the investment pool.

*This function restricts access to the project lead only. It verifies that
the contract has sufficient balance and the investment target has been reached
before allowing a withdrawal. It then transfers the requested amount to the
project lead's address using a secure `call{value: }` approach.*

```solidity
function withdraw(uint256 amount) public override;
```

**Parameters**

| Name     | Type      | Description                                           |
| -------- | --------- | ----------------------------------------------------- |
| `amount` | `uint256` | The amount of DAI the project lead wants to withdraw. |

### getTierInvestmentLength

This function retrieves the total number of investment tiers currently
registered in the contract.

*This function is a view function, meaning it doesn't modify the contract's
state. It fetches the length of the internal `_tierInvestments` array
which stores information about each investment tier.*

```solidity
function getTierInvestmentLength() public view override returns (uint256 nrOfTierInvestments);
```

**Returns**

| Name                  | Type      | Description                                      |
| --------------------- | --------- | ------------------------------------------------ |
| `nrOfTierInvestments` | `uint256` | The total number of registered investment tiers. |

### getPaymentSplitter

This function retrieves the address of the `CustomPaymentSplitter` contract
used for managing project lead and investor withdrawals.

*This function is a view function, meaning it doesn't modify the contract's
state. It returns the address stored in the internal `_paymentSplitter`
variable.*

```solidity
function getPaymentSplitter() public view override returns (CustomPaymentSplitter paymentSplitter);
```

**Returns**

| Name              | Type                    | Description                                          |
| ----------------- | ----------------------- | ---------------------------------------------------- |
| `paymentSplitter` | `CustomPaymentSplitter` | The address of the `CustomPaymentSplitter` contract. |

### getCumReceivedInvestments

This function retrieves the total amount of wei currently raised by the
investment campaign.

*This function is a view function, meaning it doesn't modify the contract's
state. It returns the value stored in the internal `_cumReceivedInvestments`
variable which keeps track of the total amount of investments received.*

```solidity
function getCumReceivedInvestments() public view override returns (uint256 cumReceivedInvestments);
```

**Returns**

| Name                     | Type      | Description                                            |
| ------------------------ | --------- | ------------------------------------------------------ |
| `cumReceivedInvestments` | `uint256` | The total amount of wei collected through investments. |

### getCumRemainingInvestorReturn

This function retrieves the total remaining return amount available for
investors based on the current investment pool and defined tiers.

*This function is a view function, meaning it doesn't modify the contract's
state. It utilizes the helper contract `_helper` to calculate the cumulative
remaining investor return based on the current investment tiers and the total
amount of wei raised.*

```solidity
function getCumRemainingInvestorReturn() public view override returns (uint256 cumRemainingInvestorReturn);
```

**Returns**

| Name                         | Type      | Description                                                       |
| ---------------------------- | --------- | ----------------------------------------------------------------- |
| `cumRemainingInvestorReturn` | `uint256` | The total remaining amount of wei available for investor returns. |

### getCurrentTier

This function retrieves the investment tier that corresponds to the current
total amount of wei raised.

*This function is a view function, meaning it doesn't modify the contract's
state. It utilizes the helper contract `_helper` to determine the current tier
based on the predefined investment tiers and the total amount collected through
investments (`_cumReceivedInvestments`).*

```solidity
function getCurrentTier() public view override returns (Tier currentTier);
```

**Returns**

| Name          | Type   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| `currentTier` | `Tier` | An object representing the current investment tier. |

### getProjectLeadFracNumerator

This function retrieves the fraction of the total revenue allocated to
the project lead.

*This function is a view function, meaning it doesn't modify the contract's
state. It returns the value stored in the internal
`_projectLeadFracNumerator` variable, which represents the numerator of the
fraction defining the project lead's revenue share (expressed in WEI).*

```solidity
function getProjectLeadFracNumerator() public view override returns (uint256 projectLeadFracNumerator);
```

**Returns**

| Name                       | Type      | Description                                                                 |
| -------------------------- | --------- | --------------------------------------------------------------------------- |
| `projectLeadFracNumerator` | `uint256` | The numerator representing the project lead's revenue share fraction (WEI). |

### getReceiveCounterOffer

This function retrieves the `ReceiveCounterOffer` contract
used for processing counter-offers made to investors.

*This function is a view function, meaning it doesn't modify the contract's
state. It returns the address stored in the internal `_receiveCounterOffer`
variable.*

```solidity
function getReceiveCounterOffer() public view override returns (ReceiveCounterOffer);
```

**Returns**

| Name     | Type                  | Description                     |
| -------- | --------------------- | ------------------------------- |
| `<none>` | `ReceiveCounterOffer` | `ReceiveCounterOffer` contract. |

### getWorkerGetReward

This function retrieves the `WorkerGetReward` contract
used for managing project worker reward distribution.

*This function is a view function, meaning it doesn't modify the contract's
state. It returns the address stored in the internal `_workerGetReward`
variable.*

```solidity
function getWorkerGetReward() public view override returns (WorkerGetReward);
```

**Returns**

| Name     | Type              | Description                                            |
| -------- | ----------------- | ------------------------------------------------------ |
| `<none>` | `WorkerGetReward` | address The address of the `WorkerGetReward` contract. |

### triggerReturnAll

This function allows the project lead to initiate a full investor return
in case the fundraising target is not met by the deadline.

*This function can only be called by the project lead after the fundraising
delay has passed and the investment target has not been reached. It iterates
through all investment tiers and transfers the invested amounts back to the
corresponding investors using a secure `transfer` approach. Finally, it verifies
that the contract balance is zero after the return process.
Important Notes:*\*
This function is designed as a safety measure and should only be called if
the project fails to reach its funding target.
Project owners should carefully consider the implications of returning funds
before calling this function.\*

```solidity
function triggerReturnAll() public onlyAfterDelayAndUnderTarget;
```

### \_allocateInvestment

This internal function allocates a received investment to the appropriate
tierInvestment contract(s).

\*This function first validates that the investment amount is greater than
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
  The function utilizes the helper contract `_saasPaymentProcessor` to perform the
  tier-based investment allocation and keeps track of all investments using the
  `_tierInvestments` array.\*

```solidity
function _allocateInvestment(uint256 investmentAmount, address investorWallet) internal;
```

**Parameters**

| Name               | Type      | Description                                 |
| ------------------ | --------- | ------------------------------------------- |
| `investmentAmount` | `uint256` | The amount of WEI invested by the investor. |
| `investorWallet`   | `address` | The address of the investor's wallet.       |

### \_performSaasRevenueAllocation

This internal function allocates SAAS revenue to a designated wallet address.

\*This function performs the following actions:

1. Validates that the contract has sufficient balance to cover the allocation amount
   and that the allocation amount is greater than zero.
1. Transfers the allocation amount (in WEI) to the `CustomPaymentSplitter` contract
   using a secure `call{value: }` approach. The call includes the `deposit` function
   signature and the receiving wallet address as arguments.
1. Verifies the success of the transfer.
1. Checks if the receiving wallet is already registered as a payee in the
   `CustomPaymentSplitter` contract.

- If not, it calls the `publicAddPayee` function of the `CustomPaymentSplitter`
  contract to add the receiving wallet as a payee with the allocated amount as
  its initial share.
- If the receiving wallet is already a payee, it calls the
  `publicAddSharesToPayee` function of the `CustomPaymentSplitter` contract to
  increase the existing payee's share by the allocated amount.
  Important Notes:\*\*
  This function assumes the existence of a `CustomPaymentSplitter` contract
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
  made internal.\*

```solidity
function _performSaasRevenueAllocation(uint256 amount, address receivingWallet) internal;
```

**Parameters**

| Name              | Type      | Description                                                   |
| ----------------- | --------- | ------------------------------------------------------------- |
| `amount`          | `uint256` | The amount of WEI to be allocated as SAAS revenue.            |
| `receivingWallet` | `address` | The address of the wallet that should receive the allocation. |

## Events

### PaymentReceived

```solidity
event PaymentReceived(address indexed from, uint256 indexed amount);
```

### InvestmentReceived

```solidity
event InvestmentReceived(address indexed from, uint256 indexed amount);
```
