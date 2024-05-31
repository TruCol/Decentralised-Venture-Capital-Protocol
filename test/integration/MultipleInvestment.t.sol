// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface IMultipleInvestmentTest {
  function setUp() external;

  function testMultipleInvestments() external;

  function followUpFirstSaasPayment() external;

  function followUpSecondInvestment() external;

  function followUpSecondSaasPayment() external;
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract MultipleInvestmentTest is PRBTest, StdCheats, IMultipleInvestmentTest {
  address internal _projectLead;

  address payable private _firstInvestorWallet;
  address payable private _secondInvestorWallet;
  uint256 private _firstInvestmentAmount;
  uint256 private _secondInvestmentAmount;
  address private _userWallet;

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
      investmentTarget: 3 ether,
      projectLead: _projectLead,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();

    _firstInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_firstInvestorWallet, 3 ether);
    _secondInvestorWallet = payable(address(uint160(uint256(keccak256(bytes("2"))))));
    deal(_secondInvestorWallet, 4 ether);

    _userWallet = address(uint160(uint256(keccak256(bytes("3")))));
    deal(_userWallet, 100 ether);

    // Print the addresses to console.
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testMultipleInvestments() public virtual override {
    uint256 startBalance = _firstInvestorWallet.balance;
    _firstInvestmentAmount = 0.5 ether;

    // Set the msg.sender address to that of the _firstInvestorWallet for the next call.
    vm.prank(address(_firstInvestorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _firstInvestmentAmount }();

    // Assert that user balance decreased by the investment amount
    uint256 endBalance = _firstInvestorWallet.balance;
    assertEq(
      startBalance - endBalance,
      _firstInvestmentAmount,
      "_firstInvestmentAmount not equal to difference in investorWalletBalance"
    );

    // TODO: assert the tierInvestment(s) are made as expected.
    assertEq(
      _dim.getCumReceivedInvestments(),
      _firstInvestmentAmount,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // _firstInvestmentAmount*10, // Tier 0 has a multiple of 10.
      10 * 0.5 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after investment."
    );

    assertEq(_dim.getTierInvestmentLength(), 1, "Error, the _tierInvestments.length was not as expected.");
    // TODO: write tests to assert the remaining investments are returned.
    followUpFirstSaasPayment();
  }

  function followUpFirstSaasPayment() public virtual override {
    // Assert can make saas payment.
    uint256 saasPaymentAmount = 20 ether;
    // Set the msg.sender address to that of the _userWallet for the next call.

    vm.prank(address(_userWallet));
    // Directly call the function on the deployed contract.
    _dim.receiveSaasPayment{ value: saasPaymentAmount }();

    // Get the payment splitter from the _dim contract.
    CustomPaymentSplitter paymentSplitter = _dim.getPaymentSplitter();
    // Assert the investor is added as a payee to the paymentSplitter.
    assertTrue(paymentSplitter.isPayee(_firstInvestorWallet), "The _firstInvestorWallet is not recognised as payee.");
    assertEq(
      _dim.getCumReceivedInvestments(),
      _firstInvestmentAmount,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // Tier 0 has a multiple of 10. So 0.5 * 10. Then subtract the 0.2 SAAS payment
      // but only the 0.6 fraction which is for investors.
      // 0.5 * 10 * 10^18 - 10*10^18 * 0.6 = (5 - 6)*10 =0
      0 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after first SAAS payment."
    );

    // Assert investor can retrieve saas revenue fraction.
    vm.prank(_firstInvestorWallet);
    paymentSplitter.release();
    assertEq(paymentSplitter.released(_firstInvestorWallet), 5 ether, "The amount released was unexpected.");
    assertEq(
      _firstInvestorWallet.balance,
      3 ether - 0.5 ether + 5 ether,
      "The balance of the investor was unexpected."
    );

    followUpSecondInvestment();
  }

  function followUpSecondInvestment() public virtual override {
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // _firstInvestmentAmount*10, // Tier 0 has a multiple of 10.
      0 ether,
      "Error, the cumRemainingInvestorReturn was not as expected before the second investment."
    );

    _secondInvestmentAmount = 4 ether;
    vm.prank(address(_secondInvestorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _secondInvestmentAmount }();

    // TODO: assert the tierInvestment(s) are made as expected.
    assertEq(
      _dim.getCumReceivedInvestments(),
      _firstInvestmentAmount + _secondInvestmentAmount,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // Initial investment is 0.5, ceiling is 4, so 3.5 *10, and 0.5 remains.
      10 * 3.5 ether + 5 * 0.5 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after the second investment."
    );
    assertEq(
      _dim.getTierInvestmentLength(),
      3,
      "Error, the _tierInvestments.length was not as expected after second investment."
    );

    followUpSecondSaasPayment();
  }

  function followUpSecondSaasPayment() public virtual override {
    // Assert can make saas payment.
    uint256 saasPaymentAmount = 1 ether;
    // Set the msg.sender address to that of the _userWallet for the next call.
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // The first investor is made whole, so only the second investment is
      // still to be returned.
      10 * 3.5 ether + 5 * 0.5 ether,
      "Error, the cumRemainingInvestorReturn was not as expected before second SAAS payment."
    );

    vm.prank(address(_userWallet));
    // Directly call the function on the deployed contract.
    _dim.receiveSaasPayment{ value: saasPaymentAmount }();

    // Get the payment splitter from the _dim contract.
    CustomPaymentSplitter paymentSplitter = _dim.getPaymentSplitter();
    // Assert the investor is added as a payee to the paymentSplitter.
    assertTrue(paymentSplitter.isPayee(_secondInvestorWallet), "The _firstInvestorWallet is not recognised as payee.");

    assertEq(
      _dim.getCumReceivedInvestments(),
      _firstInvestmentAmount + _secondInvestmentAmount,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // 10 * 3.5 ether + 5 * 0.5 ether - 1*0.6 =
      10 * 3.5 ether + 5 * 0.5 ether - 0.6 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after second SAAS payment."
    );

    // Assert investor can retrieve saas revenue fraction.
    vm.prank(_secondInvestorWallet);
    paymentSplitter.release();

    assertEq(
      paymentSplitter.released(_secondInvestorWallet),
      0.6 ether,
      "The amount released was unexpected for investorWallet1."
    );

    assertEq(
      _secondInvestorWallet.balance,
      4 ether - 4 ether + 0.6 ether,
      "The balance of the investorWallet1 was unexpected."
    );
  }
}
