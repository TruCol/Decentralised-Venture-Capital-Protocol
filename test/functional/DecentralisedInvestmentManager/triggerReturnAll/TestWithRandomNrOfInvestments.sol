// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;
/** The logging flow is described with:
    1. Initialise the mapping at all 0 values, and export those to file and set them in the struct.
  Loop:
    2. The values from the log file are read from file and overwrite those in the mapping.
    3. The code is ran, the mapping values are updated.
    4. The mapping values are logged to file.
*/

import { console2 } from "forge-std/src/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { Helper } from "../../../../src/Helper.sol";
import { TestMathHelper } from "test/TestMathHelper.sol";
import { TestInitialisationHelper } from "../../../TestInitialisationHelper.sol";
import { TestFileLogging } from "../../../TestFileLogging.sol";
import { TestIterableMapping } from "../../../TestIterableMapping.sol";
import { IterableMapping } from "../../../IterableMapping.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "test/TestConstants.sol";

interface IFuzzDebug {
  function setUp() external;

  function testRandomNrOfInvestments(
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint8 randNrOfInvestmentTiers,
    uint8 randNrOfInvestments,
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples,
    uint256[_MAX_NR_OF_INVESTMENTS] memory randomInvestments
  ) external;
}

contract FuzzDebug is PRBTest, StdCheats, IFuzzDebug {
  TestIterableMapping private _testIterableMapping;

  address internal _projectLead;
  TestInitialisationHelper private _testInitialisationHelper;
  TestFileLogging private _testFileLogging;
  Helper private _helper;
  TestMathHelper private _testMathHelper;
  string private _hitRateFilePath;

  function setUp() public virtual override {
    _helper = new Helper();
    _testInitialisationHelper = new TestInitialisationHelper();
    _testFileLogging = new TestFileLogging();
    _testMathHelper = new TestMathHelper();

    // Delete the temp file.
    if (vm.isFile(_LOG_TIME_CREATOR)) {
      vm.removeFile(_LOG_TIME_CREATOR);
    }
    _testIterableMapping = new TestIterableMapping();
  }

  /**
  @dev The investor has invested 0.5 eth, and the investment target is 0.6 eth after 12 weeks.
  So the investment target is not reached, so all the funds should be returned.
   */
  function testRandomNrOfInvestments(
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint8 randNrOfInvestmentTiers,
    uint8 randNrOfInvestments,
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples,
    uint256[_MAX_NR_OF_INVESTMENTS] memory randomInvestments
  ) public virtual override {
    // Declare variables used for initialisation of the dim contract.
    uint8[] memory multiples;
    uint256[] memory sameNrOfCeilings;
    uint256[] memory investmentAmounts;

    _testIterableMapping.readHitRatesFromLogFileAndSetToMap(_testIterableMapping.getHitRateFilePath());

    // Get a random number of random multiples and random ceilings by cutting off the random arrays of fixed length.
    (multiples, sameNrOfCeilings) = _testInitialisationHelper.getRandomMultiplesAndCeilings({
      randomCeilings: randomCeilings,
      randomMultiples: randomMultiples,
      randNrOfInvestmentTiers: randNrOfInvestmentTiers
    });

    investmentAmounts = _testMathHelper.getShortenedArray({
      someArray: randomInvestments,
      nrOfDesiredElements: randNrOfInvestments
    });

    if (!_testMathHelper.sumOfNrsThrowsOverFlow({ numbers: investmentAmounts })) {
      // Map the investment target to the range (0, maximum(Ceilings)) to ensure the investment target can be reached.
      investmentTarget = (investmentTarget % sameNrOfCeilings[sameNrOfCeilings.length - 1]) + 1;

      // Initialise the dim contract, if the random parameters are invalid, an non-random dim is initialised for typing.
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

      // Check if the initialised dim is random or non-random value.
      if (hasInitialisedRandomDim) {
        _testIterableMapping.set("validInitialisations", _testIterableMapping.get("validInitialisations") + 1);

        // Check if one is able to safely make the random number of investments safely.
        (uint256 successCount, uint256 failureCount) = _testInitialisationHelper.performRandomInvestments({
          dim: someDim,
          investmentAmounts: investmentAmounts
        });

        if (failureCount == 0) {
          // Compute cumulative investment.
          uint256 cumInvestmentAmount = _testMathHelper.computeSumOfArray({ numbers: investmentAmounts });

          // Store that this random run was for a valid investment, (track it to export it later).
          _testIterableMapping.set("validInvestments", _testIterableMapping.get("validInvestments") + 1);

          // Call the actual function that performs the test on the initialised dim contract.
          _followUpTriggerReturnAll({
            dim: someDim,
            projectLead: projectLead,
            cumInvestmentAmount: cumInvestmentAmount,
            investmentTarget: investmentTarget,
            additionalWaitPeriod: additionalWaitPeriod,
            raisePeriod: raisePeriod,
            maxTierCeiling: sameNrOfCeilings[sameNrOfCeilings.length - 1]
          });
        } else {
          _testIterableMapping.set("invalidInvestments", _testIterableMapping.get("invalidInvestments") + 1);
        }
      } else {
        // Store that this random run did not permit a valid dim initialisation.
        _testIterableMapping.set("invalidInitialisations", _testIterableMapping.get("invalidInitialisations") + 1);
      }
    } else {
      _testIterableMapping.set("investmentOverflow", _testIterableMapping.get("investmentOverflow") + 1);
    }

    _testIterableMapping.overwriteExistingMapLogFile(_testIterableMapping.getHitRateFilePath());
  }

  /**
  Tests whether the triggerReturnAll() function returns all funds from the dim contract if the investment ceiling is
  reached. Otherwise it verifies the triggerReturnAll() function throws an error saying the investment target is
  reached.

  To ensure the funds can be returned, the vm automatically simulates a fast forward of the time to beyond the raise
  period.
  @dev This is the actual test that this file executes. */
  // solhint-disable-next-line foundry-test-functions
  function _followUpTriggerReturnAll(
    DecentralisedInvestmentManager dim,
    address projectLead,
    uint256 investmentTarget,
    uint256 cumInvestmentAmount,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint256 maxTierCeiling // HitRatesReturnAll memory hitRates
  ) internal {
    if (cumInvestmentAmount >= investmentTarget) {
      // Track that the investment ceiling was reached.
      _testIterableMapping.set("didReachInvestmentCeiling", _testIterableMapping.get("didReachInvestmentCeiling") + 1);

      // Only the projectLead can trigger the return of all funds.
      vm.prank(projectLead);

      // For testing purposes, time is simulated to beyond the raise period. Another test will test calls before the raise period.
      // solhint-disable-next-line not-rely-on-time
      vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);

      // If the investment target is reached, the funds should not be returnable, because the project lead should
      // ensure the work is done to retrieve the funds.
      vm.expectRevert(
        abi.encodeWithSignature(
          "InvestmentTargetReached(string,uint256,uint256)",
          "Investment target reached!",
          _helper.minimum(maxTierCeiling, cumInvestmentAmount),
          investmentTarget
        )
      );
      dim.triggerReturnAll();
    } else {
      // Track that the investment ceiling was not reached by the randnom values.
      _testIterableMapping.set(
        "didNotreachInvestmentCeiling",
        _testIterableMapping.get("didNotreachInvestmentCeiling") + 1
      );

      // TODO: Verify the dim contract contains the investment funds.
      vm.prank(projectLead);
      // solhint-disable-next-line not-rely-on-time
      vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);
      dim.triggerReturnAll();

      // Verify the funds from the dim contract were not in the dim contract anymore.
      assertEq(address(dim).balance, 0 ether, "The dim did not contain 0 ether after returning all investments.");

      // TODO: verify the investors have retrieved their investments.
    }
  }
}
