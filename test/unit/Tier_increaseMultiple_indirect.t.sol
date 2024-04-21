// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { console2 } from "forge-std/src/console2.sol";
import { Tier } from "../../src/Tier.sol";
// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

// Import the paymentsplitter that has the shares for the investors.
import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";

// Import contract that is an attribute of main contract to test the attribute.
import { TierInvestment } from "../../src/TierInvestment.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract MultipleInvestmentTest is PRBTest, StdCheats {
  address internal _projectLeadAddress;
  address payable _investorWallet0;
  address payable _investorWallet1;
  address private _userWallet;
  Tier[] private _tiers;
  uint256 private _investmentAmount0;
  uint256 private _investmentAmount1;

  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;

  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
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
      _projectLeadAddress
    );

    _investorWallet0 = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet0, 3 ether);
    _investorWallet1 = payable(address(uint160(uint256(keccak256(bytes("2"))))));
    deal(_investorWallet1, 4 ether);

    _userWallet = address(uint160(uint256(keccak256(bytes("3")))));
    deal(_userWallet, 100 ether);

    // Print the addresses to console.

    _investmentAmount0 = 0.5 ether;

    // Set the msg.sender address to that of the _investorWallet0 for the next call.
    vm.prank(address(_investorWallet0));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: _investmentAmount0 }();
    assertEq(_dim.getTierInvestmentLength(), 1, "Error, the _tierInvestments.length was not as expected.");
    uint256 startBalance = _investorWallet0.balance;
  }

  /**
  @dev The investor has invested 0.5 eth, at a multiple of 10. Then the
  multiple of that tier gets increased to 20, but that was after the investment
  was made, so the investor still gets a multiple of 10, yielding a return of 5
  ether.
   */

  function testIncreaseMultipleIndirectly() public {
    // Assert project lead can increase multiple.
    vm.prank(_projectLeadAddress);
    _dim.increaseCurrentMultipleInstantly(20);
    assertEq(_dim.getCurrentTier().multiple(), 20, "The multiple was not 20.");

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

  /**
The multiple has increased from 10 to 20, the ceiling of the first investment
tier is 4 ether, and 0.5 has already been invested, and 5 ether has already
been paid out, so the cumulative remaining return becomes 3.5*20 +0.5*5 (5 is
the multiple of the xecond tier) = 72.5 ether.
*/
  function followUpSecondInvestment() public {
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // _investmentAmount0*10, // Tier 0 has a multiple of 10.
      0 ether,
      "Error, the cumRemainingInvestorReturn was not as expected before the second investment."
    );

    _investmentAmount1 = 4 ether;
    vm.prank(address(_investorWallet1));
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

  function followUpSecondSaasPayment() public {
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
    assertTrue(paymentSplitter.isPayee(_investorWallet1), "The _investorWallet0 is not recognised as payee.");
    assertEq(
      _dim.getCumReceivedInvestments(),
      _investmentAmount0 + _investmentAmount1,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // 10 * 3.5 ether + 5 * 0.5 ether - 1*0.6 =
      20 * 3.5 ether + 5 * 0.5 ether - 0.6 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after second SAAS payment."
    );

    // Assert investor can retrieve saas revenue fraction.
    paymentSplitter.release(_investorWallet1);
    assertEq(
      paymentSplitter.released(_investorWallet1),
      0.6 ether,
      "The amount released was unexpected for investorWallet1."
    );
    assertEq(
      _investorWallet1.balance,
      4 ether - 4 ether + 0.6 ether,
      "The balance of the investorWallet1 was unexpected."
    );
  }
}
