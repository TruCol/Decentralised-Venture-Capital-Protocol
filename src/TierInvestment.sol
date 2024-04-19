// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { console2 } from "forge-std/src/console2.sol";

contract TierInvestment {
  address public investor;
  uint256 public newInvestmentAmount;
  Tier private tier;

  /**
   * The amount of DAI that is still to be returned for this investment.
   */
  uint256 public remainingReturn;

  /**
   * The amount of DAI that the investor can collect as ROI.
   */
  uint256 public collectivleReturn;

  address private _owner;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(address someInvestor, uint256 _newInvestmentAmount, Tier _tier) {
    require(_newInvestmentAmount >= 1, "A new investment amount should at least be 1.");
    _owner = msg.sender;

    investor = someInvestor;
    newInvestmentAmount = _newInvestmentAmount;
    tier = _tier;

    // Initialise default value.
    remainingReturn = _newInvestmentAmount * tier.multiple();
  }

  /**
   * Public counterpart of the _addPayee function, to add users that can withdraw
   *   funds after constructor initialisation.
   */
  function publicSetRemainingReturn(address someInvestor, uint256 newlyReturnedAmount) public onlyOwner {
    require(someInvestor != address(0), "The investor address is equal to the address of this contract.");
    remainingReturn = remainingReturn - newlyReturnedAmount;
  }

  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "The message is sent by someone other than the owner of this contract.");
    _;
  }

  /**
  Used for testing, returns the amount that is invested in this TierInvestment. */
  function getAmountInvestedInThisTierInvestment() public view returns (uint256) {
    return newInvestmentAmount;
  }

  function getTier() public view returns (Tier) {
    return tier;
  }

  function getInvestor() public view returns (address) {
    return investor;
  }
}
