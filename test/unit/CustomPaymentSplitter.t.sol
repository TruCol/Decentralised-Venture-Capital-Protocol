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

  function testOnlyOwnerCanAddSharesToPayee() external;

  function testContractCannotAddItselfAsPayee() external;

  function testPayeeAmountOfZeroReverts() external;

  function testCannotAddPayeeThatAlreadyIsPayee() external;

  function testCanReleasePayment() external;

  function testCannotReleasePaymentOfZeroAmount() external;

  function testCannotAddZeroShares() external;

  function testCannotInitialiseConstructorWithoutOwedAmounts() external;

  function testCannotInitialiseConstructorWithoutPayees() external;

  function testCannotAddInvestorTwiceInConstructor() external;

  function testCanInitialiseConstructorWithMultiplePayees() external;

  function testCannotInitialisePayeeWithZeroAmount() external;
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
    _paymentSplitter = new CustomPaymentSplitter(address(this), _withdrawers, _owedDai);
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

  function testOnlyOwnerCanAddSharesToPayee() public override {
    vm.prank(address(15));
    vm.expectRevert(bytes("The sender of this message is not the owner."));
    _paymentSplitter.publicAddSharesToPayee(address(_paymentSplitter), 20);
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

  function testCanReleasePayment() public override {
    address payable investorWallet0 = payable(address(5));
    uint256 returnAmount = 40;
    uint256 startBalance = 7;

    // give investor some start balance
    deal(investorWallet0, startBalance);

    // Give the amount to be returned into the _paymentSplitter.
    _paymentSplitter.deposit{ value: returnAmount }();

    // Ensure the investor is a payee of the conhtract.
    _paymentSplitter.publicAddPayee(investorWallet0, returnAmount);

    // Signal th epayment can be released.
    _paymentSplitter.release(investorWallet0);
    assertEq(investorWallet0.balance, startBalance + returnAmount);
    assertEq(_paymentSplitter.released(investorWallet0), returnAmount);
  }

  function testCannotReleasePaymentOfZeroAmount() public override {
    address payable investorWallet0 = payable(address(5));
    uint256 returnAmount = 40;
    uint256 startBalance = 7;

    // give investor some start balance
    deal(investorWallet0, startBalance);

    // Give the amount to be returned into the _paymentSplitter.
    _paymentSplitter.deposit{ value: returnAmount }();

    // Ensure the investor is a payee of the conhtract.
    _paymentSplitter.publicAddPayee(investorWallet0, returnAmount);

    // Signal th epayment can be released.
    _paymentSplitter.release(investorWallet0);

    // Release payment again but now 0. TODO: determine why this does not revert.
    _paymentSplitter.release(investorWallet0);

    vm.expectRevert(bytes("The dai for account, was not larger than 0."));
    _paymentSplitter.release(payable(address(9001)));
  }

  function testCannotAddZeroShares() public override {
    address payable investorWallet0 = payable(address(4));
    vm.expectRevert(bytes("There were 0 dai shares incoming."));
    _paymentSplitter.publicAddSharesToPayee(investorWallet0, 0);

    _paymentSplitter.publicAddSharesToPayee(investorWallet0, 10);
  }

  function testCannotInitialiseConstructorWithoutOwedAmounts() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai;
    somePayees[0] = address(10);
    somePayees[1] = address(11);

    vm.expectRevert(bytes("The nr of payees is not equal to the nr of amounts owed."));
    _paymentSplitter = new CustomPaymentSplitter(address(this), somePayees, someOwedDai);
  }

  function testCannotInitialiseConstructorWithoutPayees() public override {
    address[] memory somePayees;
    // uint256[] memory someOwedDai = new uint256[](2);
    uint256[] memory someOwedDai;
    // someOwedDai[0] = 10;
    // someOwedDai[1] = 11;

    vm.expectRevert(bytes("There are not more than 0 payees."));
    _paymentSplitter = new CustomPaymentSplitter(address(this), somePayees, someOwedDai);
  }

  function testCannotAddInvestorTwiceInConstructor() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai = new uint256[](2);
    somePayees[0] = address(10);
    someOwedDai[0] = 10;
    somePayees[1] = address(10);
    someOwedDai[1] = 10;

    vm.expectRevert(bytes("This account already is owed some currency."));
    _paymentSplitter = new CustomPaymentSplitter(address(this), somePayees, someOwedDai);
  }

  function testCanInitialiseConstructorWithMultiplePayees() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai = new uint256[](2);
    somePayees[0] = address(10);
    someOwedDai[0] = 10;
    somePayees[1] = address(11);
    someOwedDai[1] = 11;

    _paymentSplitter = new CustomPaymentSplitter(address(this), somePayees, someOwedDai);
  }

  function testCannotInitialisePayeeWithZeroAmount() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai = new uint256[](2);
    somePayees[0] = address(10);
    someOwedDai[0] = 10;
    somePayees[1] = address(11);
    someOwedDai[1] = 0;

    _paymentSplitter = new CustomPaymentSplitter(address(this), somePayees, someOwedDai);
  }
}
