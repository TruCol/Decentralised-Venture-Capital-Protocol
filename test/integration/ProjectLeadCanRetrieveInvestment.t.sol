// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface IProjectLeadCanRetrieveInvestmentTest {
  function setUp() external;

  function testInvestorGetsSaasRevenue() external;
}

contract ProjectLeadCanRetrieveInvestmentTest is PRBTest, StdCheats, IProjectLeadCanRetrieveInvestmentTest {
  address internal _projectLead;

  address payable private _investorWallet;
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
      investmentTarget: 0.4 ether,
      projectLead: _projectLead,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 3 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);

    // Print the addresses to console.
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testInvestorGetsSaasRevenue() public override {
    uint256 investmentAmount = 0.5 ether;

    // Set the msg.sender address to that of the _investorWallet for the next call.
    vm.prank(address(_investorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: investmentAmount }();

    // Assert project lead can retrieve investment.
    assertEq(_projectLead.balance, 0);
    // vm.prank(address(_investorWallet));
    vm.prank(address(_projectLead));
    _dim.withdraw(investmentAmount);
    assertEq(_projectLead.balance, 0.5 ether);

    // Assert can make saas payment.
    uint256 saasPaymentAmount = 0.2 ether;
    // Set the msg.sender address to that of the _userWallet for the next call.
    vm.prank(address(_userWallet));
    // Directly call the function on the deployed contract.
    _dim.receiveSaasPayment{ value: saasPaymentAmount }();

    // Get the payment splitter from the _dim contract.
    CustomPaymentSplitter paymentSplitter = _dim.getPaymentSplitter();
    // Assert the investor is added as a payee to the paymentSplitter.
    assertTrue(paymentSplitter.isPayee(_investorWallet), "The _investorWallet is not recognised as payee.");
    assertEq(
      _dim.getCumReceivedInvestments(),
      investmentAmount,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // Tier 0 has a multiple of 10. So 0.5 * 10. Then subtract the 0.2 SAAS payment
      // but only the 0.6 fraction which is for investors.
      // 0.5 * 10 * 10^18 - 0.2*10^18 * 0.6 = (5 - 0.12)*10 =4.88 = 4.88 *10^18 wei
      4.88 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after SAAS payment."
    );

    // Assert investor can retrieve saas revenue fraction.
    vm.prank(_investorWallet);
    paymentSplitter.release();
    assertEq(paymentSplitter.released(_investorWallet), 0.12 ether);
    assertEq(_investorWallet.balance, 3 ether - 0.5 ether + 0.12 ether);
  }
}
