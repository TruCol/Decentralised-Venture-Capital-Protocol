# TierInvestment

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/TierInvestment.sol)

**Inherits:**
[Interface](/src/CustomPaymentSplitter.sol/interface.Interface.md)

## State Variables

### \_investor

```solidity
address private _investor;
```

### \_newInvestmentAmount

```solidity
uint256 private _newInvestmentAmount;
```

### \_tier

```solidity
Tier private _tier;
```

### \_remainingReturn

The amount of DAI that is still to be returned for this investment.

```solidity
uint256 private _remainingReturn;
```

### collectiveReturn

The amount of DAI that the investor can collect as ROI.

```solidity
uint256 public collectiveReturn;
```

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

This function is the constructor used to create a new TierInvestment contract instance.

*All parameters are set during construction and cannot be modified afterwards.*

```solidity
constructor(address someInvestor, uint256 newInvestmentAmount, Tier tier) public;
```

**Parameters**

| Name                  | Type      | Description                                                                         |
| --------------------- | --------- | ----------------------------------------------------------------------------------- |
| `someInvestor`        | `address` | The address of the investor who is making the investment.                           |
| `newInvestmentAmount` | `uint256` | The amount of Wei invested by the investor. Must be greater than or equal to 1 Wei. |
| `tier`                | `Tier`    | The Tier object containing investment details like multiplier and lockin period.    |

### publicSetRemainingReturn

Sets the remaining return amount for the investor for whom this TierInvestment was made.

*This function allows the owner of the TierInvestment object to set the remaining return amount for a specific
investor. It subtracts the newly returned amount from the remaining return balance.*

```solidity
function publicSetRemainingReturn(address someInvestor, uint256 newlyReturnedAmount) public override onlyOwner;
```

**Parameters**

| Name                  | Type      | Description                                                                    |
| --------------------- | --------- | ------------------------------------------------------------------------------ |
| `someInvestor`        | `address` | The address of the investor for whom the remaining return amount is being set. |
| `newlyReturnedAmount` | `uint256` | The amount newly returned by the investor.                                     |

### getInvestor

Retrieves the address of the investor associated with this TierInvestment object.

*This function is a view function that returns the address of the investor associated with this TierInvestment
object.*

```solidity
function getInvestor() public view override returns (address investor);
```

**Returns**

| Name       | Type      | Description                  |
| ---------- | --------- | ---------------------------- |
| `investor` | `address` | The address of the investor. |

### getNewInvestmentAmount

Retrieves investment amount associated with this TierInvestment object.

*This function is a view function that returns the investment amount associated with this TierInvestment object.*

```solidity
function getNewInvestmentAmount() public view override returns (uint256 newInvestmentAmount);
```

**Returns**

| Name                  | Type      | Description                |
| --------------------- | --------- | -------------------------- |
| `newInvestmentAmount` | `uint256` | The new investment amount. |

### getRemainingReturn

Retrieves the remaining return amount that the investor can still get with this TierInvestment object.

*This function is a view function that returns the remaining return that the investor can still get with this
TierInvestment object.*

```solidity
function getRemainingReturn() public view override returns (uint256 remainingReturn);
```

**Returns**

| Name              | Type      | Description                  |
| ----------------- | --------- | ---------------------------- |
| `remainingReturn` | `uint256` | The remaining return amount. |

### getOwner

Retrieves the address of the owner of this contract.

*This function is a view function that returns the address of the owner of this contract.*

```solidity
function getOwner() public view override returns (address);
```

**Returns**

| Name     | Type      | Description               |
| -------- | --------- | ------------------------- |
| `<none>` | `address` | The address of the owner. |
