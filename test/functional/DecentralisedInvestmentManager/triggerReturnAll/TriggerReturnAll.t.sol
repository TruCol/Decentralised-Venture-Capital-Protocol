// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../../../src/DecentralisedInvestmentManager.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface IMultipleInvestmentTest {
  function setUp() external;

  function testRaisePeriodReturnSingleInvestmentTriggerReturnAll() external;

  function testKeepInvestmentsForSuccesfullRaise() external;
}

/**
Tests whether the _dim.triggerReturnAll() function ensures the investments are:
- returned if the investment target is not reached, after the raisePeriod has passed.
- not returned if the investment target is reached, after the raisePeriod has passed.
TODO: test whether the investments are:
- not returned if the investment target is not reached, before the raisePeriod has passed.
- not returned if the investment target is reached, before the raisePeriod has passed.
*/
contract TriggerReturnAllTest is PRBTest, StdCheats, IMultipleInvestmentTest {
  address internal _projectLead;
  address payable private _firstInvestorWallet;
  address payable private _secondInvestorWallet;

  uint256 private _firstInvestmentAmount;

  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Instantiate the attribute for the contract-under-test.
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256[] memory ceilings = new uint256[](3);
    ceilings[0] = 4 ether;
    ceilings[1] = 15 ether;
    ceilings[2] = 30 ether;
    uint8[] memory multiples = new uint8[](3);
    multiples[0] = 10;
    multiples[1] = 5;
    multiples[2] = 2;
    InitialiseDim initDim = new InitialiseDim({
      ceilings: ceilings,
      multiples: multiples,
      raisePeriod: 12 weeks,
      investmentTarget: 0.6 ether,
      projectLead: _projectLead,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();

    _firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_firstInvestorWallet, 3 ether);
    _secondInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("2"))))));
    deal(_secondInvestorWallet, 4 ether);

    _firstInvestmentAmount = 0.5 ether;

    // Set the msg.sender address to that of the _firstInvestorWallet for the next call.
    vm.prank(address(_firstInvestorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _firstInvestmentAmount }();
    assertEq(_dim.getTierInvestmentLength(), 1, "Error, the _tierInvestments.length was not as expected.");
  }

  /**
  @dev The investor has invested 0.5 eth, and the investment target is 0.6 eth after 12 weeks.
  So the investment target is not reached, so all the funds should be returned.
   */
  function testRaisePeriodReturnSingleInvestmentTriggerReturnAll() public virtual override {
    // Simulate 3 weeks passing by
    uint256 startTime = block.timestamp;
    // solhint-disable-next-line not-rely-on-time
    vm.warp(startTime + 3 weeks);

    vm.expectRevert(
      // solhint-disable-next-line func-named-parameters
      abi.encodeWithSignature(
        "FundRaisingPeriodNotPassed(string,uint256,uint256,uint256)",
        "Fund raising period has not yet passed.",
        startTime + 3 weeks,
        startTime - 3 weeks,
        12 weeks
      )
    );
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0.5 ether, "The _dim did not contain 0.5 ether.");

    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 15 weeks);

    vm.prank(_projectLead);
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0 ether, "The _dim did not contain 0 ether after returning all investments.");
  }

  /**
  Tests whether two investments together that reach the investment target result prevents the
  funds from being returned to the investors. (Because if the investment target is reached, the funds
  should be allocated to development, instead of being returned.) */
  function testKeepInvestmentsForSuccesfullRaise() public virtual override {
    uint256 startTime = block.timestamp;
    // Simulate 3 weeks passing by
    // solhint-disable-next-line not-rely-on-time
    vm.warp(startTime + 3 weeks);

    // vm.expectRevert(bytes("The fund raising period has not passed yet."));
    vm.expectRevert(
      // solhint-disable-next-line func-named-parameters
      abi.encodeWithSignature(
        "FundRaisingPeriodNotPassed(string,uint256,uint256,uint256)",
        "Fund raising period has not yet passed.",
        startTime + 3 weeks,
        startTime - 3 weeks,
        12 weeks
      )
    );
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0.5 ether, "The _dim did not contain 0.5 ether.");

    // Set the msg.sender address to that of the _firstInvestorWallet for the next call.
    vm.prank(address(_firstInvestorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    uint256 secondInvestmentAmount = 2.5 ether;
    _dim.receiveInvestment{ value: secondInvestmentAmount }();

    // solhint-disable-next-line not-rely-on-time
    vm.warp(startTime + 15 weeks);

    // vm.expectRevert(bytes("Investment target reached!"));
    vm.expectRevert(
      abi.encodeWithSignature(
        "InvestmentTargetReached(string,uint256,uint256)",
        "Investment target reached!",
        _firstInvestmentAmount + secondInvestmentAmount,
        0.6 ether
      )
    );
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 3 ether, "The _dim did not contain 3 ether.");
  }
}
