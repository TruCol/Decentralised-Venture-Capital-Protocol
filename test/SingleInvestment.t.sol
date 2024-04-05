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
    assertEq(address(1).balance, 43);
    // dim = new DecentralisedInvestmentManager(projectLeadFracNumerator,projectLeadFracDenominator, testAddress);
  }

  function testAttributes() public {}
}
