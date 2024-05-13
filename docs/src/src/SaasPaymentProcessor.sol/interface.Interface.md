# Interface

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/SaasPaymentProcessor.sol)

## Functions

### computeInvestorReturns

```solidity
function computeInvestorReturns(
    Helper helper,
    TierInvestment[] memory tierInvestments,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
)
    external
    returns (TierInvestment[] memory, uint256[] memory);
```

### computeInvestmentReturn

```solidity
function computeInvestmentReturn(
    Helper helper,
    uint256 remainingReturn,
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn,
    bool incomingHasRoundedUp
)
    external
    returns (uint256 investmentReturn, bool returnedHasRoundedUp);
```

### addInvestmentToCurrentTier

```solidity
function addInvestmentToCurrentTier(
    uint256 cumReceivedInvestments,
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
)
    external
    returns (uint256, TierInvestment newTierInvestment);
```
