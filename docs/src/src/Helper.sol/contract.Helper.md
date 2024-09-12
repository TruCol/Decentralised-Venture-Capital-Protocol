# Helper

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/Helper.sol)

**Inherits:**
[Interface](/src/CustomPaymentSplitter.sol/interface.Interface.md)

## Functions

### computeCumRemainingInvestorReturn

This function calculates the total remaining investment return across all TierInvestments.

*This function is a view function and does not modify the contract's state. It iterates through a provided array
of `TierInvestment` objects and accumulates the `getRemainingReturn` values from each TierInvestment.*

```solidity
function computeCumRemainingInvestorReturn(TierInvestment[] memory tierInvestments)
    public
    view
    override
    returns (uint256 cumRemainingInvestorReturn);
```

**Parameters**

| Name              | Type               | Description                                                                                    |
| ----------------- | ------------------ | ---------------------------------------------------------------------------------------------- |
| `tierInvestments` | `TierInvestment[]` | An array of `TierInvestment` objects representing an investment in a specific investment Tier. |

**Returns**

| Name                         | Type      | Description                                                                         |
| ---------------------------- | --------- | ----------------------------------------------------------------------------------- |
| `cumRemainingInvestorReturn` | `uint256` | The total amount of WEI remaining to be returned to all investors across all tiers. |

### getInvestmentCeiling

This function retrieves the investment ceiling amount from the provided investment tiers.

*This function is a view function and does not modify the contract's state. It assumes that the investment tiers
are ordered with the highest tier at the end of the provided `tiers` array. The function retrieves the `getMaxVal`
from the last tier in the array, which represents the maximum investment allowed according to the configured tiers.*

```solidity
function getInvestmentCeiling(Tier[] memory tiers) public view override returns (uint256 investmentCeiling);
```

**Parameters**

| Name    | Type     | Description                                                                            |
| ------- | -------- | -------------------------------------------------------------------------------------- |
| `tiers` | `Tier[]` | An array of `Tier` structs representing the investment tiers and their configurations. |

**Returns**

| Name                | Type      | Description                                                         |
| ------------------- | --------- | ------------------------------------------------------------------- |
| `investmentCeiling` | `uint256` | The investment ceiling amount (in WEI) defined by the highest tier. |

### hasReachedInvestmentCeiling

This function determines if the total amount of received investments has reached the investment ceiling.

*This function is a view function and does not modify the contract's state. It compares the provided
`cumReceivedInvestments` (total received WEI) to the investment ceiling retrieved by calling
`getInvestmentCeiling(tiers)`.*

```solidity
function hasReachedInvestmentCeiling(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
)
    public
    view
    override
    returns (bool reachedInvestmentCeiling);
```

**Parameters**

| Name                     | Type      | Description                                                                            |
| ------------------------ | --------- | -------------------------------------------------------------------------------------- |
| `cumReceivedInvestments` | `uint256` | The cumulative amount of WEI received from investors.                                  |
| `tiers`                  | `Tier[]`  | An array of `Tier` structs representing the investment tiers and their configurations. |

**Returns**

| Name                       | Type   | Description                                                                                              |
| -------------------------- | ------ | -------------------------------------------------------------------------------------------------------- |
| `reachedInvestmentCeiling` | `bool` | True if the total received investments have reached or exceeded the investment ceiling, False otherwise. |

### computeCurrentInvestmentTier

This function identifies the current investment tier based on the total received investments.

*This function is a view function and does not modify the contract's state. It iterates through the provided
`tiers` array to find the tier where the `cumReceivedInvestments` (total received WEI) falls within the defined
investment range.*

```solidity
function computeCurrentInvestmentTier(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
)
    public
    view
    override
    returns (Tier currentTier);
```

**Parameters**

| Name                     | Type      | Description                                                                            |
| ------------------------ | --------- | -------------------------------------------------------------------------------------- |
| `cumReceivedInvestments` | `uint256` | The cumulative amount of WEI received from investors.                                  |
| `tiers`                  | `Tier[]`  | An array of `Tier` structs representing the investment tiers and their configurations. |

**Returns**

| Name          | Type   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `currentTier` | `Tier` | The `Tier` struct representing the current investment tier based on the received investments. Important Notes:\*\* The function assumes that the `tiers` array is properly configured with increasing investment thresholds. The tier with the highest threshold should be positioned at the end of the array. If the `cumReceivedInvestments` reach or exceed the investment ceiling defined by the tiers, the function reverts with a `ReachedInvestmentCeiling` error. |

### shouldCheckNextStage

This function determines whether to check the next investment tier based on the current iteration index and
the cumulative received investments.

*This function is a view function and does not modify the contract's state. It checks if the cumulative received
investments fall within the range of the current investment tier. It exists because Solidity does not do lazy
evaluation, meaning the tiers\[i\] may yield an out of range error, if the i>= nrOfTiers check is not performed in
advance. However the entire function needs to be checked in a single while loop conditional, hence the separate
function.*

```solidity
function shouldCheckNextStage(
    uint256 i,
    uint256 nrOfTiers,
    Tier[] memory tiers,
    uint256 cumReceivedInvestments
)
    public
    view
    returns (bool);
```

**Parameters**

| Name                     | Type      | Description                                                                            |
| ------------------------ | --------- | -------------------------------------------------------------------------------------- |
| `i`                      | `uint256` | The current iteration index.                                                           |
| `nrOfTiers`              | `uint256` | The total number of investment tiers.                                                  |
| `tiers`                  | `Tier[]`  | An array of `Tier` structs representing the investment tiers and their configurations. |
| `cumReceivedInvestments` | `uint256` | The total amount of wei received from investors.                                       |

