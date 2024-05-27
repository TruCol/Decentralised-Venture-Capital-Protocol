// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { TestHelper } from "../../../TestHelper.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";
import { console2 } from "forge-std/src/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IFuzzTriggerReturnAll {
  function setUp() external;

  function testFuzzAfterRaisePeriodReturnSingleInvestment(
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 firstInvestmentAmount,
    uint256 investmentTarget,
    uint256 firstCeiling,
    uint256 secondCeiling,
    uint256 thirdCeiling,
    uint32 raisePeriod,
    uint32 additionalWaitPeriod,
    uint8 firstMultiple,
    uint8 secondMultiple,
    uint8 thirdMultiple,
    uint256[100] memory someList,
    uint256[55] memory anotherList
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

  function setUp() public virtual override {
    _testHelper = new TestHelper();
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
      if (
        keccak256(abi.encodePacked(reason)) ==
        keccak256(abi.encodePacked("The maximum amount should be larger than the minimum."))
      ) {}

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
   * @param firstCeiling The first maximum allowed value (e.g., contribution limit).
   * @param secondCeiling The second maximum allowed value (e.g., contribution limit).
   * @param thirdCeiling The third maximum allowed value (e.g., contribution limit).
   * @param raisePeriod The duration (in seconds) for the investment raise period.
   * @param firstMultiple The first multiple for something (e.g., investment tier).
   * @param secondMultiple The second multiple for something (e.g., investment tier).
   * @param thirdMultiple The third multiple for something (e.g., investment tier).
   *
   * @return dim A `DecentralisedInvestmentManager` object initialized with the provided parameters.
   */
  function _initialiseRandomDim(
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    uint256 investmentTarget,
    uint256 firstCeiling,
    uint256 secondCeiling,
    uint256 thirdCeiling,
    uint32 raisePeriod,
    uint8 firstMultiple,
    uint8 secondMultiple,
    uint8 thirdMultiple
  ) internal virtual returns (DecentralisedInvestmentManager dim) {
    // Instantiate the attribute for the contract-under-test.
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256[] memory ceilings = new uint256[](3);
    ceilings[0] = firstCeiling;
    ceilings[1] = secondCeiling;
    ceilings[2] = thirdCeiling;
    uint8[] memory multiples = new uint8[](3);
    multiples[0] = firstMultiple;
    multiples[1] = secondMultiple;
    multiples[2] = thirdMultiple;

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
      emit Log("Made investment.");
      emit Log("In investment getCumReceivedInvestments=");
      emit Log(Strings.toString(dim.getCumReceivedInvestments()));
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
    uint256 firstCeiling,
    uint256 secondCeiling,
    uint256 thirdCeiling,
    uint32 additionalWaitPeriod,
    uint32 raisePeriod,
    uint8 firstMultiple,
    uint8 secondMultiple,
    uint8 thirdMultiple,
    uint256[100] memory someList,
    uint256[55] memory anotherList

  ) public virtual override {
    // Assume requirements on contract initialisation by project lead are valid.
    // vm.assume(projectLeadFracDenominator > 0);
    // vm.assume(firstCeiling > 0);
    // vm.assume(additionalWaitPeriod > 0);
    // vm.assume(raisePeriod > 0);
    // vm.assume(investmentTarget > 0);
    // vm.assume(firstCeiling < secondCeiling);
    // vm.assume(secondCeiling < thirdCeiling);
    // vm.assume(investmentTarget <= thirdCeiling);
    // vm.assume(projectLeadFracNumerator <= projectLeadFracDenominator);
    // vm.assume(firstMultiple > 1);
    // vm.assume(secondMultiple > 1);
    // vm.assume(thirdMultiple > 1);

    // Assume an investor tries to invest at least 1 wei.
    // vm.assume(firstInvestmentAmount > 0);
    console2.log("someList=",someList.length);
    // Store multiples in an array to assert they do not lead to an overflow when computing the investor return.
    uint8[] memory multiples = new uint8[](3);
    multiples[0] = firstMultiple;
    multiples[1] = secondMultiple;
    multiples[2] = thirdMultiple;
    // vm.assume(!_testHelper.sumOfNrsThrowsOverFlow({ numbers: multiples }));
    // vm.assume(
    // !_testHelper.yieldsOverflowMultiply({
    // a: firstMultiple + secondMultiple + thirdMultiple,
    // b: firstInvestmentAmount
    // })
    // );

    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256[] memory ceilings = new uint256[](3);
    ceilings[0] = firstCeiling;
    ceilings[1] = secondCeiling;
    ceilings[2] = thirdCeiling;

    if (
      _canInitialiseRandomDim({
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        raisePeriod: raisePeriod,
        investmentTarget: investmentTarget,
        ceilings: ceilings,
        multiples: multiples
      })
    ) {
      // Initialise the contract that is being fuzz tested.
      DecentralisedInvestmentManager dim = _initialiseRandomDim({
        projectLeadFracNumerator: projectLeadFracNumerator,
        projectLeadFracDenominator: projectLeadFracDenominator,
        raisePeriod: raisePeriod,
        investmentTarget: investmentTarget,
        firstCeiling: firstCeiling,
        secondCeiling: secondCeiling,
        thirdCeiling: thirdCeiling,
        firstMultiple: firstMultiple,
        secondMultiple: secondMultiple,
        thirdMultiple: thirdMultiple
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
