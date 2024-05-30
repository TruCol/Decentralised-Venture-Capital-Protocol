// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { TierInvestment } from "../../src/TierInvestment.sol";
import { Tier } from "../../src/Tier.sol";

interface ITierInvestmentTest {
  function setUp() external;

  function testTierInvestmentAttributes() external;

  function testPublicSetRemainingReturn() external;

  function testGetInvestor() external;
}

contract TierInvestmentTest is PRBTest, StdCheats, ITierInvestmentTest {
  TierInvestment internal _validTierInvestment;
  address private _testAddress;
  uint256 private _investmentAmount;
  Tier internal _validTier;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    _validTier = new Tier(0, 10_000, 10);
    _testAddress = address(1);
    _investmentAmount = 5;
    // Instantiate the contract-under-test.
    _validTierInvestment = new TierInvestment(_testAddress, _investmentAmount, _validTier);
  }

  function testTierInvestmentAttributes() public virtual override {
    // assertEq(_validTierInvestment._owner(), address(0), "The owner was not as expected");
    assertEq(_validTierInvestment.getInvestor(), _testAddress, "The investor was not as expected");
    assertEq(
      _validTierInvestment.getNewInvestmentAmount(),
      _investmentAmount,
      "The investmentAmount was not as expected."
    );
  }

  function testPublicSetRemainingReturn() public virtual override {
    vm.prank(address(_validTierInvestment)); // Simulating setting the investment from another address.
    // vm.expectRevert(bytes("The message is sent by someone other than the owner of this contract."));
    vm.expectRevert(
      abi.encodeWithSignature(
        "UnauthorizedOwnerAction(string,address)",
        "Only the contract owner can perform this action.",
        address(_validTierInvestment)
      )
    );
    _validTierInvestment.publicSetRemainingReturn(_testAddress, 10);

    // Assert setting amount for wrong investor is detected.
    // vm.expectRevert(bytes("Error, the new return is being set for the wrong investor."));
    vm.expectRevert(
      abi.encodeWithSignature(
        "IncorrectInvestorUpdate(string,address)",
        "Cannot set return for a different investor.",
        address(2)
      )
    );
    _validTierInvestment.publicSetRemainingReturn(address(2), 10);

    // Assert the remaining return is set correctly.
    _validTierInvestment.publicSetRemainingReturn(_testAddress, 10);
    assertEq(_validTierInvestment.getRemainingReturn(), 40);
  }

  function testGetInvestor() public virtual override {
    address investor = _validTierInvestment.getInvestor();
    assertEq(investor, _testAddress, "The investor was not as expected");

    assertEq(_validTierInvestment.getInvestor(), _testAddress, "The investor was not as expected");
    assertNotEq(_validTierInvestment.getInvestor(), address(2), "The investor was something else");
  }
}
