// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Helper } from "../../src/Helper.sol";
import { TierInvestment } from "../../src/TierInvestment.sol";
import { Tier } from "../../src/Tier.sol";

interface IHelperTest {
  function setUp() external;

  function testExceedInvestmentCeiling() external;

  function testNegativeInvestment() external;

  function testCanInvestInNextTier() external;

  function testGetRemainingAmountInCurrentTier() external;

  function testGetRemainingAmountInCurrentTierBelow() external;

  function testGetRemainingAmountInCurrentTierAbove() external;

  function testComputeRemainingInvestorPayoutNegativeFraction() external;

  function testGetInvestmentCeiling() external;

  function testComputeCumRemainingInvestorReturn() external;

  function testHasReachedInvestmentCeiling() external;
}

contract HelperTest is PRBTest, StdCheats, IHelperTest {
  uint256 private _cumReceivedInvestments;

  Tier[] private _tiers;
  Helper private _helper;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    _cumReceivedInvestments = 5;

    // Specify the investment tiers in ether.
    uint256 firstTierCeiling = 4 ether;
    uint256 secondTierCeiling = 15 ether;
    uint256 thirdTierCeiling = 30 ether;

    // Start lowst tier at 2 wei, such that the tested cumulative investment
    //amount can go below that at 1 wei.
    Tier tier0 = new Tier(2, firstTierCeiling, 10);
    _tiers.push(tier0);
    Tier tier1 = new Tier(firstTierCeiling, secondTierCeiling, 5);
    _tiers.push(tier1);
    Tier tier2 = new Tier(secondTierCeiling, thirdTierCeiling, 2);
    _tiers.push(tier2);

    // Initialise contract helper.
    _helper = new Helper();
  }

  function testExceedInvestmentCeiling() public override {
    vm.expectRevert(
      abi.encodeWithSignature(
        "ReachedInvestmentCeiling(uint256,string)",
        30 ether + 1 wei,
        "Investment ceiling is reached."
      )
    );
    Tier currentTier = _helper.computeCurrentInvestmentTier(30 ether + 1 wei, _tiers);
    assertEq(address(currentTier), address(0));
  }

  function testNegativeInvestment() public override {
    vm.expectRevert(
      bytes(
        string(
          abi.encodePacked(
            "Unexpected state: No matching tier found, the lowest ",
            "investment tier starting point was larger than the ",
            "cumulative received investments. All (Tier) arrays should start at 0."
          )
        )
      )
    );
    Tier currentTier = _helper.computeCurrentInvestmentTier(1 wei, _tiers);
    assertEq(address(currentTier), address(0));
  }

  function testCanInvestInNextTier() public override {
    // True True for tier 0.
    assertEq(_helper.computeCurrentInvestmentTier(2 wei, _tiers).getMultiple(), 10);
    assertTrue(_helper.isInRange(1, 3, 2));

    // False False for tier 0.
    assertEq(_helper.computeCurrentInvestmentTier(10 ether + 1 wei, _tiers).getMultiple(), 5);
    assertFalse(_helper.isInRange(1, 2, 4));

    // Hits investment ceiling
    // assertEq(_helper.computeCurrentInvestmentTier(30 ether+1 wei, _tiers).getMultiple(), 2);

    // True True for tier 0, True True for tier 1 but tier 1 is not reached.,
    assertEq(_helper.computeCurrentInvestmentTier(2 wei, _tiers).getMultiple(), 10);
    assertFalse(_helper.isInRange(1, 2, 0));
    assertFalse(_helper.isInRange(3, 2, 1));

    // Hits investment ceiling before this can reach Tier 0.
    // False True for tier 0, True True for tier 1
    // assertEq(_helper.computeCurrentInvestmentTier(1 wei, _tiers).getMultiple(), 10);

    // Try empty tier.
    // Tier[] memory emptyTiers;
    Tier[] memory emptyTiers = new Tier[](0);
    vm.expectRevert(
      abi.encodeWithSignature(
        "NoInvestmentTiersGiven(string message, uint256 nrOfTiers)",
        "No investmentTiers received.",
        0
      )
    );
    Tier currentTier = _helper.computeCurrentInvestmentTier(2 wei, emptyTiers);
    assertEq(address(currentTier), address(0));
  }

  function testGetRemainingAmountInCurrentTier() public override {
    assertEq(_helper.getRemainingAmountInCurrentTier(4 wei, _tiers[0]), 3999999999999999996 wei);
  }

  function testGetRemainingAmountInCurrentTierBelow() public override {
    // vm.expectRevert(bytes("Error: Tier's minimum value exceeds received investments."));
    uint256 simulatedCumReceivedInvestment = 1 wei;
    uint256 tierFloor = _tiers[0].getMinVal();
    vm.expectRevert(
      abi.encodeWithSignature(
        "TierMinAboveReceivedInvestments(string,uint256,uint256)",
        "Tier's min exceeds cumReceivedInvestments",
        simulatedCumReceivedInvestment,
        tierFloor
      )
    );
    uint256 someRemainingAmountInTier = _helper.getRemainingAmountInCurrentTier(
      simulatedCumReceivedInvestment,
      _tiers[0]
    );
    assertEq(someRemainingAmountInTier, 0, "Got a return value.");
  }

  function testGetRemainingAmountInCurrentTierAbove() public override {
    // vm.expectRevert(bytes("Error: Tier's maximum value is not larger than received investments."));
    uint256 simulatedCumReceivedInvestment = 4 ether + 1 wei;
    uint256 tierCeiling = _tiers[0].getMaxVal();
    vm.expectRevert(
      abi.encodeWithSignature(
        "TierMaxBelowReceivedInvestments(string,uint256,uint256)",
        "Tier's max below cumReceivedInvestments",
        simulatedCumReceivedInvestment,
        tierCeiling
      )
    );
    uint256 someRemainingAmountInTier = _helper.getRemainingAmountInCurrentTier({
      cumReceivedInvestments: simulatedCumReceivedInvestment,
      someTier: _tiers[0]
    });
    assertEq(someRemainingAmountInTier, 0, "Got a return value.");
  }

  function testComputeRemainingInvestorPayoutNegativeFraction() public override {
    vm.expectRevert(
      abi.encodeWithSignature(
        "InvalidInvestorFraction(string,uint256,uint256)",
        "Numerator smaller than denominator",
        0,
        1
      )
    );
    uint256 someCumRemainingInvestorReturn = _helper.computeRemainingInvestorPayout(0, 1, 0, 0);
    assertEq(someCumRemainingInvestorReturn, 0, "Got a return value.");
  }

  function testGetInvestmentCeiling() public override {
    assertEq(_helper.getInvestmentCeiling(_tiers), 30 ether);
  }

  function testComputeCumRemainingInvestorReturn() public override {
    // Assert 0 is returned for empty list.
    TierInvestment[] memory emptyTierInvestments = new TierInvestment[](0);
    assertEq(_helper.computeCumRemainingInvestorReturn(emptyTierInvestments), 0);
  }

  function testHasReachedInvestmentCeiling() public override {
    assertTrue(_helper.hasReachedInvestmentCeiling(400 ether, _tiers));
  }
}
