// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { Tier } from "../../src/Tier.sol";
import "forge-std/src/Vm.sol" as vm;
// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface Interface {
  function setUp() external;

  function testRaisePeriodReturnSingleInvestment() external;

  function testKeepInvestmentsForSuccesfullRaise() external;
}

contract MultipleInvestmentTest is PRBTest, StdCheats, Interface {
  address internal _projectLeadAddress;
  address payable private _investorWallet0;
  address payable private _investorWalletA;
  Tier[] private _tiers;
  uint256 private _investmentAmount0;
  uint256 private _investmentAmount1;

  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Instantiate the attribute for the contract-under-test.
    _projectLeadAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
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
      projectLeadAddress: _projectLeadAddress,
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

  /**
  @dev The investor has invested 0.5 eth, at a multiple of 10. Then the
  multiple of that tier gets increased to 20, but that was after the investment
  was made, so the investor still gets a multiple of 10, yielding a return of 5
  ether.
   */
  function testRaisePeriodReturnSingleInvestment() public virtual override {
    // Simulate 3 weeks passing by
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 3 weeks);

    vm.expectRevert(bytes("The fund raising period has not passed yet."));
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0.5 ether, "The _dim did not contain 0.5 ether.");

    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 15 weeks);

    vm.prank(_projectLeadAddress);
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