**Returns**

| Name     | Type   | Description                                                               |
| -------- | ------ | ------------------------------------------------------------------------- |
| `<none>` | `bool` | bool True if the next investment tier should be checked, false otherwise. |

### getRemainingAmountInCurrentTier

This function calculates the remaining amount of investment that is enough to fill the current investment
tier.

*This function is designed to be used within investment contracts to track progress towards different investment
tiers. It assumes that the Tier struct has properties getMinVal and getMaxVal which define the minimum and maximum
investment amounts for the tier, respectively.*

```solidity
function getRemainingAmountInCurrentTier(
    uint256 cumReceivedInvestments,
    Tier someTier
)
    public
    view
    override
    returns (uint256 remainingAmountInTier);
```

**Parameters**

| Name                     | Type      | Description                                                      |
| ------------------------ | --------- | ---------------------------------------------------------------- |
| `cumReceivedInvestments` | `uint256` | The total amount of wei received in investments so far.          |
| `someTier`               | `Tier`    | The investment tier for which to calculate the remaining amount. |

**Returns**

| Name                    | Type      | Description                                                             |
| ----------------------- | --------- | ----------------------------------------------------------------------- |
| `remainingAmountInTier` | `uint256` | The amount of wei remaining to be invested to reach the specified tier. |

### computeRemainingInvestorPayout

This function calculates the remaining amount of wei available for payout to investors after the current
payout is distributed.

*This function considers the following factors:
The total remaining amount available for investor payout (cumRemainingInvestorReturn).
The investor's fractional share of the pool (investorFracNumerator / investorFracDenominator).
The amount of wei currently being paid out (paidAmount).
The function employs a tiered approach to determine the payout amount for investors:
If there are no remaining funds for investors (cumRemainingInvestorReturn == 0), the function returns 0.
If the investor's owed amount is less than the current payout
(cumRemainingInvestorReturn * investorFracDenominator \< paidAmount * (investorFracNumerator)), the function pays
out the investor's entire remaining balance (cumRemainingInvestorReturn).
Otherwise, the function calculates the investor's payout based on their fractional share of the current payment
(paidAmount). In this case, a division with rounding-up is performed to ensure investors receive their full
entitlement during their final payout.*

```solidity
function computeRemainingInvestorPayout(
    uint256 cumRemainingInvestorReturn,
    uint256 investorFracNumerator,
    uint256 investorFracDenominator,
    uint256 paidAmount
)
    public
    pure
    override
    returns (uint256 returnCumRemainingInvestorReturn);
```

**Parameters**

| Name                         | Type      | Description                                                                            |
| ---------------------------- | --------- | -------------------------------------------------------------------------------------- |
| `cumRemainingInvestorReturn` | `uint256` | The total amount of wei remaining for investor payout before the current distribution. |
| `investorFracNumerator`      | `uint256` | The numerator representing the investor's fractional share.                            |
| `investorFracDenominator`    | `uint256` | The denominator representing the investor's fractional share.                          |
| `paidAmount`                 | `uint256` | The amount of wei being distributed in the current payout.                             |

**Returns**

| Name                               | Type      | Description                                                                               |
| ---------------------------------- | --------- | ----------------------------------------------------------------------------------------- |
| `returnCumRemainingInvestorReturn` | `uint256` | The remaining amount of wei available for investor payout after the current distribution. |

### isWholeDivision

This function determines whether a division yields a whole number or not.

*This function is specifically designed for scenarios where division with rounding-up is required once to ensure
investors receive their full entitlement during their final payout. It takes two arguments:
withRounding: The dividend in the division operation with rounding-up.
roundDown: The result of dividing the dividend by the divisor without rounding.
The function performs a simple comparison between the dividend and the result of the division without rounding. If
they are equal, it implies no remainder exists after rounding-up, and the function returns false. Otherwise, a
remainder exists, and the function returns true.*

```solidity
function isWholeDivision(
    uint256 withRounding,
    uint256 roundDown
)
    public
    pure
    override
    returns (bool boolIsWholeDivision);
```

**Parameters**

| Name           | Type      | Description                                                          |
| -------------- | --------- | -------------------------------------------------------------------- |
| `withRounding` | `uint256` | The dividend to be used in the division operation with rounding-up.  |
| `roundDown`    | `uint256` | The result of dividing the dividend by the divisor without rounding. |

**Returns**

| Name                  | Type   | Description                                                                                                                                                                                                                 |
| --------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `boolIsWholeDivision` | `bool` | A boolean indicating whether the division with rounding-up would result in a remainder: true: There would be a remainder after rounding-up the division. false: There would be no remainder after rounding-up the division. |

### isInRange

This function checks whether a given value lies within a specific inclusive range.

*This function is useful for validating inputs or performing operations within certain value boundaries. It takes
three arguments:
minVal: The minimum value of the inclusive range.
maxVal: The maximum value of the inclusive range.
someVal: The value to be checked against the range.*

```solidity
function isInRange(uint256 minVal, uint256 maxVal, uint256 someVal) public pure override returns (bool inRange);
```

**Parameters**

| Name      | Type      | Description                                |
| --------- | --------- | ------------------------------------------ |
| `minVal`  | `uint256` | The minimum value of the inclusive range.  |
| `maxVal`  | `uint256` | The maximum value of the inclusive range.  |
| `someVal` | `uint256` | The value to be checked against the range. |

**Returns**

| Name      | Type   | Description                                                                                                                                                                                          |
| --------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `inRange` | `bool` | A boolean indicating whether the value is within the specified range: true: The value is within the inclusive range (minVal \<= someVal \< maxVal). false: The value is outside the inclusive range. |
