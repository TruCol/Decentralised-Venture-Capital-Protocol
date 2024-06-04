// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;
// import "../StdJson.sol";
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
  TestFileLogging private _testFileLogging;
  Helper private _helper;
  HitRatesReturnAll private _hitRates;

  function converthitRatesToString(
    string memory path,
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

  function createLogFile(string memory tempFileName) public returns (string memory hitRateFilePath) {
    // TODO: initialise the _hitRate struct, if the file in which it will be stored, does not yet exist.
    _hitRates = initialiseHitRates();
    string memory serialisedTextString = converthitRatesToString(hitRateFilePath, _hitRates);
    // TODO: convert hitRates to serialised String

    uint256 timeStamp = _testFileLogging.createFileIfNotExists(serialisedTextString, tempFileName);
    string memory logDir = string(abi.encodePacked("test_logging/", Strings.toString(timeStamp)));
    hitRateFilePath = string(abi.encodePacked(logDir, "/DebugTest.txt"));
    if (!vm.isFile(hitRateFilePath)) {
      _hitRates = initialiseHitRates();

      // Create logging structure
      vm.createDir(logDir, true);
      string memory serialisedTextString = converthitRatesToString(hitRateFilePath, _hitRates);
      _testFileLogging.overwriteFileContent(serialisedTextString, hitRateFilePath);

      // Assort logging file exists.
      if (!vm.isFile(hitRateFilePath)) {
        revert("LogFile not created.");
      }
    } else {
      bytes memory data = _testFileLogging.readDataFromFile(hitRateFilePath);
      _hitRates = abi.decode(data, (HitRatesReturnAll));
    }
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
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples
  ) public virtual override {
    uint8[] memory multiples;
    uint256[] memory sameNrOfCeilings;
    emit Log("Start fuzz");
    string memory hitRateFilePath = createLogFile(_LOG_TIME_CREATOR);

    emit Log("Read File");
    (multiples, sameNrOfCeilings) = _testInitialisationHelper.getRandomMultiplesAndCeilings({
      randomCeilings: randomCeilings,
      randomMultiples: randomMultiples,
      randNrOfInvestmentTiers: randNrOfInvestmentTiers
    });
    investmentTarget = (investmentTarget % sameNrOfCeilings[sameNrOfCeilings.length - 1]) + 1;

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
      ++_hitRates.validInitialisations;
      // Generate a non-random investor wallet address and make an investment.
      address payable firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
      if (
        _testInitialisationHelper.safelyInvest({
          dim: someDim,
          someInvestmentAmount: firstInvestmentAmount,
          someInvestorWallet: firstInvestorWallet
        })
      ) {
        ++_hitRates.validInvestments;
        _followUpTriggerReturnAll({
          dim: someDim,
          projectLead: projectLead,
          firstInvestmentAmount: firstInvestmentAmount,
          investmentTarget: investmentTarget,
          additionalWaitPeriod: additionalWaitPeriod,
          raisePeriod: raisePeriod,
          maxTierCeiling: sameNrOfCeilings[sameNrOfCeilings.length - 1]
          // _hitRates: _hitRates
        });
      }
    } else {
      ++_hitRates.invalidInitialisations;
    }
    emit Log("Outputting File");
    string memory serialisedTextString = converthitRatesToString(hitRateFilePath, _hitRates);
    _testFileLogging.overwriteFileContent(serialisedTextString, hitRateFilePath);
    emit Log("Outputted File");
  }

  function _followUpTriggerReturnAll(
    DecentralisedInvestmentManager dim,
    address projectLead,
    uint256 investmentTarget,
    uint256 firstInvestmentAmount,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint256 maxTierCeiling // HitRatesReturnAll memory _hitRates
  ) internal {
    if (firstInvestmentAmount >= investmentTarget) {
      ++_hitRates.didReachInvestmentCeiling;
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
      ++_hitRates.didNotreachInvestmentCeiling;
      vm.prank(projectLead);
      // solhint-disable-next-line not-rely-on-time
      vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);
      dim.triggerReturnAll();
      assertEq(address(dim).balance, 0 ether, "The dim did not contain 0 ether after returning all investments.");
    }
  }
}
