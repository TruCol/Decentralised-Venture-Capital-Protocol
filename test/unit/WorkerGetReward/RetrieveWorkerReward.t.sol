// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { Tier } from "../../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";
import { SaasPaymentProcessor } from "../../../src/SaasPaymentProcessor.sol";
import { Helper } from "../../../src/Helper.sol";
import { TierInvestment } from "../../../src/TierInvestment.sol";
import { CustomPaymentSplitter } from "../../../src/CustomPaymentSplitter.sol";
import { WorkerGetReward } from "../../../src/WorkerGetReward.sol";

interface Interface {
  function setUp() external;

  function testRetrieveTooLargeRewardForWorker() external;

  function testRetrieveWorkerRewardSuccessfully() external;
}

contract WorkerGetRewardTest is PRBTest, StdCheats, Interface {
  address internal _projectLeadAddress;
  address payable private _investorWallet;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  SaasPaymentProcessor private _saasPaymentProcessor;
  Helper private _helper;
  TierInvestment[] private _tierInvestments;
  ExposedDecentralisedInvestmentManager private _exposedDim;
  address payable private _investorWalletA;
  uint256 private _investmentAmount1;

  address[] private _withdrawers;
  uint256[] private _owedDai;

  WorkerGetReward private _workerGetReward;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Instantiate the attribute for the contract-under-test.
    _projectLeadAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    _projectLeadFracNumerator = 4;
    _projectLeadFracDenominator = 10;

    // Specify the investment tiers in ether.
    uint256 firstTierCeiling = 4 ether;
    uint256 secondTierCeiling = 15 ether;
    uint256 thirdTierCeiling = 30 ether;
    Tier tier0 = new Tier(0, firstTierCeiling, 10);
    _tiers.push(tier0);
    Tier tier1 = new Tier(firstTierCeiling, secondTierCeiling, 5);
    _tiers.push(tier1);
    Tier tier2 = new Tier(secondTierCeiling, thirdTierCeiling, 2);
    _tiers.push(tier2);

    // assertEq(address(_projectLeadAddress).balance, 43);
    _dim = new DecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress,
      12 weeks,
      3 ether
    );

    _workerGetReward = _dim.getWorkerGetReward();
  }

  function testRetrieveTooLargeRewardForWorker() public virtual override {
    // Retrieve 0 if worker can get 0.
    vm.expectRevert("Amount not larger than 0.");
    _workerGetReward.retreiveWorkerReward(0);

    // Retrieve 1 if worker can get 0.
    vm.expectRevert("Asked more reward than worker can get.");
    _workerGetReward.retreiveWorkerReward(1);

    // Retrieve 2 if worker can get 1.
    // Add retrievable of 1 wei to worker.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 8 weeks);
    vm.expectRevert("Asked more reward than worker can get.");
    _workerGetReward.retreiveWorkerReward(2);
  }

  function testRetrieveWorkerRewardSuccessfully() public virtual override {
    address workerAddress = address(0);

    _workerGetReward.addWorkerReward{ value: 2 }(workerAddress, 8 weeks);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 10 weeks);
    vm.prank(workerAddress);
    _workerGetReward.retreiveWorkerReward(2);

    // Assert worker can only retrieve reward once.
    vm.prank(workerAddress);
    vm.expectRevert("Asked more reward than worker can get.");
    _workerGetReward.retreiveWorkerReward(1);
  }
}
