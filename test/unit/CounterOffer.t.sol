// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";
import { DecentralisedInvestmentManager } from "./../../src/DecentralisedInvestmentManager.sol";
import { Helper } from "./../../src/Helper.sol";
import { ReceiveCounterOffer } from "./../../src/ReceiveCounterOffer.sol";
import { SaasPaymentProcessor } from "./../../src/SaasPaymentProcessor.sol";
import { Tier } from "./../../src/Tier.sol";
import { TierInvestment } from "./../../src/TierInvestment.sol";

interface ICounterOfferTest {
  function setUp() external;

  function testExpireCounterOffer() external;

  function testRejectCounterOffer() external;

  function testAcceptCounterOffer() external;

  function testPullbackOfferOtherThanInvestor() external;

  function testPullbackAcceptedOffer() external;

  function testPullbackOfferExpired() external;
}

contract CounterOfferTest is PRBTest, StdCheats, ICounterOfferTest {
  address internal _projectLead;
  address payable private _investorWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  SaasPaymentProcessor private _saasPaymentProcessor;
  Helper private _helper;
  TierInvestment[] private _tierInvestments;
  ExposedDecentralisedInvestmentManager private _exposedDim;
  address payable private _secondInvestorWallet;
  uint256 private _secondInvestmentAmount;

  address[] private _withdrawers;
  uint256[] private _owedDai;

  ReceiveCounterOffer private _receiveCounterOfferContract;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256[] memory ceilings = new uint256[](3);
    ceilings[0] = 4 ether;
    ceilings[1] = 15 ether;
    ceilings[2] = 30 ether;
    uint8[] memory multiples = new uint8[](3);
    multiples[0] = 10;
    multiples[1] = 5;
    multiples[2] = 2;
    InitialiseDim initDim = new InitialiseDim({
      ceilings: ceilings,
      multiples: multiples,
      raisePeriod: 12 weeks,
      investmentTarget: 2 ether,
      projectLead: _projectLead,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();
    _exposedDim = initDim.getExposedDim();

    // Assert the _cumReceivedInvestments is 0 after Initialisation.
    assertEq(_dim.getCumReceivedInvestments(), 0);

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 3 ether);

    address _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);
  }

  function testExpireCounterOffer() public virtual override {
    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "A: The TierInvestment length was not 0.");

    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    _receiveCounterOfferContract.makeOffer{ value: 40 ether }(201, 4 weeks);
    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "B: The TierInvestment length was not 0.");

    // Simulate 5 weeks passing by
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 5 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "C: The TierInvestment length was not 0.");

    // Assert revert when trying to accept the investment.
    // vm.expectRevert(bytes("Only project lead can accept offer"));
    vm.expectRevert(
      abi.encodeWithSignature(
        "UnauthorizedOfferAcceptance(string,address)",
        "Only project lead can accept offer.",
        address(this)
      )
    );
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLead);
    // vm.expectRevert(bytes("Offer expired"));
    vm.expectRevert(abi.encodeWithSignature("ExpiredOffer(string,uint256)", "Offer has expired.", 0));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLead);
    // vm.expectRevert(bytes("Offer expired"));
    vm.expectRevert(abi.encodeWithSignature("ExpiredOffer(string,uint256)", "Offer has expired.", 0));
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);
  }

  function testAcceptCounterOffer() public virtual override {
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();

    vm.prank(_investorWallet);
    _receiveCounterOfferContract.makeOffer{ value: 2 ether }(201, 4 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "A: The TierInvestment length was not 0.");

    // Simulate 3 weeks passing by
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 3 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "C: The TierInvestment length was not 0.");

    // Assert revert when trying to accept the investment.
    // vm.expectRevert(bytes("Only project lead can accept offer"));
    vm.expectRevert(
      abi.encodeWithSignature(
        "UnauthorizedOfferAcceptance(string,address)",
        "Only project lead can accept offer.",
        address(this)
      )
    );
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLead);
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    assertEq(_dim.getTierInvestmentLength(), 1, "D: The TierInvestment length was not 1.");

    vm.prank(_projectLead);
    // vm.expectRevert(bytes("Offer already rejected or accepted."));
    vm.expectRevert(
      abi.encodeWithSignature("OfferAlreadyDecided(string,uint256)", "Offer has already been rejected or accepted.", 0)
    );
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLead);
    // vm.expectRevert(bytes("Offer already rejected or accepted."));
    vm.expectRevert(
      abi.encodeWithSignature("OfferAlreadyDecided(string,uint256)", "Offer has already been rejected or accepted.", 0)
    );
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
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 3 weeks);

    // Assert the amount of TierInvestments is 0.
    assertEq(_dim.getTierInvestmentLength(), 0, "C: The TierInvestment length was not 0.");

    // Assert revert when trying to accept the investment.
    // vm.expectRevert(bytes("Only project lead can accept offer"));
    vm.expectRevert(
      abi.encodeWithSignature(
        "UnauthorizedOfferAcceptance(string,address)",
        "Only project lead can accept offer.",
        address(this)
      )
    );
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);
    assertEq(_investorWallet.balance, 1 ether, "Balance of investor unexpected after offer.");

    vm.prank(_projectLead);
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 5 weeks);

    vm.prank(_investorWallet);
    _receiveCounterOfferContract.pullbackOffer(0);
    assertEq(_investorWallet.balance, 3 ether, "Balance of investor not recovered after reject.");

    assertEq(_dim.getTierInvestmentLength(), 0, "D: The TierInvestment length was not 0.");

    vm.prank(_projectLead);
    // vm.expectRevert(bytes("Offer already rejected or accepted."));
    vm.expectRevert(
      abi.encodeWithSignature("OfferAlreadyDecided(string,uint256)", "Offer has already been rejected or accepted.", 0)
    );
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    vm.prank(_projectLead);
    // vm.expectRevert(bytes("Offer already rejected or accepted."));
    vm.expectRevert(
      abi.encodeWithSignature("OfferAlreadyDecided(string,uint256)", "Offer has already been rejected or accepted.", 0)
    );
    _receiveCounterOfferContract.acceptOrRejectOffer(0, false);

    // TODO: assert investor has investment back.
  }

  function testPullbackOfferOtherThanInvestor() public virtual override {
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    _receiveCounterOfferContract.makeOffer{ value: 40 ether }(201, 4 weeks);

    vm.prank(address(111));
    // vm.expectRevert(bytes("Someone other than the investor tried to retrieve offer."));
    vm.expectRevert(
      abi.encodeWithSignature(
        "UnauthorizedOfferRetrieval(string,uint256,address)",
        "Only the investor can retrieve the offer.",
        0,
        address(111)
      )
    );
    _receiveCounterOfferContract.pullbackOffer(0);
  }

  function testPullbackAcceptedOffer() public virtual override {
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    _receiveCounterOfferContract.makeOffer{ value: 1 ether }(201, 4 weeks);

    vm.prank(_projectLead);
    _receiveCounterOfferContract.acceptOrRejectOffer(0, true);

    // vm.expectRevert(bytes("The offer has been accepted, so can't pull back."));
    vm.expectRevert(
      abi.encodeWithSignature("AlreadyAcceptedOffer(string,uint256)", "The offer has already been accepted.", 0)
    );

    _receiveCounterOfferContract.pullbackOffer(0);
  }

  function testPullbackOfferExpired() public virtual override {
    assertEq(_investorWallet.balance, 3 ether, "Start balance of investor unexpected.");
    _receiveCounterOfferContract = _dim.getReceiveCounterOffer();
    vm.prank(_investorWallet);
    _receiveCounterOfferContract.makeOffer{ value: 1 ether }(201, 4 weeks);
    assertEq(_investorWallet.balance, 2 ether, "Start after investment balance of investor unexpected.");

    vm.prank(_investorWallet);
    // vm.expectRevert(bytes("The offer duration has not yet expired."));
    vm.expectRevert(
      abi.encodeWithSignature("OfferNotExpiredYet(string,uint256)", "Offer duration has not yet passed.", 0)
    );
    _receiveCounterOfferContract.pullbackOffer(0);

    vm.prank(_investorWallet);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 5 weeks);
    _receiveCounterOfferContract.pullbackOffer(0);
    assertEq(_investorWallet.balance, 3 ether, "Start after revert balance of investor unexpected.");
  }
}
