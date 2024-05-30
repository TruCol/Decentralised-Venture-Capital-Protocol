// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { TierInvestment } from "../../src/TierInvestment.sol";
import { SaasPaymentProcessor } from "../../src/SaasPaymentProcessor.sol";
import { Tier } from "../../src/Tier.sol";
import { Helper } from "../../src/Helper.sol";

interface ISaasPaymentProcessorTest {
  function setUp() external;

  function testOnlyOwnerTriggered() external;

  function testOnlyOwnerPasses() external;

  function testZeroInvestorReturn() external;
}

contract SaasPaymentProcessorTest is PRBTest, StdCheats, ISaasPaymentProcessorTest {
  SaasPaymentProcessor private _saasPaymentProcessor;
  Helper private _helper;
  TierInvestment[] private _tierInvestments;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    _saasPaymentProcessor = new SaasPaymentProcessor();
    _helper = new Helper();
  }

  function testOnlyOwnerTriggered() public virtual override {
    Tier someTier = new Tier(0, 8, 55);
    address unauthorisedAddress = address(0);
    vm.prank(unauthorisedAddress); // Simulating setting the investment from another address.
    vm.expectRevert(
      abi.encodeWithSignature(
        "SaasPaymentProcessorOnlyOwner(string,address,address)",
        "Message sender is not owner.",
        address(this),
        unauthorisedAddress
      )
    );
    _saasPaymentProcessor.addInvestmentToCurrentTier(10, address(2), someTier, 50);
  }

  function testOnlyOwnerPasses() public virtual override {
    Tier someTier = new Tier(0, 8, 55);
    _saasPaymentProcessor.addInvestmentToCurrentTier(10, address(2), someTier, 50);
  }

  function testZeroInvestorReturn() public virtual override {
    address testAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    // Instantiate the attribute for the contract-under-test.
    Tier tierInterface = new Tier(0, 10_000, 10); // Set expected values

    // Instantiate the object that is tested.
    TierInvestment tierInvestment = new TierInvestment(testAddress, 43, tierInterface);

    _tierInvestments.push(tierInvestment);

    vm.expectRevert(
      abi.encodeWithSignature(
        "SaasRevenueForInvestorsSmallerThanOne(string,uint256)",
        "saasRevenueForInvestors is not larger than 0.",
        0
      )
    );
    _saasPaymentProcessor.computeInvestorReturns(_helper, _tierInvestments, 0, 0);
    vm.expectRevert(
      abi.encodeWithSignature("DenominatorSmallerThanOne(string,uint256)", "Denominator not larger than 0", 0)
    );
    _saasPaymentProcessor.computeInvestorReturns(_helper, _tierInvestments, 1, 0);

    // Add two tiers

    _tierInvestments.push(new TierInvestment(testAddress, 1, tierInterface));
  }
}
