// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { TierInvestment } from "../../src/TierInvestment.sol";
import { Tier } from "../../src/Tier.sol";

contract TierInvestmentTest is PRBTest, StdCheats {
  TierInvestment internal _validTierInvestment;
  address private _testAddress;
  uint256 private _investmentAmount;
  Tier internal _validTier;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    validTier = new Tier(0, 10_000, 10);
    testAddress = address(1);
    investmentAmount = 5;
    // Instantiate the contract-under-test.
    validTierInvestment = new TierInvestment(testAddress, investmentAmount, validTier);
  }

  function testTierInvestmentAttributes() public {
    // assertEq(validTierInvestment._owner(), address(0), "The owner was not as expected");
    assertEq(validTierInvestment.investor(), testAddress, "The investor was not as expected");
    assertEq(validTierInvestment.newInvestmentAmount(), investmentAmount, "The investmentAmount was not as expected.");
  }

  function testPublicSetRemainingReturn() public {
    vm.prank(address(validTierInvestment));
    vm.expectRevert(bytes("The message is sent by someone other than the owner of this contract."));
    validTierInvestment.publicSetRemainingReturn(testAddress, 10);
  }
}
