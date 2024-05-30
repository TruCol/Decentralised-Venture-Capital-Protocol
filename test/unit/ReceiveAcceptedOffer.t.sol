// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

interface IReveiveAcceptedOfferTest {
  function setUp() external;

  function testReceiveZeroInvestmentOffer() external;

  function testReceiveInvestmentOfferCeilingReached() external;
}

contract ReveiveAcceptedOfferTest is PRBTest, StdCheats, IReveiveAcceptedOfferTest {
  address payable private _investorWallet;
  address private _userWallet;
  DecentralisedInvestmentManager private _dim;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    uint256[] memory ceilings = new uint256[](3);
    ceilings[0] = 4;
    ceilings[1] = 15;
    ceilings[2] = 30;
    uint8[] memory multiples = new uint8[](3);
    multiples[0] = 10;
    multiples[1] = 5;
    multiples[2] = 2;
    InitialiseDim initDim = new InitialiseDim({
      ceilings: ceilings,
      multiples: multiples,
      raisePeriod: 12 weeks,
      investmentTarget: 29,
      projectLead: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();

    // Assert the _cumReceivedInvestments is 0 after Initialisation.
    assertEq(_dim.getCumReceivedInvestments(), 0);

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 3 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);
  }

  function testReceiveZeroInvestmentOffer() public virtual override {
    // vm.expectRevert(bytes("The amount invested was not larger than 0."));
    vm.expectRevert(
      abi.encodeWithSignature(
        "AcceptedInvestmentOfferSmallerThanOne(string,uint256)",
        "Accepted investment offer payment below 1.",
        0
      )
    );
    _dim.receiveAcceptedOffer{ value: 0 }(payable(address(0)));

    // vm.expectRevert(bytes("The contract calling this function was not counterOfferContract."));
    vm.expectRevert(
      abi.encodeWithSignature(
        "OfferMadeByDifferentAddressThanCounterOfferContract(string,address,address)",
        "The contract calling this function was not counterOfferContract.",
        address(this),
        address(0)
      )
    );

    _dim.receiveAcceptedOffer{ value: 10 }(payable(address(0)));
  }

  function testReceiveInvestmentOfferCeilingReached() public virtual override {
    vm.prank(_investorWallet);
    _dim.receiveInvestment{ value: 30 }();
    // TODO: Assert the investment ceiling is reached

    vm.deal(address(_dim.getReceiveCounterOffer()), 10);
    vm.prank(address(_dim.getReceiveCounterOffer()));
    // vm.expectRevert(bytes("The investor ceiling is reached."));
    vm.expectRevert(
      abi.encodeWithSignature(
        "InvestmentCeilingReachedForAcceptedOffer(string,uint256)",
        "Cannot receive accepted investment, investment ceiling is reached.",
        30
      )
    );
    _dim.receiveAcceptedOffer{ value: 10 }(payable(address(0)));
  }
}
