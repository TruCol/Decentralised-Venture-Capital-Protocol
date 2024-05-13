# Offer

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/ReceiveCounterOffer.sol)

```solidity
struct Offer {
    address payable _offerInvestor;
    uint256 _investmentAmount;
    uint16 _offerMultiplier;
    uint256 _offerDuration;
    uint256 _offerStartTime;
    bool _offerIsAccepted;
    bool _isDecided;
}
```
