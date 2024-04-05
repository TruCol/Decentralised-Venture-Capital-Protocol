// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";

contract TierInvestment {
  address public investor;
  uint256 public newInvestmentAmount;
  Tier private _tier;

  /** The amount of DAI that is still to be returned for this investment. */
  uint256 public remainingReturn;

  /** The amount of DAI that the investor can collect as ROI. */
  uint256 public collectivleReturn;

  address private _owner;

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *  */
  constructor(address someInvestor, uint256 _newInvestmentAmount, Tier tier) {
    require(_newInvestmentAmount >= 1, "A new investment amount should at least be 1.");
    _owner = msg.sender;

    investor = someInvestor;
    newInvestmentAmount = _newInvestmentAmount;
    _tier = tier;

    // Initialise default value.
    remainingReturn = 0;
  }

  /**
  Public counterpart of the _addPayee function, to add users that can withdraw
  funds after constructor initialisation. */
  function publicSetRemainingReturn(address someInvestor, uint256 newRemainingReturn) public onlyOwner {
    require(someInvestor != address(0));
    remainingReturn = newRemainingReturn;
  }

  /**
  Used to ensure only the owner/creator of the constructor of this contract is
  able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }
}
