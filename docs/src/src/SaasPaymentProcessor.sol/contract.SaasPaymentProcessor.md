# SaasPaymentProcessor

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/SaasPaymentProcessor.sol)

**Inherits:**
[Interface](/src/CustomPaymentSplitter.sol/interface.Interface.md)

## State Variables

### \_owner

```solidity
address private _owner;
```

## Functions

### onlyOwner

Used to ensure only the owner/creator of the constructor of this contract is
able to call/use functions that use this function (modifier).

```solidity
modifier onlyOwner();
```

### constructor

Initializes the SaasPaymentProcessor contract by setting the contract creator as the owner.

*This constructor sets the sender of the transaction as the owner of the contract.*

```solidity
constructor() public;
```

### computeInvestorReturns

Computes the payout for investors based on their tier investments and the SAAS revenue and stores it as the
remaining return in the TierInvestment objects.

*This function calculates the returns for investors in each tierInvestment based on their investments and the
total SAAS revenue. It ensures that the cumulative payouts match the SAAS revenue. The ROIs are then stored in the
tierInvestment  objects as remaining return.*

```solidity
function computeInvestorReturns(
    Helper helper,
    TierInvestment[] memory tierInvestments,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
)
    public
    override
    returns (TierInvestment[] memory, uint256[] memory);
```

**Parameters**

| Name                         | Type               | Description                                                                                       |
| ---------------------------- | ------------------ | ------------------------------------------------------------------------------------------------- |
| `helper`                     | `Helper`           | An instance of the Helper contract.                                                               |
| `tierInvestments`            | `TierInvestment[]` | An array of `TierInvestment` structs representing the investments made by investors in each tier. |
| `saasRevenueForInvestors`    | `uint256`          | The total SAAS revenue allocated for investor returns.                                            |
| `cumRemainingInvestorReturn` | `uint256`          | The cumulative remaining return amount for investors.                                             |

**Returns**

| Name     | Type               | Description                                                                                               |
| -------- | ------------------ | --------------------------------------------------------------------------------------------------------- |
| `<none>` | `TierInvestment[]` | \_returnTiers An array of `TierInvestment` structs representing the tiers for which returns are computed. |
| `<none>` | `uint256[]`        | \_returnAmounts An array of uint256 values representing the computed returns for each tier.               |

### addInvestmentToCurrentTier

Creates TierInvestment & updates total investment.

*Creates a new TierInvestment for an investor in the current tier. Then increments total investment received.
Since it takes in the current tier, it stores the multiple used for that current tier.
Furthermore, it tracks how much investment this contract has received in total using \_cumReceivedInvestments.*

```solidity
function addInvestmentToCurrentTier(
    uint256 cumReceivedInvestments,
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
)
    public
    override
    onlyOwner
    returns (uint256, TierInvestment newTierInvestment);
```

**Parameters**

| Name                     | Type      | Description                                 |
| ------------------------ | --------- | ------------------------------------------- |
| `cumReceivedInvestments` | `uint256` | Total investment received before this call. |
| `investorWallet`         | `address` | Address of the investor.                    |
| `currentTier`            | `Tier`    | The tier the investment belongs to.         |
| `newInvestmentAmount`    | `uint256` | The amount of wei invested.                 |

**Returns**

| Name                | Type             | Description                                                       |
| ------------------- | ---------------- | ----------------------------------------------------------------- |
| `<none>`            | `uint256`        | A tuple of (updated total investment, new TierInvestment object). |
| `newTierInvestment` | `TierInvestment` |                                                                   |

### computeInvestmentReturn

Calculates investment return for investors based on remaining return and investor share.

\*\*

*This function computes the investment return for investors based on the remaining return available for
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
yet critical in the safe evaluation of this contract.*

```solidity
function computeInvestmentReturn(
    Helper helper,
    uint256 remainingReturn,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn,
    bool incomingHasRoundedUp
)
    public
    view
    override
    returns (uint256 investmentReturn, bool returnedHasRoundedUp);
```

**Parameters**

| Name                         | Type      | Description                                                                                                 |
| ---------------------------- | --------- | ----------------------------------------------------------------------------------------------------------- |
| `helper`                     | `Helper`  | (Helper): A reference to a helper contract likely containing the isWholeDivision function.                  |
| `remainingReturn`            | `uint256` | (uint256): The total remaining wei to be distributed to investors.                                          |
| `saasRevenueForInvestors`    | `uint256` | (uint256): The total SaaS revenue allocated to investors.                                                   |
| `cumRemainingInvestorReturn` | `uint256` | (uint256): The total cumulative remaining investor return used as the divisor for calculating share ratios. |
| `incomingHasRoundedUp`       | `bool`    | (bool): A boolean flag indicating if a previous calculation rounded up.                                     |

**Returns**

| Name                   | Type      | Description                                                          |
| ---------------------- | --------- | -------------------------------------------------------------------- |
| `investmentReturn`     | `uint256` | The calculated investment return for the current investor (uint256). |
| `returnedHasRoundedUp` | `bool`    | A boolean indicating if this function rounded up the share (bool).   |
