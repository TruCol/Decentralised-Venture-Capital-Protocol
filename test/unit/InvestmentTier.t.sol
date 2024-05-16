// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../../src/Tier.sol";
import { TierInvestment } from "../../src/TierInvestment.sol";

interface Interface {
  function setUp() external;

  function testAttributes() external;
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract TierTest is PRBTest, StdCheats, Interface {
  address internal _testAddress;
  Tier internal _tierInterface;

  TierInvestment internal _tierInvestment;

  /// @dev A function invoked before each test case is run.
  function setUp() public override {
    _testAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    // Instantiate the attribute for the contract-under-test.
    _tierInterface = new Tier(0, 10_000, 10); // Set expected values

    // Instantiate the object that is tested.
    _tierInvestment = new TierInvestment(_testAddress, 43, _tierInterface);
  }

  /**
   * Test the _tierInvestment object can be created with valid values, and that
   * its public parameters are available, and that its private parameters are
   * not available.
   *
   */
  function testAttributes() public override {
    // Fail first: The test detects the invalid commented address below.
    // address expectedAddress = 0xF39fD6E51aad88F6f4ce6AB8827279cFFFb92268;
    // Actual expected address.
    address expectedAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    assert(_tierInvestment.getInvestor() == expectedAddress);
    assertEq(_tierInvestment.getNewInvestmentAmount(), 43, "The maxVal was not as expected");
  }
}
