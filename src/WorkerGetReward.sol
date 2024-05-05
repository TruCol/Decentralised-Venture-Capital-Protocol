// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

interface Interface {
  function addWorkerReward(address worker, uint256 retrievalDuration) external payable;

  function retreiveWorkerReward(uint256 amount) external;

  function projectLeadRecoversRewards(uint256 amount) external;

  function getProjectLeadCanRecoverFromTime() external returns (uint256 projectLeadCanRecoverFrom);
}

contract WorkerGetReward is Interface {
  address private _projectLead;

  uint256 private _projectLeadCanRecoverFrom;

  uint256 private _minRetrievalDuration;
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
  constructor(address projectLead, uint256 minRetrievalDuration) public {
    _projectLead = projectLead;
    _minRetrievalDuration = minRetrievalDuration;
    // miners can manipulate time(stamps) seconds, not hours/days.
    // solhint-disable-next-line not-rely-on-time
    _projectLeadCanRecoverFrom = block.timestamp + _minRetrievalDuration;
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
    require(msg.value > 0, "Tried to add 0 value to worker reward.");
    require(retrievalDuration >= _minRetrievalDuration, "Tried to set retrievalDuration below min.");
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
    require(amount > 0, "Amount not larger than 0.");
    require(_rewards[msg.sender] >= amount, "Asked more reward than worker can get.");
    require(address(this).balance >= amount, "Tried to payout more than the contract contains.");

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
    require(msg.sender == _projectLead, "Someone other than projectLead tried to recover rewards.");
    require(amount > 0, "Tried to recover 0 wei.");
    require(address(this).balance >= amount, "Tried to recover more than the contract contains.");
    require(
      // miners can manipulate time(stamps) seconds, not hours/days.
      // solhint-disable-next-line not-rely-on-time
      block.timestamp > _projectLeadCanRecoverFrom,
      "ProjectLead tried to recover funds before workers got the chance."
    );
    payable(_projectLead).transfer(amount);
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
