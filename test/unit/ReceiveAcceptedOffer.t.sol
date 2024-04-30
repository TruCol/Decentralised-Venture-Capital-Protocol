// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { TierInvestment } from "../../src/TierInvestment.sol";
import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { SaasPaymentProcessor } from "../../src/SaasPaymentProcessor.sol";
import { Helper } from "../../src/Helper.sol";
import { ReceiveCounterOffer } from "../../src/ReceiveCounterOffer.sol";

import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";

interface Interface {
  function setUp() external;

  function testReceiveZeroInvestmentOffer() external;

  function testReceiveInvestmentOfferCeilingReached() external;
}

contract ReveiveAcceptedOfferTest is PRBTest, StdCheats, Interface {
  address internal _projectLeadAddress;
  address payable private _investorWallet;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  SaasPaymentProcessor private _saasPaymentProcessor;
  Helper private _helper;
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

  function testReceiveZeroInvestmentOffer() public virtual override {
    vm.expectRevert(bytes("The amount invested was not larger than 0."));
    _dim.receiveAcceptedOffer{ value: 0 }(payable(address(0)));

    vm.expectRevert(bytes("The contract calling this function was not counterOfferContract."));
    _dim.receiveAcceptedOffer{ value: 10 }(payable(address(0)));
  }

  function testReceiveInvestmentOfferCeilingReached() public virtual override {
    _dim.receiveInvestment{ value: 30 ether }();

    vm.deal(address(_dim.getReceiveCounterOffer()), 10);
    vm.prank(address(_dim.getReceiveCounterOffer()));
    vm.expectRevert(bytes("The investor ceiling is reached."));
    _dim.receiveAcceptedOffer{ value: 10 }(payable(address(0)));
  }
}
