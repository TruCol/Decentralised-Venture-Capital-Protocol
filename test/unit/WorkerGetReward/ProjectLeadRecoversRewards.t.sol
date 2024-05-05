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

  function testRecoverRewardsWithNonProjectLeadAddress() external;

  function testRecoverMoreRewardThanContractContains() external;

  function testRecoverBeforeMinDurationHasPassed() external;

  function testRecoverBeforeMaxDurationHasPassed() external;

  function testRecoverRewardsWithProjectLead() external;
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

  function testRecoverRewardsWithNonProjectLeadAddress() public virtual override {
    vm.expectRevert("Someone other than projectLead tried to recover rewards.");
    _workerGetReward.projectLeadRecoversRewards(1);
  }

  function testRecoverMoreRewardThanContractContains() public virtual override {
    // Ask 0 when contract has 0.
    vm.prank(_projectLeadAddress);
    vm.expectRevert("Tried to recover 0 wei.");
    _workerGetReward.projectLeadRecoversRewards(0);

    // Ask 1 when contract has 0.
    vm.prank(_projectLeadAddress);
    vm.expectRevert("Tried to recover more than the contract contains.");
    _workerGetReward.projectLeadRecoversRewards(1);

    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 8 weeks);
    vm.prank(_projectLeadAddress);
    vm.expectRevert("Tried to recover more than the contract contains.");
    _workerGetReward.projectLeadRecoversRewards(2);
  }

  function testRecoverBeforeMinDurationHasPassed() public virtual override {
    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 3 }(workerAddress, 8 weeks);
    vm.prank(_projectLeadAddress);
    vm.expectRevert("ProjectLead tried to recover funds before workers got the chance.");
    _workerGetReward.projectLeadRecoversRewards(3);
    //
  }

  function testRecoverBeforeMaxDurationHasPassed() public virtual override {
    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 3 }(workerAddress, 12 weeks);
    vm.prank(_projectLeadAddress);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 12 weeks - 1);
    vm.expectRevert("ProjectLead tried to recover funds before workers got the chance.");
    _workerGetReward.projectLeadRecoversRewards(3);
  }

  function testRecoverRewardsWithProjectLead() public virtual override {
    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 3 }(workerAddress, 12 weeks);
    vm.prank(_projectLeadAddress);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 12 weeks + 1);
    // vm.expectRevert("ProjectLead tried to recover funds before workers got the chance.");
    _workerGetReward.projectLeadRecoversRewards(3);
  }
}
