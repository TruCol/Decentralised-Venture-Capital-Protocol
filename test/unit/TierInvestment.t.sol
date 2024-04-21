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
    _validTier = new Tier(0, 10_000, 10);
    _testAddress = address(1);
    _investmentAmount = 5;
    // Instantiate the contract-under-test.
    _validTierInvestment = new TierInvestment(_testAddress, _investmentAmount, _validTier);
  }

  function testTierInvestmentAttributes() public {
    // assertEq(_validTierInvestment._owner(), address(0), "The owner was not as expected");
    assertEq(_validTierInvestment.investor(), _testAddress, "The investor was not as expected");
    assertEq(
      _validTierInvestment.getNewInvestmentAmount(),
      _investmentAmount,
      "The investmentAmount was not as expected."
    );
  }

  function testPublicSetRemainingReturn() public {
    vm.prank(address(_validTierInvestment));
    vm.expectRevert(bytes("The message is sent by someone other than the owner of this contract."));
    _validTierInvestment.publicSetRemainingReturn(_testAddress, 10);
  }
}
