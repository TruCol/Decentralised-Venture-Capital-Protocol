// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { TierInvestment } from "../../src/TierInvestment.sol";
import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { SaasPaymentProcessor } from "../../src/SaasPaymentProcessor.sol";
import { DecentralisedInvestmentHelper } from "../../src/Helper.sol";
import { ReceiveCounterOffer } from "../../src/ReceiveCounterOffer.sol";

import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";

interface Interface {
  function setUp() external;

  function testExpireCounterOffer() external;

  function testRejectCounterOffer() external;

  function testAcceptCounterOffer() external;
}

contract CounterOfferTest is PRBTest, StdCheats, Interface {
  address internal _projectLeadAddress;
  address payable private _investorWallet;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  SaasPaymentProcessor private _saasPaymentProcessor;
  DecentralisedInvestmentHelper private _helper;
  TierInvestment[] private _tierInvestments;
  ExposedDecentralisedInvestmentManager private _exposed_dim;
  address payable private _investorWallet1;
  uint256 private _investmentAmount1;

  address[] private _withdrawers;
  uint256[] private _owedDai;

  ReceiveCounterOffer private _receiveCounterOfferContract;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Specify the investment tiers in ether.
    uint256 firstTierCeiling = 4 ether;
    uint256 secondTierCeiling = 15 ether;
    uint256 thirdTierCeiling = 30 ether;
    Tier tier0 = new Tier(0, firstTierCeiling, 10);
    _tiers.push(tier0);
    Tier tier1 = new Tier(firstTierCeiling, secondTierCeiling, 5);
    _tiers.push(tier1);
    Tier tier2 = new Tier(secondTierCeiling, thirdTierCeiling, 2);
    _tiers.push(tier2);

    // assertEq(address(_projectLeadAddress).balance, 43);
    _dim = new DecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress,
      12 weeks,
      3 ether
    );

    // Assert the _cumReceivedInvestments is 0 after Initialisation.
    assertEq(_dim.getCumReceivedInvestments(), 0);

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 3 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);

    // Initialise exposed dim.
    _exposed_dim = new ExposedDecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress,
      12 weeks,
      3 ether
    );
  }

  function testExpireCounterOffer() public virtual override {
    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "A: The TierInvestment length was not 0.");

    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    _receiveCounterOfferContract.makeOffer{ value: 40 ether }(201, 4 weeks);
    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "B: The TierInvestment length was not 0.");

    // Simulate 5 weeks passing by
    vm.warp(block.timestamp + 5 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "C: The TierInvestment length was not 0.");

    // Assert revert when trying to accept the investment.
    vm.expectRevert(bytes("Only project lead can accept offer"));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Offer expired"));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Offer expired"));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);
  }

  function testAcceptCounterOffer() public virtual override {
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();

    vm.prank(_investorWallet);
    _receiveCounterOfferContract.makeOffer{ value: 2 ether }(201, 4 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "A: The TierInvestment length was not 0.");

    // Simulate 3 weeks passing by
    vm.warp(block.timestamp + 3 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "C: The TierInvestment length was not 0.");

    // Assert revert when trying to accept the investment.
    vm.expectRevert(bytes("Only project lead can accept offer"));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLeadAddress);
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    assertEq(_dim.getTierInvestmentLength(), 1, "D: The TierInvestment length was not 1.");

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Offer already accepted"));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);
    // vm.prank( _projectLeadAddress);
    // vm.expectRevert(bytes("Offer already accepted"));
    // _receiveCounterOfferContract.acceptOrRejectOffer(0, false);
  }

  function testRejectCounterOffer() public virtual override {}
}
