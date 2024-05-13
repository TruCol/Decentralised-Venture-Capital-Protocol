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
import { InitialiseDim } from "test/InitialiseDim.sol";

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
    uint256[] memory ceilings = new uint256[](3);
    ceilings[0] = 4 ether;
    ceilings[1] = 15 ether;
    ceilings[2] = 30 ether;
    uint8[] memory multiples = new uint8[](3);
    multiples[0] = 10;
    multiples[1] = 5;
    multiples[2] = 2;
    InitialiseDim initDim = new InitialiseDim({
      ceilings: ceilings,
      multiples: multiples,
      raisePeriod: 12 weeks,
      investmentTarget: 3 ether,
      projectLeadAddress: _projectLeadAddress,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();
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
