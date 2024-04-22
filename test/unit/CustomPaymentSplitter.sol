// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import "forge-std/src/console2.sol"; // Import the console library
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";

interface Interface {
  function setUp() external;

  function testAttributes() external;

  function testOnlyOwnerCanAddPayee() external;

  function testContractCannotAddItselfAsPayee() external;

  function testPayeeAmountOfZeroReverts() external;

  function testCannotAddPayeeThatAlreadyIsPayee() external;

  function testCanReleasePayment() external;

  function testCannotReleasePaymentOfZeroAmount() external;

  function testCannotAddZeroShares() external;

  function testCannotInitialiseConstructorWithoutOwedAmounts() external;

  function testCannotInitialiseConstructorWithoutPayees() external;
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract CustomPaymentSplitterTest is PRBTest, StdCheats, Interface {
  address private _projectLead;
  address[] private _withdrawers;
  uint256[] private _owedDai;
  CustomPaymentSplitter private _paymentSplitter;

  /// @dev A function invoked before each test case is run.
  function setUp() public override {
    _withdrawers.push(_projectLead);
    _owedDai.push(0);
    _paymentSplitter = new CustomPaymentSplitter(_withdrawers, _owedDai);
  }

  /**
   * Test the _tierInvestment object can be created with valid values, and that
   * its public parameters are available, and that its private parameters are
   * not available.
   *
   */
  function testAttributes() public override {
    assertTrue(_paymentSplitter.isPayee(_projectLead));
  }

  function testOnlyOwnerCanAddPayee() public override {
    vm.prank(address(15));
    vm.expectRevert(bytes("The sender of this message is not the owner."));
    _paymentSplitter.publicAddPayee(address(_paymentSplitter), 20);
  }

  function testContractCannotAddItselfAsPayee() public override {
    vm.expectRevert(bytes("This account is equal to the address of this account."));
    _paymentSplitter.publicAddPayee(address(_paymentSplitter), 20);
  }

  function testPayeeAmountOfZeroReverts() public override {
    vm.expectRevert(bytes("The number of incoming dai is not larger than 0."));
    _paymentSplitter.publicAddPayee(address(0), 0);
  }

  function testCannotAddPayeeThatAlreadyIsPayee() public override {
    _paymentSplitter.publicAddPayee(address(0), 5);
    vm.expectRevert(bytes("This account already has some currency."));
    _paymentSplitter.publicAddPayee(address(0), 5);
  }

  function testCanReleasePayment() public override {}

  function testCannotReleasePaymentOfZeroAmount() public override {}

  function testCannotAddZeroShares() public override {}

  function testCannotInitialiseConstructorWithoutOwedAmounts() public override {}

  function testCannotInitialiseConstructorWithoutPayees() public override {}
}
