// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { Tier } from "../../src/Tier.sol";
import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface Interface {
  function setUp() external;

  function testIncreaseMultipleIndirectly() external;

  function followUpSecondInvestment() external;

  function followUpSecondSaasPayment() external;
}

contract MultipleInvestmentTest is PRBTest, StdCheats, Interface {
  address internal _projectLead;
  address payable private _investorWallet0;
  address payable private _investorWalletA;
  address private _userWallet;
  Tier[] private _tiers;
  uint256 private _investmentAmount0;
  uint256 private _investmentAmount1;

  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;

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

    _investorWallet0 = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet0, 3 ether);
    _investorWalletA = payable(address(uint160(uint256(keccak256(bytes("2"))))));
    deal(_investorWalletA, 4 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("3")))));
    deal(_userWallet, 100 ether);

    /**
    Invest 0.5 ether in tier 0 which has a ceiling of 4 ether, and multiple 10.
    This creates a cumulative remaining investor return of 5 ether.*/
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

  /**
    Invest 0.5 ether in tier 0 which has a ceiling of 4 ether, and multiple 10.
    This creates a cumulative remaining investor return of 5 ether.

    After the project lead has increased the multiple of tier 0 from 10 to 20,
    the cumulative return remains unchanged.

    Then a SAAS payment of 20 ether is made, meaning the investors have received
    5 ether (because they invested 0.5 ether when the multiple was 10 instead of 20),
    and the projectLead has received 15 ether.
    */
  function testIncreaseMultipleIndirectly() public virtual override {
    // Assert project lead can increase multiple.
    vm.prank(_projectLead);
    _dim.increaseCurrentMultipleInstantly(20);
    assertEq(_dim.getCurrentTier().getMultiple(), 20, "The multiple was not 20.");

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
      0 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after first SAAS payment."
    );

    // Assert investor can retrieve saas revenue fraction.
    vm.prank(_investorWallet0);
    paymentSplitter.release();
    assertEq(paymentSplitter.released(_investorWallet0), 5 ether, "The amount released was unexpected.");
    assertEq(_investorWallet0.balance, 3 ether - 0.5 ether + 5 ether, "The balance of the investor was unexpected.");
    followUpSecondInvestment();
  }

  /**


The multiple has increased from 10 to 20, the ceiling of the first investment
tier is 4 ether, and 0.5 has already been invested, and 5 ether has already
been paid out, so the cumulative remaining return becomes *4-0.5)*20... = 3.5*20 +0.5*5 = 72.5 ether. (5 is
the multiple of the second tier, and 0.5 is the amount of investment in the second tier).
*/
  /**
    Invest 0.5 ether in tier 0 which has a ceiling of 4 ether, and multiple 10.
    This creates a cumulative remaining investor return of 5 ether.

    After the project lead has increased the multiple of tier 0 from 10 to 20,
    the cumulative return remains unchanged.

    Then a SAAS payment of 20 ether is made, meaning the investors have received
    5 ether (because they invested 0.5 ether when the multiple was 10 instead of 20),
    and the projectLead has received 15 ether.

    Next, a second investment of 4 ether is made. 3.5 goes into Tier 0 with a multiple of 20,
    and 0.5 goes into Tier 1 with a multiple of 5. This means the cumulative remaining investor
    return becomes 3.5*20+0.5*5 = 72.5 ether.
    */
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
      20 * 3.5 ether + 5 * 0.5 ether,
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
      20 * 3.5 ether + 5 * 0.5 ether,
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
      "Error, the _cumReceivedInvestments was not as expected after second investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // 10 * 3.5 ether + 5 * 0.5 ether - 1*0.6 =
      20 * 3.5 ether + 5 * 0.5 ether - 0.6 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after second SAAS payment."
    );

    // Assert investor can retrieve saas revenue fraction.
    vm.prank(_investorWalletA);
    paymentSplitter.release();
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
