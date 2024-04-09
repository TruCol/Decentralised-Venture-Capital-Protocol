// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { console2 } from "forge-std/src/console2.sol";

// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import contract that is being tested.
import { DecentralisedInvestmentManager } from "../src/DecentralisedInvestmentManager.sol";

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
    deal(_investorWallet, 80000 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100002 ether);
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testSingleInvestment() public {
    uint256 startBalance = _investorWallet.balance;
    uint256 investmentAmount = 20 ether;
    // Send investment directly from the user wallet
    (bool success, bytes memory result) = _investorWallet.call{ value: investmentAmount }(
      abi.encodeWithSelector(_dim.receiveInvestment.selector)
    );
    uint256 endBalance = _investorWallet.balance;

    // Assert that user balance decreased by the investment amount
    assertEq(endBalance - startBalance, investmentAmount);

    // Assert the tier investments are processed as expected.
    console2.log("BEFORE ASSERTION {0}", _dim.getTierInvestmentLength());
    assertEq(_dim.getTierInvestmentLength(), 1);
  }

  // function testReceiveInvestment_RevertsOnZeroInvestment() public {
  //   vm.prank(_userWallet); // Simulate message sender (optional)
  //   // _dim.receiveInvestment{value: 0}();
  //   // assertEq(string(expectRevert), "The amount invested was not larger than 0.");
  // }
}
