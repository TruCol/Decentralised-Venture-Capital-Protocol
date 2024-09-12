# Tier

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/Tier.sol)

**Inherits:**
[ITier](/src/Tier.sol/interface.ITier.md)

## State Variables

### \_minVal

```solidity
uint256 private _minVal;
```

### \_maxVal

```solidity
uint256 private _maxVal;
```

### \_multiple

```solidity
uint256 private _multiple;
```

### \_owner

```solidity
address private _owner;
```

## Functions

### constructor

Constructor for creating a Tier instance with specified configuration parameters.

*This constructor initializes a Tier instance with the provided minimum value, maximum value, and ROI multiple.
The values cannot be changed after creation.
Consecutive Tier objects are expected to have touching maxVal and minVal values respectively.*

```solidity
constructor(uint256 minVal, uint256 maxVal, uint256 multiple) public;
```

**Parameters**

| Name       | Type      | Description                                  |
| ---------- | --------- | -------------------------------------------- |
| `minVal`   | `uint256` | The minimum investment amount for this tier. |
| `maxVal`   | `uint256` | The maximum investment amount for this tier. |
| `multiple` | `uint256` | The ROI multiple for this tier.              |

### increaseMultiple

Increases the ROI multiple for this Tier object.

*This function allows the project lead to increase the ROI multiple for this Tier object. It requires that the
caller is the owner of the Tier object and that the new integer multiple is larger than the current integer multiple.*

```solidity
function increaseMultiple(uint256 newMultiple) public virtual override;
```

**Parameters**

| Name          | Type      | Description                                       |
| ------------- | --------- | ------------------------------------------------- |
| `newMultiple` | `uint256` | The new ROI multiple to set for this Tier object. |

### getMinVal

This function retrieves the investment starting amount at which this Tier begins.

*This value can be used to determine if the current investment level is in this tier or not.*

```solidity
function getMinVal() public view override returns (uint256 minVal);
```

**Returns**

| Name     | Type      | Description                |
| -------- | --------- | -------------------------- |
| `minVal` | `uint256` | The minimum allowed value. |

### getMaxVal

This function retrieves the investment ceiling amount at which this Tier ends.

*This value can be used to determine if the current investment level is in this tier or not.*

```solidity
function getMaxVal() public view override returns (uint256 maxVal);
```

**Returns**

| Name     | Type      | Description                |
| -------- | --------- | -------------------------- |
| `maxVal` | `uint256` | The minimum allowed value. |

### getMultiple

This function retrieves the current ROI multiple that is used for all investments that are allocated in this
Tier.

*This value is used to compute how much  an investor may receive as return on investment. An investment of
5 ether at a multiple of 6 yields can yield a maximum profit of 25 ether, if sufficient SAAS revenue comes in.*

```solidity
function getMultiple() public view override returns (uint256 multiple);
```

**Returns**

| Name       | Type      | Description                        |
| ---------- | --------- | ---------------------------------- |
| `multiple` | `uint256` | The current multiplication factor. |
