# Interface

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/CustomPaymentSplitter.sol)

## Functions

### deposit

```solidity
function deposit() external payable;
```

### release

```solidity
function release(address payable account) external;
```

### publicAddPayee

```solidity
function publicAddPayee(address account, uint256 dai_) external;
```

### publicAddSharesToPayee

```solidity
function publicAddSharesToPayee(address account, uint256 dai) external;
```

### released

```solidity
function released(address account) external view returns (uint256 amountReleased);
```

### isPayee

```solidity
function isPayee(address account) external view returns (bool accountIsPayee);
```
