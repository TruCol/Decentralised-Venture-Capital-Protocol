// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { console2 } from "forge-std/src/console2.sol";

contract TierInvestment {
  address private _investor;
  uint256 private _newInvestmentAmount;
  Tier private _tier;

  /**
   * The amount of DAI that is still to be returned for this investment.
   */
  uint256 private _remainingReturn;

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
  constructor(address someInvestor, uint256 newInvestmentAmount, Tier tier) {
    require(newInvestmentAmount >= 1, "A new investment amount should at least be 1.");
    _owner = msg.sender;

    _investor = someInvestor;
    _newInvestmentAmount = newInvestmentAmount;
    _tier = tier;

    // Initialise default value.
    _remainingReturn = _newInvestmentAmount * tier.getMultiple();
  }

  /**
   * Public counterpart of the _addPayee function, to add users that can withdraw
   *   funds after constructor initialisation.
   */
  function publicSetRemainingReturn(address someInvestor, uint256 newlyReturnedAmount) public onlyOwner {
    require(_investor == someInvestor, "Error, the new return is being set for the wrong investor.");
    _remainingReturn = _remainingReturn - newlyReturnedAmount;
  }

  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "The message is sent by someone other than the owner of this contract.");
    _;
  }

  function getInvestor() public view returns (address investor) {
    investor = _investor;
    return investor;
  }

  function getNewInvestmentAmount() public view returns (uint256 newInvestmentAmount) {
    newInvestmentAmount = _newInvestmentAmount;
    return newInvestmentAmount;
  }

  function getRemainingReturn() public view returns (uint256 remainingReturn) {
    remainingReturn = _remainingReturn;
    return remainingReturn;
  }
}
