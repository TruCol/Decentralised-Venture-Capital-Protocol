# Interface

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/TierInvestment.sol)

## Functions

### publicSetRemainingReturn

```solidity
function publicSetRemainingReturn(address someInvestor, uint256 newlyReturnedAmount) external;
```

### getInvestor

```solidity
function getInvestor() external view returns (address investor);
```

### getNewInvestmentAmount

```solidity
function getNewInvestmentAmount() external view returns (uint256 newInvestmentAmount);
```

### getRemainingReturn

```solidity
function getRemainingReturn() external view returns (uint256 remainingReturn);
```

### getOwner

```solidity
function getOwner() external view returns (address);
```
