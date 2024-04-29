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

  function testPullbackOfferOtherThanInvestor() external;

  function testPullbackAcceptedOffer() external;

  function testPullbackOfferExpired() external;
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
    vm.expectRevert(bytes("Offer already rejected or accepted."));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Offer already rejected or accepted."));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);

    // TODO: assert investor has investment back.
  }

  function testRejectCounterOffer() public virtual override {
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    assertEq(_investorWallet.balance, 3 ether, "Start balance of investor unexpected.");
    vm.prank(_investorWallet);
    _receiveCounterOfferContract.makeOffer{ value: 2 ether }(201, 4 weeks);
    assertEq(_investorWallet.balance, 1 ether, "Balance of investor unexpected after offer.");

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "A: The TierInvestment length was not 0.");

    // Simulate 3 weeks passing by
    vm.warp(block.timestamp + 3 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "C: The TierInvestment length was not 0.");

    // Assert revert when trying to accept the investment.
    vm.expectRevert(bytes("Only project lead can accept offer"));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);
    assertEq(_investorWallet.balance, 1 ether, "Balance of investor unexpected after offer.");

    vm.prank(_projectLeadAddress);
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);
    vm.warp(block.timestamp + 5 weeks);

    vm.prank(_investorWallet);
    _receiveCounterOfferContract.pullbackOffer(0);
    assertEq(_investorWallet.balance, 3 ether, "Balance of investor not recovered after reject.");

    assertEq(_dim.getTierInvestmentLength(), 0, "D: The TierInvestment length was not 0.");

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Offer already rejected or accepted."));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Offer already rejected or accepted."));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);

    // TODO: assert investor has investment back.
  }

  function testPullbackOfferOtherThanInvestor() public virtual override {
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    _receiveCounterOfferContract.makeOffer{ value: 40 ether }(201, 4 weeks);

    vm.prank(address(111));
    vm.expectRevert(bytes("Someone other than the investor tried to retrieve offer."));
    _receiveCounterOfferContract.pullbackOffer(0);
  }

  function testPullbackAcceptedOffer() public virtual override {
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    _receiveCounterOfferContract.makeOffer{ value: 1 ether }(201, 4 weeks);

    vm.prank(_projectLeadAddress);
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.expectRevert(bytes("The offer has been accepted, so can't pull back."));
    _receiveCounterOfferContract.pullbackOffer(0);
  }

  function testPullbackOfferExpired() public virtual override {
    assertEq(_investorWallet.balance, 3 ether, "Start balance of investor unexpected.");
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    vm.prank(_investorWallet);
    _receiveCounterOfferContract.makeOffer{ value: 1 ether }(201, 4 weeks);
    assertEq(_investorWallet.balance, 2 ether, "Start after investment balance of investor unexpected.");

    vm.prank(_investorWallet);
    vm.expectRevert(bytes("The offer duration has not yet expired."));
    _receiveCounterOfferContract.pullbackOffer(0);

    vm.prank(_investorWallet);
    vm.warp(block.timestamp + 5 weeks);
    _receiveCounterOfferContract.pullbackOffer(0);
    assertEq(_investorWallet.balance, 3 ether, "Start after revert balance of investor unexpected.");
  }
}
