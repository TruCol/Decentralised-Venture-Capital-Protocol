// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;
import { console2 } from "forge-std/src/console2.sol";
import { Tier } from "../../src/Tier.sol";
// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

// Import the paymentsplitter that has the shares for the investors.
import { CustomPaymentSplitter } from "../../src/CustomPaymentSplitter.sol";

// Import contract that is an attribute of main contract to test the attribute.
import { TierInvestment } from "../../src/TierInvestment.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract DecentralisedInvestmentManagerTest is PRBTest, StdCheats {
  address internal _projectLeadAddress;
  address payable _investorWallet;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the attribute for the contract-under-test.
    _projectLeadAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    _projectLeadFracNumerator = 4;
    _projectLeadFracDenominator = 10;

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
      _projectLeadAddress
    );

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 3 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function test_projectLeadFracNumerator() public {
    assertEq(_dim.getProjectLeadFracNumerator(), _projectLeadFracNumerator);
  }
}
