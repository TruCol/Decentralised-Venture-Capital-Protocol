# WorkerGetReward

[Git Source](https://github.com/TruCol/Decentralised-Saas-Investment-Protocol/blob/261eef1ab2997c2de78fe153ea0697c80fbc509d/src/WorkerGetReward.sol)

**Inherits:**
[Interface](/src/CustomPaymentSplitter.sol/interface.Interface.md)

## State Variables

### \_projectLead

```solidity
address private _projectLead;
```

### \_projectLeadCanRecoverFrom

```solidity
uint256 private _projectLeadCanRecoverFrom;
```

### \_minRetrievalDuration

```solidity
uint256 private _minRetrievalDuration;
```

### \_rewards

```solidity
mapping(address => uint256) private _rewards;
```

## Functions

### constructor

This function is the constructor used to create a new WorkerGetReward contract instance. This contract
enables the project leader to allow workers to retrieve their payouts.

*All parameters are set during construction and cannot be modified afterwards.*

```solidity
constructor(address projectLead, uint256 minRetrievalDuration) public;
```

**Parameters**

| Name                   | Type      | Description                                                                                        |
| ---------------------- | --------- | -------------------------------------------------------------------------------------------------- |
| `projectLead`          | `address` | The address of the project lead who can recover unclaimed rewards after a minimum duration.        |
| `minRetrievalDuration` | `uint256` | The minimum duration a worker must wait before they can claim their rewards from the project lead. |

### addWorkerReward

This function allows the project lead to enable a worker to retrieve its payout.

*The project lead must send Wei with the transaction and set a retrieval duration greater than or equal to the
minimum retrieval duration set during construction. The retrieval duration determines how long a worker can wait
before they claim their rewards from the project lead.
This function also updates the project lead's earliest retrieval time if the new reward duration extends beyond
the current time.
This duration is to prevent funds from being locked up of a worker decides against picking up funds, e.g. because of
tax reasons, losing credentials, or passing away.*

```solidity
function addWorkerReward(address worker, uint256 retrievalDuration) public payable override;
```

**Parameters**

| Name                | Type      | Description                                                                        |
| ------------------- | --------- | ---------------------------------------------------------------------------------- |
| `worker`            | `address` | The address of the worker to be rewarded.                                          |
| `retrievalDuration` | `uint256` | The amount of time (in seconds) the worker must wait before claiming their reward. |

### retreiveWorkerReward

This function allows a worker to retrieve their accumulated rewards.

*A worker can only claim an amount up to their total accumulated rewards and what the contract currently holds.
The function performs a transfer and checks the balance change to validate success.*

```solidity
function retreiveWorkerReward(uint256 amount) public override;
```

**Parameters**

| Name     | Type      | Description                                   |
| -------- | --------- | --------------------------------------------- |
| `amount` | `uint256` | The amount of Wei the worker wishes to claim. |

### projectLeadRecoversRewards

This function allows the project lead to recover any unclaimed rewards after the minimum retrieval duration
has passed.

*The project lead can only recover a non-zero amount up to the contract's current balance, and only after the
pre-defined wait time has elapsed, ensuring workers have had a chance to claim their rewards first. The wait time is
always the longest wait time required to facilitate the worker latest reward retrieval.*

```solidity
function projectLeadRecoversRewards(uint256 amount) public override;
```

**Parameters**

| Name     | Type      | Description                                           |
| -------- | --------- | ----------------------------------------------------- |
| `amount` | `uint256` | The amount of Wei the project lead wishes to recover. |

### getProjectLeadCanRecoverFromTime

This function retrieves the timestamp at which the project lead can first recover unclaimed rewards.

*This initial value is set during construction and is later updated by the maximum time at which any worker can
still retrieve its reward.*

```solidity
function getProjectLeadCanRecoverFromTime() public view override returns (uint256);
```

**Returns**

| Name     | Type      | Description                                                                                                     |
| -------- | --------- | --------------------------------------------------------------------------------------------------------------- |
| `<none>` | `uint256` | \_projectLeadCanRecoverFrom The timestamp (in seconds since epoch) at which the project lead can recover funds. |
