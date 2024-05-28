// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { Helper } from "../../../../src/Helper.sol";
import { TestMathHelper } from "../../../TestMathHelper.sol";
import { TestInitialisationHelper } from "../../../TestInitialisationHelper.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
uint32 constant _MAX_NR_OF_TIERS = 100;

interface IFuzzTriggerReturnAll {
  function setUp() external;

  function getRandomMultiplesAndCeilings(
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples,
    uint8 randNrOfInvestmentTiers
  ) external returns (uint8[] memory multiples, uint256[] memory sameNrOfCeilings);

  function testFuzzTriggerReturnAll(
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
contract FuzzTriggerReturnAll is PRBTest, StdCheats, IFuzzTriggerReturnAll {
  address internal _projectLead;
  TestMathHelper private _testMathHelper;
  TestInitialisationHelper private _testInitialisationHelper;
  Helper private _helper;

  function setUp() public virtual override {
    _testMathHelper = new TestMathHelper();
    _helper = new Helper();
    _testInitialisationHelper = new TestInitialisationHelper();
  }

  /**
   * @notice Generates random multiples and corresponding ceiling values for a specified number of investment tiers.
   * @dev This function selects a random subset of unique investment ceilings and ensures
   * multiples are greater than 1. It leverages helper functions for sorting, uniquing,
   * and minimum/maximum calculations.
   *
   * @param randomCeilings An array of random ceiling values (unused length, replaced with actual length).
   * @param randomMultiples An array of random multiples (unused length, replaced with actual length).
   * @param randNrOfInvestmentTiers The randomly chosen number of investment tiers.
   *
   * @return multiples A dynamic array containing the selected random multiples.
   * @return sameNrOfCeilings A dynamic array containing the corresponding unique ceiling values for each tier.
   */
  function getRandomMultiplesAndCeilings(
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples,
    uint8 randNrOfInvestmentTiers
  ) public virtual override returns (uint8[] memory multiples, uint256[] memory sameNrOfCeilings) {
    uint256 nrOfRandomCeilings = randomCeilings.length; // TODO: change this to _MAX_NR_OF_TIERS.
    // Change the fixed array length from _MAX_NR_OF_TIERS to array of variable length (dynamic array).
    uint256[] memory duplicateCeilings = new uint256[](nrOfRandomCeilings);
    for (uint256 i = 0; i < nrOfRandomCeilings; ++i) {
      // +1 to ensure a ceiling of 0 is shifted to a minimum of 1.
      duplicateCeilings[i] = _testMathHelper.maximum(1, randomCeilings[i]);
    }
    // Removes duplicate values and sorts the ceilings from small to large.
    uint256[] memory ceilings = _testMathHelper.getSortedUniqueArray(duplicateCeilings);

    // From the selected unique, ascending Tier investment ceilings, select subset of random size.
    uint256 nrOfInvestmentTiers = (randNrOfInvestmentTiers % ceilings.length) + 1;
    // Recreate the multiples and ceilings of the selected random size (nr. of Tiers).
    multiples = new uint8[](nrOfInvestmentTiers);
    sameNrOfCeilings = new uint256[](nrOfInvestmentTiers);
    for (uint256 i = 0; i < nrOfInvestmentTiers; ++i) {
      multiples[i] = uint8(_testMathHelper.maximum(2, randomMultiples[i])); // Filter out the 0 and 1 values.
      sameNrOfCeilings[i] = ceilings[i];
    }

    return (multiples, sameNrOfCeilings);
  }

  /**
  @dev The investor has invested 0.5 eth, and the investment target is 0.6 eth after 12 weeks.
  So the investment target is not reached, so all the funds should be returned.
   */
  function testFuzzTriggerReturnAll(
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
    (multiples, sameNrOfCeilings) = getRandomMultiplesAndCeilings({
      randomCeilings: randomCeilings,
      randomMultiples: randomMultiples,
      randNrOfInvestmentTiers: randNrOfInvestmentTiers
    });
    investmentTarget = (investmentTarget % sameNrOfCeilings[sameNrOfCeilings.length - 1]) + 1;
    //projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    if (
      _testInitialisationHelper.canInitialiseRandomDim({
        projectLead: projectLead,
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        raisePeriod: raisePeriod,
        investmentTarget: investmentTarget,
        ceilings: sameNrOfCeilings,
        multiples: multiples
      })
    ) {
      projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

      InitialiseDim initDim = new InitialiseDim({
        ceilings: sameNrOfCeilings,
        multiples: multiples,
        investmentTarget: investmentTarget,
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        projectLead: projectLead,
        raisePeriod: raisePeriod
      });
      DecentralisedInvestmentManager dim = initDim.getDim();

      // Generate a non-random investor wallet address and make an investment.
      address payable firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
      if (
        _testInitialisationHelper.safelyInvest({
          dim: dim,
          someInvestmentAmount: firstInvestmentAmount,
          someInvestorWallet: firstInvestorWallet
        })
      ) {
        _followUpTriggerReturnAll({
          dim: dim,
          projectLead: projectLead,
          firstInvestmentAmount: firstInvestmentAmount,
          investmentTarget: investmentTarget,
          additionalWaitPeriod: additionalWaitPeriod,
          raisePeriod: raisePeriod
        });
      } else {
        emit Log("Could not make investment.");
      }
    } else {
      emit Log("Could not initialise dim.");
    }
  }

  function _followUpTriggerReturnAll(
    DecentralisedInvestmentManager dim,
    address projectLead,
    uint256 investmentTarget,
    uint256 firstInvestmentAmount,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod
  ) internal {
    if (firstInvestmentAmount >= investmentTarget) {
      vm.prank(projectLead);
      // solhint-disable-next-line not-rely-on-time
      vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);
      vm.expectRevert(bytes("Investment target reached!"));
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
