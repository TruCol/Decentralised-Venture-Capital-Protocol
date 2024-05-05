// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { Tier } from "../../src/Tier.sol";
// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

// Import the paymentsplitter that has the shares for the investors.
import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";

interface Interface {
  function setUp() external;

  function testMultipleInvestments() external;

  function followUpFirstSaasPayment() external;

  function followUpSecondInvestment() external;

  function followUpSecondSaasPayment() external;
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract MultipleInvestmentTest is PRBTest, StdCheats, Interface {
  address internal _projectLeadAddress;

  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  address payable private _investorWallet0;
  address payable private _investorWalletA;
  uint256 private _investmentAmount0;
  uint256 private _investmentAmount1;
  address private _userWallet;
  Tier[] private _tiers;

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
    Tier tier0 = new Tier(0, firstTierCeiling, 10);
    _tiers.push(tier0);
    Tier tier1 = new Tier(firstTierCeiling, secondTierCeiling, 5);
    _tiers.push(tier1);
    Tier tier2 = new Tier(secondTierCeiling, thirdTierCeiling, 2);
    _tiers.push(tier2);

    _dim = new DecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress,
      12 weeks,
      3 ether
    );

    _investorWallet0 = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet0, 3 ether);
    _investorWalletA = payable(address(uint160(uint256(keccak256(bytes("2"))))));
    deal(_investorWalletA, 4 ether);

    _userWallet = address(uint160(uint256(keccak256(bytes("3")))));
    deal(_userWallet, 100 ether);

    // Print the addresses to console.
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testMultipleInvestments() public virtual override {
    uint256 startBalance = _investorWallet0.balance;
    _investmentAmount0 = 0.5 ether;

    // Set the msg.sender address to that of the _investorWallet0 for the next call.
    vm.prank(address(_investorWallet0));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _investmentAmount0 }();

    // Assert that user balance decreased by the investment amount
    uint256 endBalance = _investorWallet0.balance;
    assertEq(
      startBalance - endBalance,
      _investmentAmount0,
      "_investmentAmount0 not equal to difference in investorWalletBalance"
    );

    // TODO: assert the tierInvestment(s) are made as expected.
    assertEq(
      _dim.getCumReceivedInvestments(),
      _investmentAmount0,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // _investmentAmount0*10, // Tier 0 has a multiple of 10.
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
    assertTrue(paymentSplitter.isPayee(_investorWallet0), "The _investorWallet0 is not recognised as payee.");
    assertEq(
      _dim.getCumReceivedInvestments(),
      _investmentAmount0,
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

    paymentSplitter.release(_investorWallet0);
    assertEq(paymentSplitter.released(_investorWallet0), 5 ether, "The amount released was unexpected.");
    assertEq(_investorWallet0.balance, 3 ether - 0.5 ether + 5 ether, "The balance of the investor was unexpected.");

    followUpSecondInvestment();
  }

  function followUpSecondInvestment() public virtual override {
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // _investmentAmount0*10, // Tier 0 has a multiple of 10.
      0 ether,
      "Error, the cumRemainingInvestorReturn was not as expected before the second investment."
    );

    _investmentAmount1 = 4 ether;
    vm.prank(address(_investorWalletA));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _investmentAmount1 }();

    // TODO: assert the tierInvestment(s) are made as expected.
    assertEq(
      _dim.getCumReceivedInvestments(),
      _investmentAmount0 + _investmentAmount1,
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
    assertTrue(paymentSplitter.isPayee(_investorWalletA), "The _investorWallet0 is not recognised as payee.");

    assertEq(
      _dim.getCumReceivedInvestments(),
      _investmentAmount0 + _investmentAmount1,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // 10 * 3.5 ether + 5 * 0.5 ether - 1*0.6 =
      10 * 3.5 ether + 5 * 0.5 ether - 0.6 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after second SAAS payment."
    );

    // Assert investor can retrieve saas revenue fraction.
    paymentSplitter.release(_investorWalletA);

    assertEq(
      paymentSplitter.released(_investorWalletA),
      0.6 ether,
      "The amount released was unexpected for investorWallet1."
    );

    assertEq(
      _investorWalletA.balance,
      4 ether - 4 ether + 0.6 ether,
      "The balance of the investorWallet1 was unexpected."
    );
  }
}
