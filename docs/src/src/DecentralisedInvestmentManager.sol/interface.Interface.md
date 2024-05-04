# Interface

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/DecentralisedInvestmentManager.sol)

## Functions

### receiveSaasPayment

```solidity
function receiveSaasPayment() external payable;
```

### receiveInvestment

```solidity
function receiveInvestment() external payable;
```

### receiveAcceptedOffer

```solidity
function receiveAcceptedOffer(address payable offerInvestor) external payable;
```

### withdraw

```solidity
function withdraw(uint256 amount) external;
```

### getTierInvestmentLength

```solidity
function getTierInvestmentLength() external returns (uint256 nrOfTierInvestments);
```

### increaseCurrentMultipleInstantly

```solidity
function increaseCurrentMultipleInstantly(uint256 newMultiple) external;
```

### getPaymentSplitter

```solidity
function getPaymentSplitter() external returns (CustomPaymentSplitter paymentSplitter);
```

### getCumReceivedInvestments

```solidity
function getCumReceivedInvestments() external returns (uint256 cumReceivedInvestments);
```

### getCumRemainingInvestorReturn

```solidity
function getCumRemainingInvestorReturn() external returns (uint256 cumRemainingInvestorReturn);
```

### getCurrentTier

```solidity
function getCurrentTier() external returns (Tier currentTier);
```

### getProjectLeadFracNumerator

```solidity
function getProjectLeadFracNumerator() external returns (uint256 projectLeadFracNumerator);
```

### getReceiveCounterOffer

```solidity
function getReceiveCounterOffer() external returns (ReceiveCounterOffer);
```

### getWorkerGetReward

```solidity
function getWorkerGetReward() external returns (WorkerGetReward);
```
