# Interface

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/ReceiveCounterOffer.sol)

## Functions

### makeOffer

```solidity
function makeOffer(uint16 multiplier, uint256 duration) external payable;
```

### acceptOrRejectOffer

```solidity
function acceptOrRejectOffer(uint256 offerId, bool accept) external;
```

### pullbackOffer

```solidity
function pullbackOffer(uint256 offerId) external;
```
