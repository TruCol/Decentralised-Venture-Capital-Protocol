// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
struct Reward {
  uint256 _reward;
  uint256 _releaseDate;
}

interface Interface {
  function getOwner() external view returns (address);

  function addWorkerReward(address worker) external payable;

  function retreiveWorkerReward(uint256 amount) external;
}

contract WorkerGetReward is Interface {
  address private _projectLead;
  address private _owner;

  uint256 private _minRetrievalDuration;
  mapping(address => uint256) private _rewards;

  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "The message is sent by someone other than the owner of this contract.");
    _;
  }

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(address projectLead, uint256 minRetrievalDuration) public {
    _owner = msg.sender;
    _projectLead = projectLead;
    _minRetrievalDuration = minRetrievalDuration;

    // Create mapping of worker rewards.
  }

  /**
  TODO: add duration to set minimum projectLead Recover fund date. Ensure project lead cannot
  retrieve funds any earlier. */
  function addWorkerReward(address worker) public payable override {
    require(msg.sender == _owner);
    require(msg.value > 0, "Tried to add 0 value to worker reward.");
    _rewards[worker] += msg.value;
  }

  function retreiveWorkerReward(uint256 amount) public override {
    require(_rewards[msg.sender] >= amount, "Asked more reward than worker can get.");
    require(address(this).balance >= amount, "Tried to payout more than the contract contains.");

    uint256 beforeBalance = msg.sender.balance;
    payable(msg.sender).transfer(amount);
    uint256 afterBalance = msg.sender.balance;
    require(afterBalance - beforeBalance == amount, "Worker reward not transferred successfully.");
  }

  function getOwner() public view override returns (address) {
    return _owner;
  }
}
