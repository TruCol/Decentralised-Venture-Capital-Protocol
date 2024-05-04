# CustomPaymentSplitter

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/CustomPaymentSplitter.sol)

**Inherits:**
[Interface](/src/CustomPaymentSplitter.sol/interface.Interface.md)

*This contract can be used when payments need to be received by a group
of people and split proportionately to some number of dai they own.*

## State Variables

### \_totalDai

```solidity
uint256 private _totalDai;
```

### \_totalReleased

```solidity
uint256 private _totalReleased;
```

### \_dai

```solidity
mapping(address => uint256) private _dai;
```

### \_released

```solidity
mapping(address => uint256) private _released;
```

### \_payees

```solidity
address[] private _payees;
```

### \_amountsOwed

```solidity
uint256[] private _amountsOwed;
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

This constructor initializes the `CustomPaymentSplitter` contract.

\*This constructor performs the following actions:

1. Validates that the provided lists of payees and corresponding amounts owed have
   the same length. It ensures at least one payee is specified. That implicitly
   veries that at least one amountsOwed element is given.
1. Sets the contract owner to the message sender (`msg.sender`). This contract
   is designed to be initialised by the DecentralisedInvestmentManager contract.
1. Stores the provided `amountsOwed` array in the internal `_amountsOwed`
   variable.
1. Iterates through the `payees` and `amountsOwed` arrays, calling the
   `_addPayee` internal function for each element to register payees and their
   initial shares.
   Important Notes:\*\*
   The `CustomPaymentSplitter` contract is designed for splitting payments among
   multiple payees based on predefined shares. It is a modificiation of the
   PaymentSplitter contract by OpenZeppelin.\*

```solidity
constructor(address[] memory payees, uint256[] memory amountsOwed) public payable;
```

**Parameters**

| Name          | Type        | Description                                                                    |
| ------------- | ----------- | ------------------------------------------------------------------------------ |
| `payees`      | `address[]` | A list of wallet addresses representing the people that can receive money.     |
| `amountsOwed` | `uint256[]` | A list of WEI amounts representing the initial shares allocated to each payee. |

### release

This function allows a payee to claim their outstanding wei balance.

\*This function is designed to be called by payees to withdraw their share of
collected DAI. It performs the following actions:

1. Validates that the payee's outstanding wei balance (the difference between
   their total nr of "shares" and any previous releases) is greater than zero.
1. Calculates the amount to be paid to the payee by subtracting any previously
   released wei from their initial share.
1. Verifies that the calculated payment amount is greater than zero.
1. Updates the internal accounting for the payee's released wei and the total
   contract-wide released wei.
1. Transfers the calculated payment amount of wei to the payee's address using
   a secure `transfer` approach.
1. Emits a `PaymentReleased` event to log the payment details.
   Important Notes:\*\*
   Payees are responsible for calling this function to claim their outstanding
   balances.\*

```solidity
function release(address payable account) public override;
```

**Parameters**

| Name      | Type              | Description                                    |
| --------- | ----------------- | ---------------------------------------------- |
| `account` | `address payable` | The address of the payee requesting a release. |

### publicAddPayee

Public counterpart of the \_addPayee function, to add users that can withdraw
funds after constructor initialisation.

```solidity
function publicAddPayee(address account, uint256 dai_) public override onlyOwner;
```

### publicAddSharesToPayee

This function allows the contract owner to add additional "shares" to an existing payee.

\*This function increases the "share" allocation of a registered payee. It performs
the following actions:

1. Validates that the additional share amount (in WEI) is greater than zero.
1. Verifies that the payee address already exists in the `_dai` mapping (implicit
   through requirement check).
1. Updates the payee's share balance in the `_dai` mapping by adding the provided
   `dai` amount.
1. Updates the contract-wide total DAI amount by adding the provided `dai` amount.
1. Emits a `SharesAdded` event to log the details of the share increase.
   Important Notes:\*\*
   This function can only be called by the contract owner \_dim. It cannot be
   called by the projectLead.
   The payee must already be registered with the contract to receive additional
   shares.\*

```solidity
function publicAddSharesToPayee(address account, uint256 dai) public override onlyOwner;
```

**Parameters**

| Name      | Type      | Description                                                   |
| --------- | --------- | ------------------------------------------------------------- |
| `account` | `address` | The address of the payee to receive additional shares.        |
| `dai`     | `uint256` | The amount of additional DAI shares to be allocated (in WEI). |

### deposit

This function is used to deposit funds into the `CustomPaymentSplitter`
contract.

*This function allows anyone to deposit funds into the contract. It primarily
serves as a way to collect investment funds or other revenue streams. The function
logs the deposit details by emitting a `PaymentReceived` event.
Important Notes:*\*
There is no restriction on who can call this function.
TODO: Consider implementing access control mechanisms if only specific addresses
should be allowed to deposit funds. This may be important because some
business logic/balance checks may malfunction if unintentional funds come in.\*

```solidity
function deposit() public payable override;
```

### released

This function retrieves the total amount of wei that has already been released to a specific payee.

*This function is a view function, meaning it doesn't modify the contract's state. It returns the accumulated
amount of wei that has been released to the provided payee address.*

```solidity
function released(address account) public view override returns (uint256 amountReleased);
```

**Parameters**

| Name      | Type      | Description                                                            |
| --------- | --------- | ---------------------------------------------------------------------- |
| `account` | `address` | The address of the payee for whom to retrieve the released DAI amount. |

**Returns**

| Name             | Type      | Description                                             |
| ---------------- | --------- | ------------------------------------------------------- |
| `amountReleased` | `uint256` | The total amount of DAI (in WEI) released to the payee. |

### isPayee

This function verifies if a specified address is registered as a payee in the contract.

*This function is a view function and does not modify the contract's state. It iterates through the
internal `_payees` array to check if the provided `account` address exists within the list of registered payees.*

```solidity
function isPayee(address account) public view override returns (bool accountIsPayee);
```

**Parameters**

| Name      | Type      | Description                                              |
| --------- | --------- | -------------------------------------------------------- |
| `account` | `address` | The address to be checked against the registered payees. |

**Returns**

| Name             | Type   | Description                                                 |
| ---------------- | ------ | ----------------------------------------------------------- |
| `accountIsPayee` | `bool` | True if the address is a registered payee, False otherwise. |

### \_addPayee

This private function adds a new payee to the contract.

\*This function is private and can only be called by other functions within the contract. It performs the
following actions:

1. Validates that the payee address is not already registered (by checking if the corresponding `wei` share balance
   is zero).
1. Adds the payee's address to the internal `_payees` array.
1. Sets the payee's initial share balance in the `_dai` mapping.
1. Updates the contract-wide total DAI amount to reflect the addition of the new payee's share.
1. Emits a `PayeeAdded` event to log the details of the new payee.\*

```solidity
function _addPayee(address account, uint256 dai_) private;
```

**Parameters**

| Name      | Type      | Description                                               |
| --------- | --------- | --------------------------------------------------------- |
| `account` | `address` | The address of the payee to be added.                     |
| `dai_`    | `uint256` | The amount of wei allocated as the payee's initial share. |

## Events

### PayeeAdded

```solidity
event PayeeAdded(address indexed account, uint256 indexed dai);
```

### PaymentReleased

```solidity
event PaymentReleased(address indexed to, uint256 indexed amount);
```

### SharesAdded

```solidity
event SharesAdded(address indexed to, uint256 indexed amount);
```

### PaymentReceived

```solidity
event PaymentReceived(address indexed from, uint256 indexed amount);
```
