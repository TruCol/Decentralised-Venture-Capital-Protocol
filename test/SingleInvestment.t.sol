// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { console2 } from "forge-std/src/console2.sol";

// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../src/DecentralisedInvestmentManager.sol";

// Import the paymentsplitter that has the shares for the investors.
import { CustomPaymentSplitter } from "../src/CustomPaymentSplitter.sol";

// Import contract that is an attribute of main contract to test the attribute.
import { TierInvestment } from "../src/TierInvestment.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract SimplifiedTest is PRBTest, StdCheats {
  address internal projectLeadAddress;
  address payable _investorWallet;
  address private _userWallet;
  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the attribute for the contract-under-test.
    projectLeadAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 projectLeadFracNumerator = 4;
    uint256 projectLeadFracDenominator = 10;

    // Specify the investment tiers in ether.
    uint256 firstTierCeiling = 3 ether;
    uint256 secondTierCeiling = 15 ether;
    uint256 thirdTierCeiling = 30 ether;

    // assertEq(address(projectLeadAddress).balance, 43);
    _dim = new DecentralisedInvestmentManager(
      firstTierCeiling,
      secondTierCeiling,
      thirdTierCeiling,
      projectLeadFracNumerator,
      projectLeadFracDenominator,
      projectLeadAddress
    );

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 80 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);

    // Print the addresses to console.
    console2.log("projectLeadAddress=    ", projectLeadAddress);
    console2.log("_investorWallet=       ", _investorWallet);
    console2.log("_userWallet=           ", _userWallet, "\n");
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testInvestorGetsSaasRevenue() public {
    uint256 startBalance = _investorWallet.balance;
    uint256 investmentAmount = 0.5 ether;

    console2.log("_dim balance before=", address(_dim).balance);
    // Set the msg.sender address to that of the _investorWallet for the next call.
    vm.prank(address(_investorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: investmentAmount }();

    // Assert that user balance decreased by the investment amount
    uint256 endBalance = _investorWallet.balance;
    assertEq(
      startBalance - endBalance,
      investmentAmount,
      "investmentAmount not equal to difference in investorWalletBalance"
    );
    console2.log("startBalance=", startBalance);
    console2.log("endBalance=", endBalance);
    console2.log("investmentAmount=", investmentAmount);
    console2.log("_dim balance after=", address(_dim).balance);

    // TODO: assert the tierInvestment(s) are made as expected.
    assertEq(
      _dim.getCumReceivedInvestments(),
      investmentAmount,
      "Error, the _cumReceivedInvestments was not as expected after investment."
    );
    assertEq(
      _dim.getCumRemainingInvestorReturn(),
      // investmentAmount*10, // Tier 0 has a multiple of 10.
      10 * 0.5 ether,
      "Error, the cumRemainingInvestorReturn was not as expected directly after investment."
    );

    assertEq(_dim.getTierInvestmentLength(), 1, "Error, the _tierInvestments.length was not as expected.");
    // TODO: write tests to assert the remaining investments are returned.

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
    paymentSplitter.release(_investorWallet);
    assertEq(paymentSplitter.released(_investorWallet), 0.12 ether);
  }
}
