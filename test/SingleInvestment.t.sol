// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { DecentralisedInvestmentManager } from "../src/DecentralisedInvestmentManager.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract SingleInvestmentTest is PRBTest, StdCheats {
  address internal firstFoundryAddress;
  DecentralisedInvestmentManager dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the attribute for the contract-under-test.
    firstFoundryAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 projectLeadFracNumerator = 4;
    uint256 projectLeadFracDenominator = 10;
    // assertEq(address(firstFoundryAddress).balance, 43);
    deal(address(1), 43 ether);
    assertEq(address(1).balance, 43 ether);
    dim = new DecentralisedInvestmentManager(projectLeadFracNumerator, projectLeadFracDenominator, address(0));
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function test_SimulateLargerBalance() public {
    // Get the contract's address
    address payable contractAddress = payable(address(0));

    // Simulate sending 10 ETH to the contract
    deal(contractAddress, 10 ether);

    // Get the contract's balance after simulation
    uint256 simulatedBalance = contractAddress.balance;

    // Assert the simulated balance is as expected
    assertEq(simulatedBalance, 10 ether, "Simulated balance mismatch");
  }

  function testAttributes() public {}
}
