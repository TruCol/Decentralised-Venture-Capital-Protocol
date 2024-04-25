// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { Tier } from "../../src/Tier.sol";
import "forge-std/src/console2.sol"; // Import the console library
import "forge-std/src/Vm.sol"; // For manipulating time
// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

interface Interface {
  function setUp() external;

  function testProjectLeadCantWithdrawBeforeTargetIsReached() external;

  function testRaisePeriodReturnSingleInvestment() external;

  function testKeepInvestmentsForSuccesfullRaise() external;
}

contract MultipleInvestmentTest is PRBTest, StdCheats, Interface {
  address internal _projectLeadAddress;
  address payable private _investorWallet0;
  address payable private _investorWallet1;
  Tier[] private _tiers;
  uint256 private _investmentAmount0;
  uint256 private _investmentAmount1;

  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;

  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Instantiate the attribute for the contract-under-test.
    _projectLeadAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    _projectLeadFracNumerator = 4;
    _projectLeadFracDenominator = 10;

    // Specify the investment tiers in ether.
    uint256 firstTierCeiling = 4 ether;
    uint256 secondTierCeiling = 15 ether;
    uint256 thirdTierCeiling = 30 ether;
    vm.prank(_projectLeadAddress);
    Tier tier0 = new Tier(0, firstTierCeiling, 10);
    _tiers.push(tier0);
    vm.prank(_projectLeadAddress);
    Tier tier1 = new Tier(firstTierCeiling, secondTierCeiling, 5);
    _tiers.push(tier1);
    vm.prank(_projectLeadAddress);
    Tier tier2 = new Tier(secondTierCeiling, thirdTierCeiling, 2);
    _tiers.push(tier2);

    // assertEq(address(_projectLeadAddress).balance, 43);
    _dim = new DecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress,
      12 weeks,
      0.6 ether
    );

    _investorWallet0 = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet0, 3 ether);
    _investorWallet1 = payable(address(uint160(uint256(keccak256(bytes("2"))))));
    deal(_investorWallet1, 4 ether);

    _investmentAmount0 = 0.5 ether;

    // Set the msg.sender address to that of the _investorWallet0 for the next call.
    vm.prank(address(_investorWallet0));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _investmentAmount0 }();
    assertEq(_dim.getTierInvestmentLength(), 1, "Error, the _tierInvestments.length was not as expected.");
  }

  function testProjectLeadCantWithdrawBeforeTargetIsReached() public virtual override {
    // Simulate 3 weeks passing by
    vm.warp(block.timestamp + 3 weeks);

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Investment target is not yet reached."));
    _dim.withdraw(_investmentAmount0);
    _dim.receiveInvestment{ value: 5 ether }();

    vm.prank(_projectLeadAddress);
    _dim.withdraw(5.5 ether);
    assertEq(address(_dim).balance, 0 ether, "The _dim did not contain 0 ether.");
    assertEq(_projectLeadAddress.balance, 5.5 ether, "The _dim did not contain 0 ether.");
  }

  function testRaisePeriodReturnSingleInvestment() public virtual override {
    // Simulate 3 weeks passing by
    vm.warp(block.timestamp + 3 weeks);

    vm.expectRevert(bytes("The fund raising period has not passed yet."));
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0.5 ether, "The _dim did not contain 0.5 ether.");

    vm.warp(block.timestamp + 15 weeks);

    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0 ether, "The _dim did not contain 0 ether.");
  }

  function testKeepInvestmentsForSuccesfullRaise() public virtual override {
    // Simulate 3 weeks passing by
    vm.warp(block.timestamp + 3 weeks);

    vm.expectRevert(bytes("The fund raising period has not passed yet."));
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 0.5 ether, "The _dim did not contain 0.5 ether.");

    // Set the msg.sender address to that of the _investorWallet0 for the next call.
    vm.prank(address(_investorWallet0));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: 2.5 ether }();

    vm.warp(block.timestamp + 15 weeks);

    vm.expectRevert(bytes("Investment target reached!"));
    _dim.triggerReturnAll();
    assertEq(address(_dim).balance, 3 ether, "The _dim did not contain 0 ether.");
  }
}
