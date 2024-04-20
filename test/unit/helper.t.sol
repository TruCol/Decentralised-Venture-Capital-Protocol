// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { DecentralisedInvestmentHelper } from "../../src/Helper.sol";
import { TierInvestment } from "../../src/TierInvestment.sol";
import { Tier } from "../../src/Tier.sol";

contract HelperTest is PRBTest, StdCheats {
  TierInvestment internal validTierInvestment;

  uint256 private cumReceivedInvestments;

  Tier[] private _tiers;
  Tier[] private someTiers;
  DecentralisedInvestmentHelper private _helper;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    cumReceivedInvestments = 5;

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
    _helper = new DecentralisedInvestmentHelper();
  }

  function testExceedInvestmentCeiling() public {
    // vm.prank(address(validTierInvestment));
    vm.expectRevert(bytes("Investment ceiling is reached."));
    _helper.computeCurrentInvestmentTier(30 ether + 1 wei, _tiers);
  }

  function testNegativeInvestment() public {
    // vm.prank(address(validTierInvestment));
    vm.expectRevert(
      bytes(
        "Unexpected state: No matching tier found, the lowest investment tier starting point was larger than the cumulative received investments. All (Tier) arrays should start at 0."
      )
    );
    _helper.computeCurrentInvestmentTier(1 wei, _tiers);
  }

  function testCanInvestInNextTier() public {
    // True True for tier 0.
    assertEq(_helper.computeCurrentInvestmentTier(2 wei, _tiers).multiple(), 10);

    // False False for tier 0.
    assertEq(_helper.computeCurrentInvestmentTier(10 ether + 1 wei, _tiers).multiple(), 5);

    // Hits investment ceiling
    // assertEq(_helper.computeCurrentInvestmentTier(30 ether+1 wei, _tiers).multiple(), 2);

    // True True for tier 0, True True for tier 1 but tier 1 is not reached.,
    assertEq(_helper.computeCurrentInvestmentTier(2 wei, _tiers).multiple(), 10);

    // Hits investment ceiling before this can reach Tier 0.
    // False True for tier 0, True True for tier 1
    // assertEq(_helper.computeCurrentInvestmentTier(1 wei, _tiers).multiple(), 10);
  }

  function testGetRemainingAmountInCurrentTierBelow() public {
    vm.expectRevert(bytes("Error: Tier's minimum value exceeds received investments."));
    _helper.getRemainingAmountInCurrentTier(1 wei, _tiers[0]);
  }

  function testGetRemainingAmountInCurrentTierAbove() public {
    vm.expectRevert(bytes("Error: Tier's maximum value is not larger than received investments."));
    _helper.getRemainingAmountInCurrentTier(4 ether + 1 wei, _tiers[0]);
  }

  function testComputeRemainingInvestorPayoutNegativeFraction() public {
    vm.expectRevert(bytes("investorFracNumerator is smaller than investorFracDenominator."));
    _helper.computeRemainingInvestorPayout(0, 1, 0, 0);
  }

  function testGetInvestmentCeiling() public {
    // vm.prank(address(validTierInvestment));

    assertEq(_helper.getInvestmentCeiling(_tiers), 30 ether);
  }
}
