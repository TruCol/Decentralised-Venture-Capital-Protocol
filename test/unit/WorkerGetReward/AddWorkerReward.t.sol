// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { Tier } from "../../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";
import { SaasPaymentProcessor } from "../../../src/SaasPaymentProcessor.sol";
import { Helper } from "../../../src/Helper.sol";
import { TierInvestment } from "../../../src/TierInvestment.sol";
import { WorkerGetReward } from "../../../src/WorkerGetReward.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface IAddWorkerRewardTest {
  function setUp() external;

  function testAddWorkerRewardOfZero() external;

  function addWorkerRewardWithTooLowDuration() external;

  function addWorkerRewardValid() external;

  function testProjectLeadRecoverDateIsExtended() external;

  function testProjectLeadRecoverDateIsNotExtended() external;

  function testSetRetrievalDurationBelowMin() external;
}

contract AddWorkerRewardTest is PRBTest, StdCheats, IAddWorkerRewardTest {
  address internal _projectLead;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  SaasPaymentProcessor private _saasPaymentProcessor;
  Helper private _helper;
  TierInvestment[] private _tierInvestments;
  ExposedDecentralisedInvestmentManager private _exposedDim;
  uint256 private _investmentAmount1;

  address[] private _withdrawers;
  uint256[] private _owedDai;

  WorkerGetReward private _workerGetReward;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Instantiate the attribute for the contract-under-test.
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
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
      projectLead: _projectLead,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();

    _workerGetReward = _dim.getWorkerGetReward();
  }

  function testAddWorkerRewardOfZero() public virtual override {
    address workerAddress = address(0);
    // vm.deal(address(this),5 ether);
    vm.expectRevert("Tried to add 0 value to worker reward.");
    _workerGetReward.addWorkerReward{ value: 0 }(workerAddress, 5 weeks);
  }

  function addWorkerRewardWithTooLowDuration() public virtual override {
    address workerAddress = address(0);
    // vm.deal(address(this),5 ether);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 4 weeks - 1);
    vm.expectRevert("Tried to set retrievalDuratin below min.");
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 5 weeks);
  }

  function addWorkerRewardValid() public virtual override {
    address workerAddress = address(0);

    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 4 weeks);
    vm.expectRevert("Tried to set retrievalDuratin below min.");
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 5 weeks);
  }

  function testProjectLeadRecoverDateIsExtended() public virtual override {
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 8 weeks);
    // solhint-disable-next-line not-rely-on-time
    assertEq(_workerGetReward.getProjectLeadCanRecoverFromTime(), block.timestamp + 8 weeks);
  }

  function testProjectLeadRecoverDateIsNotExtended() public virtual override {
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 12 weeks);
    // solhint-disable-next-line not-rely-on-time
    assertEq(_workerGetReward.getProjectLeadCanRecoverFromTime(), block.timestamp + 12 weeks);
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 8 weeks);
    // solhint-disable-next-line not-rely-on-time
    assertEq(_workerGetReward.getProjectLeadCanRecoverFromTime(), block.timestamp + 12 weeks);
  }

  function testSetRetrievalDurationBelowMin() public virtual override {
    address workerAddress = address(0);
    vm.expectRevert("Tried to set retrievalDuration below min.");
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 7 weeks);
  }
}
