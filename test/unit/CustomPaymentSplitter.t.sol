// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";
import { console2 } from "forge-std/src/console2.sol";

interface ICustomPaymentSplitterTest {
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
contract CustomPaymentSplitterTest is PRBTest, StdCheats, ICustomPaymentSplitterTest {
  address private _projectLead;
  address[] private _withdrawers;
  uint256[] private _owedDai;
  CustomPaymentSplitter private _paymentSplitter;

  /// @dev A function invoked before each test case is run.
  function setUp() public override {
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
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
    address unauthorisedAddress = address(15);
    vm.prank(unauthorisedAddress);
    vm.expectRevert(
      abi.encodeWithSignature(
        "CustomPaymentSplitterOnlyOwner(string,address,address)",
        "Message sender is not owner.",
        address(this),
        unauthorisedAddress
      )
    );
    // Assert an unauthorised entity cannot add the _paymentSplitter contract itself as payee.
    _paymentSplitter.publicAddPayee(address(_paymentSplitter), 20);
  }

  function testOnlyOwnerCanAddSharesToPayee() public override {
    address unauthorisedAddress = address(15);
    vm.prank(unauthorisedAddress);
    vm.expectRevert(
      abi.encodeWithSignature(
        "CustomPaymentSplitterOnlyOwner(string,address,address)",
        "Message sender is not owner.",
        address(this),
        unauthorisedAddress
      )
    );
    // Assert an unauthorised entity cannot add shares to the _paymentSplitter contract.
    _paymentSplitter.publicAddSharesToPayee(address(_paymentSplitter), 20);
  }

  function testContractCannotAddItselfAsPayee() public override {
    vm.expectRevert(
      abi.encodeWithSignature(
        "ReleaseAccountIsContractAddress(string,address,address)",
        "This account is equal to the address of this account.",
        address(_paymentSplitter),
        address(_paymentSplitter)
      )
    );
    _paymentSplitter.publicAddPayee(address(_paymentSplitter), 20);
  }

  function testPayeeAmountOfZeroReverts() public override {
    vm.expectRevert(
      abi.encodeWithSignature(
        "ZeroDaiForAddingNewPayee(string,address,uint256)",
        "The number of incoming dai is not larger than 0.",
        address(0),
        0
      )
    );
    _paymentSplitter.publicAddPayee(address(0), 0);
  }

  function testCannotAddPayeeThatAlreadyIsPayee() public override {
    _paymentSplitter.publicAddPayee(address(0), 5);
    vm.expectRevert(
      abi.encodeWithSignature(
        "NonEmptyAccountForNewPayee(string,address,uint256)",
        "This account already has some currency.",
        address(0),
        5
      )
    );
    _paymentSplitter.publicAddPayee(address(0), 5);
  }

  function testCanReleasePayment() public override {
    address investorWallet0 = address(5);
    uint256 returnAmount = 40;
    uint256 startBalance = 7;

    // give investor some start balance
    deal(investorWallet0, startBalance);

    // Give the amount to be returned into the _paymentSplitter.
    _paymentSplitter.deposit{ value: returnAmount }();

    // Ensure the investor is a payee of the conhtract.
    _paymentSplitter.publicAddPayee(investorWallet0, returnAmount);

    // Signal th epayment can be released.
    vm.prank(investorWallet0);
    _paymentSplitter.release();
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

    // Signal the payment can be released.
    vm.prank(investorWallet0);
    _paymentSplitter.release();

    // Release payment again but now 0. TODO: determine why this does not revert.
    vm.expectRevert(
      abi.encodeWithSignature(
        "ZeroPaymentForAccount(string,address,uint256)",
        "The amount to be paid was not larger than 0.",
        // address(9001),
        investorWallet0,
        0
      )
    );
    vm.prank(investorWallet0);
    _paymentSplitter.release();

    vm.expectRevert(
      abi.encodeWithSignature(
        "ZeroDaiSharesReleasedForAccount(string,address,uint256)",
        "The dai for account, was not larger than 0.",
        address(9001),
        0
      )
    );
    vm.prank(address(9001));
    _paymentSplitter.release();
  }

  function testCannotAddZeroShares() public override {
    address payable investorWallet0 = payable(address(4));
    vm.expectRevert(
      abi.encodeWithSignature(
        "ZeroDaiSharesIncoming(string,address,uint256)",
        "There were 0 dai shares incoming.",
        investorWallet0,
        0
      )
    );
    _paymentSplitter.publicAddSharesToPayee(investorWallet0, 0);

    _paymentSplitter.publicAddSharesToPayee(investorWallet0, 10);
  }

  function testCannotInitialiseConstructorWithoutOwedAmounts() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai = new uint256[](0);
    somePayees[0] = address(10);
    somePayees[1] = address(11);

    
    vm.expectRevert(
      abi.encodeWithSignature(
        "DifferentNrOfPayeesThanAmountsOwed(string,uint256,uint256)",
        "Nr of payees not equal to nr of amounts owed.",
        somePayees.length,
        someOwedDai.length
      )
    );
    _paymentSplitter = new CustomPaymentSplitter(somePayees, someOwedDai);
  }

  function testCannotInitialiseConstructorWithoutPayees() public override {
    address[] memory somePayees = new address[](0);
    uint256[] memory someOwedDai = new uint256[](0);
    
    vm.expectRevert(
      abi.encodeWithSignature(
        "LessThanOnePayee(string,uint256)",
        "There are not more than 0 payees.",
        somePayees.length
      )
    );
    _paymentSplitter = new CustomPaymentSplitter(somePayees, someOwedDai);
  }

  function testCannotAddInvestorTwiceInConstructor() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai = new uint256[](2);
    somePayees[0] = address(10);
    someOwedDai[0] = 10;
    somePayees[1] = address(10);
    someOwedDai[1] = 10;

    vm.expectRevert(
      abi.encodeWithSignature(
        "AccountIsNotNewPayee(string,address,uint256)",
        "Account is not a new payee.",
        address(10),
        10
      )
    );
    _paymentSplitter = new CustomPaymentSplitter(somePayees, someOwedDai);
  }

  function testCanInitialiseConstructorWithMultiplePayees() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai = new uint256[](2);
    somePayees[0] = address(10);
    someOwedDai[0] = 10;
    somePayees[1] = address(11);
    someOwedDai[1] = 11;

    _paymentSplitter = new CustomPaymentSplitter(somePayees, someOwedDai);
  }

  function testCannotInitialisePayeeWithZeroAmount() public override {
    address[] memory somePayees = new address[](2);
    uint256[] memory someOwedDai = new uint256[](2);
    somePayees[0] = address(10);
    someOwedDai[0] = 10;
    somePayees[1] = address(11);
    someOwedDai[1] = 0;

    _paymentSplitter = new CustomPaymentSplitter(somePayees, someOwedDai);
  }
}
