// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { console2 } from "forge-std/src/console2.sol";

// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../src/DecentralisedInvestmentManager.sol";

// Import contract that is an attribute of main contract to test the attribute.
import { TierInvestment } from "../src/TierInvestment.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract SingleInvestmentTest is PRBTest, StdCheats {
  address internal firstFoundryAddress;
  address private _investorWallet;
  address private _userWallet;
  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the attribute for the contract-under-test.
    firstFoundryAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 projectLeadFracNumerator = 4;
    uint256 projectLeadFracDenominator = 10;
    // assertEq(address(firstFoundryAddress).balance, 43);
    _dim = new DecentralisedInvestmentManager(projectLeadFracNumerator, projectLeadFracDenominator, address(0));

    _investorWallet = address(uint160(uint256(keccak256(bytes("1")))));
    deal(_investorWallet, 80000 wei);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100002 wei);
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testSingleInvestmentOnInvestorExceedingCeiling() public {
    uint256 startBalance = _investorWallet.balance;
    uint256 investmentAmount = 200_000 wei;
    console2.log("Within test, investorWallet = ", _investorWallet);
    // Send investment directly from the investor wallet.
    (bool investmentSuccess, bytes memory investmentResult) = _investorWallet.call{ value: investmentAmount }(
      abi.encodeWithSelector(_dim.receiveInvestment.selector)
    );

    uint256 endBalance = _investorWallet.balance;

    // Assert that user balance decreased by the investment amount
    assertEq(endBalance - startBalance, investmentAmount);

    // Assert can make saas payment.
    uint256 saasPaymentAmount = 5000 wei;
    console2.log("_userWallet", _userWallet);
    // Directly call the function on the deployed contract.
    // _dim.receiveSaasPayment{ value: saasPaymentAmount }();
    (bool paymentSuccess, bytes memory paymentResult) = _userWallet.call{ value: saasPaymentAmount }(
      abi.encodeWithSelector(_dim.receiveSaasPayment.selector)
    );

    // TODO: Assert investor can retrieve saas revenue fraction.
    // (bool returnSuccess, bytes memory returnResult) = _userWallet.call{ value: saasPaymentAmount }(
    //   abi.encodeWithSelector(_dim.receiveSaasPayment.selector)
    // );
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testSingleInvestmentOnContractExceedingCeiling() public {
    uint256 investmentAmount = 200_000 wei;
    // console2.log("Within test, _dim contract address = ",_dim);
    console2.log("Within test, dim contract address = ", _dim.getContractAddress());

    // Directly call the function on the deployed contract.
    _dim.receiveInvestment{ value: investmentAmount }();

    // Assert the tier investments are processed as expected.
    console2.log("Before length assertion", _dim.getTierInvestmentLength());
    assertEq(_dim.getTierInvestmentLength(), 3);

    TierInvestment[] memory tierInvestments = _dim.getTierInvestments();

    // Assert the first tier has an amount of 10000 wei.
    TierInvestment firstTierInvestment = tierInvestments[0];
    assertEq(firstTierInvestment.getAmountInvestedInThisTierInvestment(), 10_000);
    assertEq(firstTierInvestment.getTier().multiple(), 10);
    assertEq(tierInvestments[1].getAmountInvestedInThisTierInvestment(), 40_000);
    assertEq(tierInvestments[1].getTier().multiple(), 5);
    assertEq(tierInvestments[2].getAmountInvestedInThisTierInvestment(), 50_000);
    assertEq(tierInvestments[2].getTier().multiple(), 2);

    // Assert can make saas payment.
    uint256 saasPaymentAmount = 5000 wei;
    console2.log("_userWallet", _userWallet);
    // Directly call the function on the deployed contract.
    // _dim.receiveSaasPayment{ value: saasPaymentAmount }();
    _dim.receiveInvestment{ value: saasPaymentAmount }();
  }
}
