// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25; // Specifies the Solidity compiler version.
error InvalidProjectLeadAddress(string message);
error ZeroRewardContribution(string message);
error InvalidRetrievalDuration(string message, uint256 requestedDuration, uint256 minDuration);
error InvalidRewardTransfer(string message, uint256 amount);

error InsufficientWorkerReward(string message, address worker, uint256 requestedAmount, uint256 availableReward);
error InsufficientContractBalance(string message, uint256 requestedAmount, uint256 availableBalance);

error UnauthorizedRewardRecovery(string message, address sender);
error InvalidRecoveryAmount(string message, uint256 requestedAmount);
error InsufficientFundsForTransfer(string message, uint256 requestedAmount, uint256 availableBalance);
error InvalidTimeManipulation(string message, uint256 attemptedRecoveryTime, uint256 allowedRecoveryTime);

interface IWorkerGetReward {
  function addWorkerReward(address worker, uint256 retrievalDuration) external payable;

  function retreiveWorkerReward(uint256 amount) external;

  function projectLeadRecoversRewards(uint256 amount) external;

  function getProjectLeadCanRecoverFromTime() external returns (uint256 projectLeadCanRecoverFrom);
}

contract WorkerGetReward is IWorkerGetReward {
  address private immutable _PROJECT_LEAD;
  uint256 private _projectLeadCanRecoverFrom;
  uint256 private immutable _MIN_RETRIEVAL_DURATION;
  // solhint-disable-next-line named-parameters-mapping
  mapping(address => uint256) private _rewards;

  /**
  @notice This function is the constructor used to create a new WorkerGetReward contract instance. This contract
  enables the project leader to allow workers to retrieve their payouts.

  @dev All parameters are set during construction and cannot be modified afterwards.

  @param projectLead The address of the project lead who can recover unclaimed rewards after a minimum duration.
  @param minRetrievalDuration The minimum duration a worker must wait before they can claim their rewards from the
  project lead.
  */
  // solhint-disable-next-line comprehensive-interface
  // solhint-disable-next-line comprehensive-interface
  constructor(address projectLead, uint256 minRetrievalDuration) {
    if (projectLead == address(0)) {
      revert InvalidProjectLeadAddress("Project lead address cannot be zero.");
    }

    _PROJECT_LEAD = projectLead;
    _MIN_RETRIEVAL_DURATION = minRetrievalDuration;
    // miners can manipulate time(stamps) seconds, not hours/days.
    // solhint-disable-next-line not-rely-on-time
    _projectLeadCanRecoverFrom = block.timestamp + _MIN_RETRIEVAL_DURATION;
    // Create mapping of worker rewards.
  }

  /**
  @notice This function allows the project lead to enable a worker to retrieve its payout.

  @dev The project lead must send Wei with the transaction and set a retrieval duration greater than or equal to the
  minimum retrieval duration set during construction. The retrieval duration determines how long a worker can wait
  before they claim their rewards from the project lead.
  This function also updates the project lead's earliest retrieval time if the new reward duration extends beyond
  the current time.

  This duration is to prevent funds from being locked up of a worker decides against picking up funds, e.g. because of
  tax reasons, losing credentials, or passing away.

  @param worker The address of the worker to be rewarded.
  @param retrievalDuration The amount of time (in seconds) the worker must wait before claiming their reward.
  */
  function addWorkerReward(address worker, uint256 retrievalDuration) public payable override {
    if (msg.value <= 0) {
      revert ZeroRewardContribution("Cannot contribute zero wei to worker reward.");
    }

    if (retrievalDuration < _MIN_RETRIEVAL_DURATION) {
      revert InvalidRetrievalDuration(
        "Retrieval duration must be greater than or equal to minimum duration.",
        retrievalDuration,
        _MIN_RETRIEVAL_DURATION
      );
    }

    // miners can manipulate time(stamps) seconds, not hours/days.
    // solhint-disable-next-line not-rely-on-time
    if (block.timestamp + retrievalDuration > _projectLeadCanRecoverFrom) {
      // miners can manipulate time(stamps) seconds, not hours/days.
      // solhint-disable-next-line not-rely-on-time
      _projectLeadCanRecoverFrom = block.timestamp + retrievalDuration;
    }
    _rewards[worker] += msg.value;
  }

  /**
  @notice This function allows a worker to retrieve their accumulated rewards.

  @dev A worker can only claim an amount up to their total accumulated rewards and what the contract currently holds.
  The function performs a transfer and checks the balance change to validate success.

  @param amount The amount of Wei the worker wishes to claim.
  */
  function retreiveWorkerReward(uint256 amount) public override {
    if (amount <= 0) {
      revert InvalidRewardTransfer("Reward amount must be greater than zero.", amount);
    }

    if (_rewards[msg.sender] < amount) {
      revert InsufficientWorkerReward("Insufficient worker reward balance.", msg.sender, amount, _rewards[msg.sender]);
    }

    if (address(this).balance < amount) {
      revert InsufficientContractBalance("Insufficient contract balance for payout.", amount, address(this).balance);
    }

    _rewards[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
    // TODO: require payment to be successful.
  }

  /**
  @notice  This function allows the project lead to recover any unclaimed rewards after the minimum retrieval duration
  has passed.

  @dev The project lead can only recover a non-zero amount up to the contract's current balance, and only after the
  pre-defined wait time has elapsed, ensuring workers have had a chance to claim their rewards first. The wait time is
  always the longest wait time required to facilitate the worker latest reward retrieval.

  @param amount The amount of Wei the project lead wishes to recover.
  */
  function projectLeadRecoversRewards(uint256 amount) public override {
    if (msg.sender != _PROJECT_LEAD) {
      revert UnauthorizedRewardRecovery("Only project lead can recover rewards.", msg.sender);
    }

    if (amount <= 0) {
      revert InvalidRecoveryAmount("Recovery amount must be greater than 0 wei.", amount);
    }

    if (address(this).balance < amount) {
      revert InsufficientFundsForTransfer("Insufficient contract balance for transfer.", amount, address(this).balance);
    }

    // solhint-disable-next-line not-rely-on-time
    if (block.timestamp <= _projectLeadCanRecoverFrom) {
      revert InvalidTimeManipulation(
        "Project lead attempted recovery before allowed time.",
        block.timestamp,
        _projectLeadCanRecoverFrom
      );
    }

    payable(_PROJECT_LEAD).transfer(amount);
  }

  /**
  @notice This function retrieves the timestamp at which the project lead can first recover unclaimed rewards.

  @dev This initial value is set during construction and is later updated by the maximum time at which any worker can
  still retrieve its reward.

  @return projectLeadCanRecoverFrom The timestamp (in seconds since epoch) at which the project lead can recover funds.
  */
  function getProjectLeadCanRecoverFromTime() public view override returns (uint256 projectLeadCanRecoverFrom) {
    projectLeadCanRecoverFrom = _projectLeadCanRecoverFrom;
    return projectLeadCanRecoverFrom;
  }
}
