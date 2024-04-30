// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import "forge-std/src/console2.sol"; // Import the console library

interface Interface {
  function addWorkerReward(address worker, uint256 retrievalDuration) external payable;

  function retreiveWorkerReward(uint256 amount) external;

  function projectLeadRecoversRewards(uint256 amount) external;

  function getProjectLeadCanRecoverFromTime() external returns (uint256);
}

contract WorkerGetReward is Interface {
  address private _projectLead;

  uint256 private _projectLeadCanRecoverFrom;

  uint256 private _minRetrievalDuration;
  mapping(address => uint256) private _rewards;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(address projectLead, uint256 minRetrievalDuration) public {
    _projectLead = projectLead;
    _minRetrievalDuration = minRetrievalDuration;
    _projectLeadCanRecoverFrom = block.timestamp + _minRetrievalDuration;
    // Create mapping of worker rewards.
  }

  /**
  TODO: add duration to set minimum projectLead Recover fund date. Ensure project lead cannot
  retrieve funds any earlier. */
  function addWorkerReward(address worker, uint256 retrievalDuration) public payable override {
    require(msg.value > 0, "Tried to add 0 value to worker reward.");
    require(retrievalDuration >= _minRetrievalDuration, "Tried to set retrievalDuration below min.");
    if (block.timestamp + retrievalDuration > _projectLeadCanRecoverFrom) {
      _projectLeadCanRecoverFrom = block.timestamp + retrievalDuration;
    }
    _rewards[worker] += msg.value;
  }

  /**
  TODO: ensure the worker cannot retrieve funds twice, and test it. */
  function retreiveWorkerReward(uint256 amount) public override {
    require(amount > 0, "Amount not larger than 0.");
    require(_rewards[msg.sender] >= amount, "Asked more reward than worker can get.");
    require(address(this).balance >= amount, "Tried to payout more than the contract contains.");

    uint256 beforeBalance = msg.sender.balance;
    payable(msg.sender).transfer(amount);
    _rewards[msg.sender] -= amount;
    uint256 afterBalance = msg.sender.balance;
    require(afterBalance - beforeBalance == amount, "Worker reward not transferred successfully.");
  }

  function projectLeadRecoversRewards(uint256 amount) public override {
    require(msg.sender == _projectLead, "Someone other than projectLead tried to recover rewards.");
    require(amount > 0, "Tried to recover 0 wei.");
    require(address(this).balance >= amount, "Tried to recover more than the contract contains.");
    require(
      block.timestamp > _projectLeadCanRecoverFrom,
      "ProjectLead tried to recover funds before workers got the chance."
    );
    payable(_projectLead).transfer(amount);
  }

  function getProjectLeadCanRecoverFromTime() public view override returns (uint256) {
    return _projectLeadCanRecoverFrom;
  }
}
