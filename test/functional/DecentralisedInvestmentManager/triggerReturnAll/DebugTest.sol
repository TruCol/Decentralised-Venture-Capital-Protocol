// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { Helper } from "../../../../src/Helper.sol";

import { TestInitialisationHelper } from "../../../TestInitialisationHelper.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "test/TestConstants.sol";

interface IFuzzDebug {
  function setUp() external;

  function testFuzzDebug(
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint256 firstInvestmentAmount,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint8 randNrOfInvestmentTiers,
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples
  ) external;
}

/**
Tests whether the dim.triggerReturnAll() function ensures the investments are:
- returned if the investment target is not reached, after the raisePeriod has passed.
- not returned if the investment target is reached, after the raisePeriod has passed.
TODO: test whether the investments are:
- not returned if the investment target is not reached, before the raisePeriod has passed.
- not returned if the investment target is reached, before the raisePeriod has passed.
*/
contract FuzzDebug is PRBTest, StdCheats, IFuzzDebug {
  address internal _projectLead;
  TestInitialisationHelper private _testInitialisationHelper;
  Helper private _helper;
  uint256 private _validInitialisationCounter;
  uint256 private _validInvestmentCounter;
  uint256 private _testRunsCounter;

  function setUp() public virtual override {
    _helper = new Helper();
    _testInitialisationHelper = new TestInitialisationHelper();
    // _testRunsCounter = 0;
    // _validInitialisationCounter = 0;
    // _validInvestmentCounter = 0;
  }

  /**
  @dev The investor has invested 0.5 eth, and the investment target is 0.6 eth after 12 weeks.
  So the investment target is not reached, so all the funds should be returned.
   */
  function testFuzzDebug(
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint256 firstInvestmentAmount,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint8 randNrOfInvestmentTiers,
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples
  ) public virtual override {
    uint8[] memory multiples;
    uint256[] memory sameNrOfCeilings;
    (multiples, sameNrOfCeilings) = _testInitialisationHelper.getRandomMultiplesAndCeilings({
      randomCeilings: randomCeilings,
      randomMultiples: randomMultiples,
      randNrOfInvestmentTiers: randNrOfInvestmentTiers
    });
    investmentTarget = (investmentTarget % sameNrOfCeilings[sameNrOfCeilings.length - 1]) + 1;
    ++_testRunsCounter;
    (bool hasInitialisedRandomDim, DecentralisedInvestmentManager someDim) = _testInitialisationHelper
      .initialiseRandomDim({
        projectLead: projectLead,
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        raisePeriod: raisePeriod,
        investmentTarget: investmentTarget,
        ceilings: sameNrOfCeilings,
        multiples: multiples
      });
    if (hasInitialisedRandomDim) {
      ++_validInitialisationCounter;

      // Generate a non-random investor wallet address and make an investment.
      address payable firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
      if (
        _testInitialisationHelper.safelyInvest({
          dim: someDim,
          someInvestmentAmount: firstInvestmentAmount,
          someInvestorWallet: firstInvestorWallet
        })
      ) {
        ++_validInvestmentCounter;
        _followUpTriggerReturnAll({
          dim: someDim,
          projectLead: projectLead,
          firstInvestmentAmount: firstInvestmentAmount,
          investmentTarget: investmentTarget,
          additionalWaitPeriod: additionalWaitPeriod,
          raisePeriod: raisePeriod,
          maxTierCeiling: sameNrOfCeilings[sameNrOfCeilings.length - 1]
        });
      }
    }

    emit Log("_validInitialisationCounter=");
    emit Log(Strings.toString(_validInitialisationCounter));

    emit Log("_validInvestmentCounter=");
    emit Log(Strings.toString(_validInvestmentCounter));

    emit Log("_testRunsCounter=");
    emit Log(Strings.toString(_testRunsCounter));
  }

  function _followUpTriggerReturnAll(
    DecentralisedInvestmentManager dim,
    address projectLead,
    uint256 investmentTarget,
    uint256 firstInvestmentAmount,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint256 maxTierCeiling
  ) internal {
    if (firstInvestmentAmount >= investmentTarget) {
      vm.prank(projectLead);
      // solhint-disable-next-line not-rely-on-time
      vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);
      vm.expectRevert(
        abi.encodeWithSignature(
          "InvestmentTargetReached(string,uint256,uint256)",
          "Investment target reached!",
          _helper.minimum(maxTierCeiling, firstInvestmentAmount),
          investmentTarget
        )
      );
      dim.triggerReturnAll();
    } else {
      vm.prank(projectLead);
      // solhint-disable-next-line not-rely-on-time
      vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);
      dim.triggerReturnAll();
      assertEq(address(dim).balance, 0 ether, "The dim did not contain 0 ether after returning all investments.");
    }
  }
}
