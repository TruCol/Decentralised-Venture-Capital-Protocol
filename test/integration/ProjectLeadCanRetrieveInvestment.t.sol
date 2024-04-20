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
contract ProjectLeadCanRetrieveInvestmentTest is PRBTest, StdCheats {
  address internal projectLeadAddress;
  address payable _investorWallet;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the attribute for the contract-under-test.
    projectLeadAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 projectLeadFracNumerator = 4;
    uint256 projectLeadFracDenominator = 10;

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

    // assertEq(address(projectLeadAddress).balance, 43);
    _dim = new DecentralisedInvestmentManager(
      _tiers,
      projectLeadFracNumerator,
      projectLeadFracDenominator,
      projectLeadAddress
    );

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 3 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);

    // Print the addresses to console.
    console2.log("projectLeadAddress=    ", projectLeadAddress);
    console2.log("_investorWallet=       ", _investorWallet);
    console2.log("_userWallet=           ", _userWallet, "\n");
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testInvestorGetsSaasRevenue() public {
    uint256 investmentAmount = 0.5 ether;

    console2.log("_dim balance before=", address(_dim).balance);
    // Set the msg.sender address to that of the _investorWallet for the next call.
    vm.prank(address(_investorWallet));
    // Send investment directly from the investor wallet into the receiveInvestment function.
    _dim.receiveInvestment{ value: investmentAmount }();

    // Assert project lead can retrieve investment.
    assertEq(projectLeadAddress.balance, 0);
    // vm.prank(address(_investorWallet)); // fail first test.
    vm.prank(address(projectLeadAddress)); // fail first test.
    _dim.withdraw(investmentAmount); // fail first test.
    assertEq(projectLeadAddress.balance, 0.5 ether);

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
    assertEq(_investorWallet.balance, 3 ether - 0.5 ether + 0.12 ether);
  }
}
