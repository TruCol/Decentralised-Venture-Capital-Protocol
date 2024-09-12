# Interface

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/Helper.sol)

## Functions

### computeCumRemainingInvestorReturn

```solidity
function computeCumRemainingInvestorReturn(TierInvestment[] memory tierInvestments)
    external
    view
    returns (uint256 cumRemainingInvestorReturn);
```

### getInvestmentCeiling

```solidity
function getInvestmentCeiling(Tier[] memory tiers) external view returns (uint256 investmentCeiling);
```

### isInRange

```solidity
function isInRange(uint256 minVal, uint256 maxVal, uint256 someVal) external view returns (bool inRange);
```

### isWholeDivision

```solidity
function isWholeDivision(uint256 withRounding, uint256 roundDown) external view returns (bool boolIsWholeDivision);
```

### hasReachedInvestmentCeiling

```solidity
function hasReachedInvestmentCeiling(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
)
    external
    view
    returns (bool reachedInvestmentCeiling);
```

### computeCurrentInvestmentTier

```solidity
function computeCurrentInvestmentTier(
    uint256 cumReceivedInvestments,
    Tier[] memory tiers
)
    external
    view
    returns (Tier currentTier);
```

### getRemainingAmountInCurrentTier

```solidity
function getRemainingAmountInCurrentTier(
    uint256 cumReceivedInvestments,
    Tier someTier
)
    external
    view
    returns (uint256 remainingAmountInTier);
```

### computeRemainingInvestorPayout

```solidity
function computeRemainingInvestorPayout(
    uint256 cumRemainingInvestorReturn,
    uint256 investorFracNumerator,
    uint256 investorFracDenominator,
    uint256 paidAmount
)
    external
    pure
    returns (uint256 returnCumRemainingInvestorReturn);
```
