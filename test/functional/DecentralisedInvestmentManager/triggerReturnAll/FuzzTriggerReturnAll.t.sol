// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface IFuzzTriggerReturnAll {
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
    uint8 thirdMultiple
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
  address payable private _firstInvestorWallet;
  address payable private _secondInvestorWallet;

  uint256 private _firstInvestmentAmount;

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

  function _performInvestmentInRandomDim(
    DecentralisedInvestmentManager dim,
    uint256 someInvestmentAmount,
    address payable someInvestorWallet
  ) internal virtual {
    deal(someInvestorWallet, someInvestmentAmount);
    // Set the msg.sender address to that of the _firstInvestorWallet for the next call.
    vm.prank(address(someInvestorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    dim.receiveInvestment{ value: someInvestmentAmount }();
    // assertEq(dim.getTierInvestmentLength(), 1, "Error, the _tierInvestments.length was not as expected.");
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
    uint8 thirdMultiple
  ) public virtual override {
    if (
      projectLeadFracDenominator > 0 &&
      firstInvestmentAmount > 0 &&
      firstCeiling > 0 &&
      additionalWaitPeriod > 0 &&
      raisePeriod > 0 &&
      investmentTarget > 0 &&
      firstCeiling < secondCeiling &&
      secondCeiling < thirdCeiling &&
      projectLeadFracNumerator <= projectLeadFracDenominator &&
      firstMultiple > 1 &&
      secondMultiple > 1 &&
      thirdMultiple > 1
    ) {
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
      address payable firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
      _performInvestmentInRandomDim({
        dim: dim,
        someInvestmentAmount: firstInvestmentAmount,
        someInvestorWallet: firstInvestorWallet
      });

      if (firstInvestmentAmount > investmentTarget) {
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
    } else {}
  }
}
