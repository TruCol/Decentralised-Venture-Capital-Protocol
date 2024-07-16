// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { Helper } from "../../../../src/Helper.sol";

import { TestInitialisationHelper } from "../../../TestInitialisationHelper.sol";
import { TestFileLogging } from "../../../TestFileLogging.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "test/TestConstants.sol";
import { VmSafe } from "forge-std/src/Vm.sol";

/**
Stores the counters used to track how often the different branches of the tests are covered.*/
struct HitRatesReturnAll {
  uint256 didNotreachInvestmentCeiling;
  uint256 didReachInvestmentCeiling;
  uint256 validInitialisations;
  uint256 validInvestments;
  uint256 invalidInitialisations;
}

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
    uint8 randNrOfInvestments,
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples,
    uint8[_MAX_NR_OF_TIERS] memory randomInvestments
  ) external;
}

contract FuzzDebug is PRBTest, StdCheats, IFuzzDebug {
  address internal _projectLead;
  TestInitialisationHelper private _testInitialisationHelper;
  TestFileLogging private _testFileLogging;
  Helper private _helper;

  /**
  @dev This is a function stores the log elements used to verify each test case in the fuzz test is reached.
   */
  function convertHitRatesToString(
    HitRatesReturnAll memory hitRates
  ) public returns (string memory serialisedTextString) {
    string memory obj1 = "ThisValueDissapearsIntoTheVoid";
    vm.serializeUint(obj1, "invalidInitialisations", hitRates.invalidInitialisations);
    vm.serializeUint(obj1, "validInitialisations", hitRates.validInitialisations);
    vm.serializeUint(obj1, "validInvestments", hitRates.validInvestments);
    vm.serializeUint(obj1, "didReachInvestmentCeiling", hitRates.didReachInvestmentCeiling);
    serialisedTextString = vm.serializeUint(
      obj1,
      "didNotreachInvestmentCeiling",
      hitRates.didNotreachInvestmentCeiling
    );
    return serialisedTextString;
  }

  /**
@dev Creates an empty struct with the counters for each test case set to 0. */
  function initialiseHitRates() public pure returns (HitRatesReturnAll memory hitRates) {
    return
      HitRatesReturnAll({
        didNotreachInvestmentCeiling: 0,
        didReachInvestmentCeiling: 0,
        validInitialisations: 0,
        validInvestments: 0,
        invalidInitialisations: 0
      });
  }

  /**
@dev Ensures the struct with the log data for this test file is exported into a log file if it does not yet exist.
Afterwards, it can load that new file.
 */
  function createLogIfNotExistAndReadLogData()
    public
    returns (string memory hitRateFilePath, HitRatesReturnAll memory hitRates)
  {
    hitRates = initialiseHitRates();
    // Output hit rates to file if they do not exist yet.
    string memory serialisedTextString = convertHitRatesToString(hitRates);
    hitRateFilePath = _testFileLogging.createLogFileIfItDoesNotExist(_LOG_TIME_CREATOR, serialisedTextString);
    // Read the latest hitRates from file.
    bytes memory data = _testFileLogging.readDataFromFile(hitRateFilePath);
    hitRates = abi.decode(data, (HitRatesReturnAll));

    return (hitRateFilePath, hitRates);
  }

  function setUp() public virtual override {
    _helper = new Helper();
    _testInitialisationHelper = new TestInitialisationHelper();
    _testFileLogging = new TestFileLogging();
    // Delete the temp file.
    if (vm.isFile(_LOG_TIME_CREATOR)) {
      vm.removeFile(_LOG_TIME_CREATOR);
    }
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
    uint8 randNrOfInvestments,
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples,
    uint8[_MAX_NR_OF_TIERS] memory randomInvestments
  ) public virtual override {
    // Declare variables used for initialisation of the dim contract.
    uint8[] memory multiples;
    uint256[] memory sameNrOfCeilings;

    // Initialise the hit rate counter and accompanying logfile.
    (string memory hitRateFilePath, HitRatesReturnAll memory hitRates) = createLogIfNotExistAndReadLogData();

    // Get a random number of random multiples and random ceilings by cutting off the random arrays of fixed length.
    (multiples, sameNrOfCeilings) = _testInitialisationHelper.getRandomMultiplesAndCeilings({
      randomCeilings: randomCeilings,
      randomMultiples: randomMultiples,
      randNrOfInvestmentTiers: randNrOfInvestmentTiers
    });
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
      ++hitRates.validInitialisations;

      // TODO: Generate a non-random investor wallet address and make an investment.
      address payable firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));

      // Check if one is able to safely make the investments.
      // TODO: convert into random number of investments.
      if (
        _testInitialisationHelper.safelyInvest({
          dim: someDim,
          someInvestmentAmount: firstInvestmentAmount,
          someInvestorWallet: firstInvestorWallet
        })
      ) {
        // Store that this random run was for a valid investment, (track it to export it later).
        ++hitRates.validInvestments;

        // Call the actual function that performs the test on the initialised dim contract.
        _followUpTriggerReturnAll({
          dim: someDim,
          projectLead: projectLead,
          firstInvestmentAmount: firstInvestmentAmount,
          investmentTarget: investmentTarget,
          additionalWaitPeriod: additionalWaitPeriod,
          raisePeriod: raisePeriod,
          maxTierCeiling: sameNrOfCeilings[sameNrOfCeilings.length - 1],
          hitRates: hitRates
        });
      } // TODO: else track invalid investment.
    } else {
      // Store that this random run did not permit a valid dim initialisation.
      ++hitRates.invalidInitialisations;
    }
    emit Log("Outputting File");
    string memory serialisedTextString = convertHitRatesToString(hitRates);
    _testFileLogging.overwriteFileContent(serialisedTextString, hitRateFilePath);
    emit Log("Outputted File");
  }

  /**
  Tests whether the triggerReturnAll() function returns all funds from the dim contract if the investment ceiling is
  reached. Otherwise it verifies the triggerReturnAll() function throws an error saying the investment target is
  reached.

  To ensure the funds can be returned, the vm automatically simulates a fast forward of the time to beyond the raise
  period.
  @dev This is the actual test that this file executes. */
  function _followUpTriggerReturnAll(
    DecentralisedInvestmentManager dim,
    address projectLead,
    uint256 investmentTarget,
    uint256 firstInvestmentAmount,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint256 maxTierCeiling,
    HitRatesReturnAll memory hitRates
  ) internal {
    if (firstInvestmentAmount >= investmentTarget) {
      // Track that the investment ceiling was reached.
      ++hitRates.didReachInvestmentCeiling;

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
          _helper.minimum(maxTierCeiling, firstInvestmentAmount),
          investmentTarget
        )
      );
      dim.triggerReturnAll();
    } else {
      // Track that the investment ceiling was not reached by the randnom values.
      ++hitRates.didNotreachInvestmentCeiling;

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
