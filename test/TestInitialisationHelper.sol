// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { InitialiseDim } from "test/InitialiseDim.sol";
import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { TestMathHelper } from "test/TestMathHelper.sol";
import "test/TestConstants.sol";

interface ITestInitialisationHelper {
  function canInitialiseRandomDim(
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint256[] memory ceilings,
    uint8[] memory multiples,
    uint32 raisePeriod
  ) external returns (bool canInitialiseDim);

  function safelyInvest(
    DecentralisedInvestmentManager dim,
    uint256 someInvestmentAmount,
    address payable someInvestorWallet
  ) external returns (bool canMakeInvestment);

  function getRandomMultiplesAndCeilings(
    uint256[_MAX_NR_OF_TIERS] memory randomCeilings,
    uint8[_MAX_NR_OF_TIERS] memory randomMultiples,
    uint8 randNrOfInvestmentTiers
  ) external returns (uint8[] memory multiples, uint256[] memory sameNrOfCeilings);
}

contract TestInitialisationHelper is ITestInitialisationHelper, PRBTest, StdCheats {
  /**
   * @notice Checks if a RandomDim object can be initialized with the provided parameters.
   * @dev This function attempts to create a temporary `InitialiseDim` object with the given parameters.
   * If successful, it returns `true`. If there are any errors during initialization, it returns `false`.
   *
   * @param projectLeadFracNumerator The numerator representing the project lead's fractional share.
   * @param projectLeadFracDenominator The denominator for the project lead's fractional share.
   * @param investmentTarget The target amount of investment for the project.
   * @param ceilings An array of integers representing the maximum allowed values for something (e.g., contribution
   limits).
   * @param multiples An array of integers representing multiples for something (e.g., investment tiers).
   * @param raisePeriod The duration (in seconds) for the investment raise period.
   *
   * @return canInitialiseDim A boolean indicating whether the `InitialiseDim` object can be initialized successfully.
   */
  function canInitialiseRandomDim(
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint256[] memory ceilings,
    uint8[] memory multiples,
    uint32 raisePeriod
  ) public override returns (bool canInitialiseDim) {
    try
      new InitialiseDim({
        ceilings: ceilings,
        multiples: multiples,
        investmentTarget: investmentTarget,
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        projectLead: projectLead,
        raisePeriod: raisePeriod
      })
    {
      // emit Log("Initialised");
      return true;
    } catch Error(string memory reason) {
      // emit Log(reason);
      return false;
    } catch (bytes memory reason) {
      // catch failing assert()

      //emit LogBytes(reason);
      return false;
    }
  }

  /**
   * @notice Attempts to safely invest a given amount from an investor's wallet into a DecentralisedInvestmentManager
   (DIM) object.
   * @dev This function first transfers the investment amount (`someInvestmentAmount`) from the provided
   `someInvestorWallet` using the `deal` function (likely a custom function for managing funds).
   * Then, it simulates the investor as the message sender (`vm.prank`) and calls the `receiveInvestment` function of
   the `dim` object with the transferred amount.
   * If successful, it logs investment details and returns `true`. If there are any errors during the transfer or
   investment process, it logs the error reason and returns `false`.
   *
   * @param dim The DecentralisedInvestmentManager object to invest in.
   * @param someInvestmentAmount The amount of money to invest (in Wei).
   * @param someInvestorWallet The address of the investor's wallet.
   *
   * @return canMakeInvestment A boolean indicating whether the investment was successful.
   */
  function safelyInvest(
    DecentralisedInvestmentManager dim,
    uint256 someInvestmentAmount,
    address payable someInvestorWallet
  ) public override returns (bool canMakeInvestment) {
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
    TestMathHelper _testMathHelper;
    _testMathHelper = new TestMathHelper();
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
}
