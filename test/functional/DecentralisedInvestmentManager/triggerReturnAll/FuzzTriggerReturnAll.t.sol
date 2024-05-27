// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { Helper } from "../../../../src/Helper.sol";
import { TestHelper } from "../../../TestHelper.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";
import { console2 } from "forge-std/src/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// uint32 private constant _MAX_NR_OF_TIERS= 100;
uint32 constant _MAX_NR_OF_TIERS = 100;

interface IFuzzTriggerReturnAll {
  function setUp() external;

  function testFuzzAfterRaisePeriodReturnSingleInvestment(
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
  TestHelper private _testHelper;
  Helper private _helper;

  function setUp() public virtual override {
    _testHelper = new TestHelper();
    _helper = new Helper();
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
  ) public virtual returns (uint8[] memory multiples, uint256[] memory sameNrOfCeilings) {
    // Change the fixed array length from _MAX_NR_OF_TIERS to array of variable length (dynamic array).
    uint256[] memory duplicateCeilings = new uint256[](randomCeilings.length);
    for (uint256 i = 0; i < randomCeilings.length; ++i) {
      // +1 to ensure a ceiling of 0 is shifted to a minimum of 1.
      duplicateCeilings[i] = _testHelper.maximum(1, randomCeilings[i]);
    }
    // Removes duplicate values and sorts the ceilings from small to large.
    uint256[] memory ceilings = _testHelper.getSortedUniqueArray(duplicateCeilings);

    // From the selected unique, ascending Tier investment ceilings, select subset of random size.
    uint256 nrOfInvestmentTiers = (randNrOfInvestmentTiers % ceilings.length) + 1;
    // Recreate the multiples and ceilings of the selected random size (nr. of Tiers).
    uint8[] memory multiples = new uint8[](nrOfInvestmentTiers);
    uint256[] memory sameNrOfCeilings = new uint256[](nrOfInvestmentTiers);
    for (uint256 i = 0; i < nrOfInvestmentTiers; ++i) {
      multiples[i] = uint8(_testHelper.maximum(2, randomMultiples[i])); // Filter out the 0 and 1 values.
      sameNrOfCeilings[i] = ceilings[i];
    }

    return (multiples, sameNrOfCeilings);
  }

  /**
   * @notice Checks if a RandomDim object can be initialized with the provided parameters.
   * @dev This function attempts to create a temporary `InitialiseDim` object with the given parameters.
   * If successful, it returns `true`. If there are any errors during initialization, it returns `false`.
   *
   * @param projectLeadFracNumerator The numerator representing the project lead's fractional share.
   * @param projectLeadFracDenominator The denominator for the project lead's fractional share.
   * @param investmentTarget The target amount of investment for the project.
   * @param ceilings An array of integers representing the maximum allowed values for something (e.g., contribution limits).
   * @param multiples An array of integers representing multiples for something (e.g., investment tiers).
   * @param raisePeriod The duration (in seconds) for the investment raise period.
   *
   * @return canInitialiseDim A boolean indicating whether the `InitialiseDim` object can be initialized successfully.
   */
  function _canInitialiseRandomDim(
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint256[] memory ceilings,
    uint8[] memory multiples,
    uint32 raisePeriod
  ) internal virtual returns (bool canInitialiseDim) {
    try
      new InitialiseDim({
        ceilings: ceilings,
        multiples: multiples,
        investmentTarget: investmentTarget,
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        projectLead: _projectLead,
        raisePeriod: raisePeriod
      })
    {
      emit Log("Initialised");
      return true;
    } catch Error(string memory reason) {
      emit Log(reason);
      return false;
    } catch (bytes memory reason) {
      // catch failing assert()

      emit LogBytes(reason);
      return false;
    }
  }

  /**
   * @notice Initializes a DecentralisedInvestmentManager (DIM) object with the provided parameters.
   * @dev This function creates a new `DecentralisedInvestmentManager` object with the given parameters.
   * It first prepares internal arrays for ceilings and multiples, then creates a temporary `InitialiseDim` object
   * to perform the initialization. Finally, it retrieves the created `DecentralisedInvestmentManager` object and returns it.
   *
   * @param projectLeadFracNumerator The numerator representing the project lead's fractional share.
   * @param projectLeadFracDenominator The denominator for the project lead's fractional share.
   * @param investmentTarget The target amount of investment for the project.

   * @param raisePeriod The duration (in seconds) for the investment raise period.
   *
   * @return dim A `DecentralisedInvestmentManager` object initialized with the provided parameters.
   */
  function _initialiseRandomDim(
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint32 raisePeriod,
    uint256[] memory ceilings,
    uint8[] memory multiples
  ) internal virtual returns (DecentralisedInvestmentManager dim) {
    // Instantiate the attribute for the contract-under-test.
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    InitialiseDim initDim = new InitialiseDim({
      ceilings: ceilings,
      multiples: multiples,
      investmentTarget: investmentTarget,
      projectLeadFracNumerator: projectLeadFracNumerator,
      projectLeadFracDenominator: projectLeadFracDenominator,
      projectLead: _projectLead,
      raisePeriod: raisePeriod
    });
    dim = initDim.getDim();
    return dim;
  }

  /**
   * @notice Attempts to safely invest a given amount from an investor's wallet into a DecentralisedInvestmentManager (DIM) object.
   * @dev This function first transfers the investment amount (`someInvestmentAmount`) from the provided `someInvestorWallet` using the `deal` function (likely a custom function for managing funds).
   * Then, it simulates the investor as the message sender (`vm.prank`) and calls the `receiveInvestment` function of the `dim` object with the transferred amount.
   * If successful, it logs investment details and returns `true`. If there are any errors during the transfer or investment process, it logs the error reason and returns `false`.
   *
   * @param dim The DecentralisedInvestmentManager object to invest in.
   * @param someInvestmentAmount The amount of money to invest (in Wei).
   * @param someInvestorWallet The address of the investor's wallet.
   *
   * @return canMakeInvestment A boolean indicating whether the investment was successful.
   */
  function _safelyInvest(
    DecentralisedInvestmentManager dim,
    uint256 someInvestmentAmount,
    address payable someInvestorWallet
  ) internal virtual returns (bool canMakeInvestment) {
    deal(someInvestorWallet, someInvestmentAmount);

    // Set the msg.sender address to that of the _firstInvestorWallet for the next call.
    vm.prank(address(someInvestorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    try dim.receiveInvestment{ value: someInvestmentAmount }() {
      return true;
    } catch Error(string memory reason) {
      emit Log(reason);
      return false;
    } catch (bytes memory reason) {
      emit LogBytes(reason);
      return false;
    }
  }

  /**
  @dev The investor has invested 0.5 eth, and the investment target is 0.6 eth after 12 weeks.
  So the investment target is not reached, so all the funds should be returned.
   */
  function testFuzzAfterRaisePeriodReturnSingleInvestment(
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
    uint256 investmentTarget = (investmentTarget % sameNrOfCeilings[sameNrOfCeilings.length - 1]) + 1;
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    if (
      _canInitialiseRandomDim({
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        raisePeriod: raisePeriod,
        investmentTarget: investmentTarget,
        ceilings: sameNrOfCeilings,
        multiples: multiples
      })
    ) {
      // Initialise the contract that is being fuzz tested.
      DecentralisedInvestmentManager dim = _initialiseRandomDim({
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        raisePeriod: raisePeriod,
        investmentTarget: investmentTarget,
        ceilings: sameNrOfCeilings,
        multiples: multiples
      });

      // Generate a non-random investor wallet address and make an investment.
      address payable firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
      if (
        _safelyInvest({
          dim: dim,
          someInvestmentAmount: firstInvestmentAmount,
          someInvestorWallet: firstInvestorWallet
        })
      ) {
        // Perform test logic.
        if (firstInvestmentAmount >= investmentTarget) {
          vm.prank(_projectLead);
          // solhint-disable-next-line not-rely-on-time
          vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);
          vm.expectRevert(bytes("Investment target reached!"));
          dim.triggerReturnAll();
        } else {
          vm.prank(_projectLead);
          // solhint-disable-next-line not-rely-on-time
          vm.warp(block.timestamp + raisePeriod + additionalWaitPeriod);
          dim.triggerReturnAll();
          assertEq(address(dim).balance, 0 ether, "The dim did not contain 0 ether after returning all investments.");
        }
      } else {
        emit Log("Could not make investment.");
      }
    } else {
      emit Log("Could not initialise dim.");
    }
  }
}
