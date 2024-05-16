// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface IMultipleInvestmentTest {
  function setUp() external;

  function testProjectLeadCantWithdrawBeforeTargetIsReached() external;

  function testRaisePeriodReturnSingleInvestment() external;

  function testKeepInvestmentsForSuccesfullRaise() external;
}

contract MultipleInvestmentTest is PRBTest, StdCheats, IMultipleInvestmentTest {
  address internal _projectLead;
  address payable private _investorWallet0;
  address payable private _investorWalletA;

  uint256 private _investmentAmount0;

  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
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

    _investorWallet0 = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet0, 3 ether);
    _investorWalletA = payable(address(uint160(uint256(keccak256(bytes("2"))))));
    deal(_investorWalletA, 4 ether);
    _investmentAmount0 = 0.5 ether;

    // Set the msg.sender address to that of the _investorWallet0 for the next call.
    vm.prank(address(_investorWallet0));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _investmentAmount0 }();
    assertEq(_dim.getTierInvestmentLength(), 1, "Error, the _tierInvestments.length was not as expected.");
  }

  function testProjectLeadCantWithdrawBeforeTargetIsReached() public virtual override {
    // Simulate 3 weeks passing by
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 3 weeks);

    vm.prank(_projectLead);
    vm.expectRevert(bytes("Investment target is not yet reached."));
    _dim.withdraw(_investmentAmount0);
    _dim.receiveInvestment{ value: 5 ether }();

    vm.prank(_projectLead);
    _dim.withdraw(5.5 ether);
    assertEq(address(_dim).balance, 0 ether, "The _dim did not contain 0 ether.");
    assertEq(_projectLead.balance, 5.5 ether, "The _dim did not contain 0 ether.");
  }

  function testRaisePeriodReturnSingleInvestment() public virtual override {
    // Simulate 3 weeks passing by
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 3 weeks);

    vm.expectRevert(bytes("The fund raising period has not passed yet."));
    vm.prank(_projectLead);
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0.5 ether, "The _dim did not contain 0.5 ether.");

    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 15 weeks);

    vm.expectRevert(bytes("Someone other than projectLead tried to return all investments."));
    _dim.triggerReturnAll();

    vm.prank(_projectLead);
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0 ether, "The _dim did not contain 0 ether.");
  }

  function testKeepInvestmentsForSuccesfullRaise() public virtual override {
    // Simulate 3 weeks passing by
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 3 weeks);

    vm.expectRevert(bytes("The fund raising period has not passed yet."));
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0.5 ether, "The _dim did not contain 0.5 ether.");

    // Set the msg.sender address to that of the _investorWallet0 for the next call.
    vm.prank(address(_investorWallet0));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: 2.5 ether }();

    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 15 weeks);

    vm.expectRevert(bytes("Investment target reached!"));
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 3 ether, "The _dim did not contain 0 ether.");
  }
}
