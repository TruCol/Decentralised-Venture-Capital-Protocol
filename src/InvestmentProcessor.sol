// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";

interface Interface {
  function addInvestmentToCurrentTier(
    uint256 cumReceivedInvestments,
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
  ) external returns (uint256, TierInvestment newTierInvestment);
}

contract InvestmentProcessor is Interface {
  address private _owner;
  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "The sender of this message is not the owner.");
    _;
  }

  constructor() public {
    _owner = msg.sender;
  }

  /**
  @notice This creates a tierInvestment object/contract for the current tier.
  Since it takes in the current tier, it stores the multiple used for that tier
  to specify how much the investor may retrieve. Furthermore, it tracks how
  much investment this contract has received in total using
  _cumReceivedInvestments.
   */
  function addInvestmentToCurrentTier(
    uint256 cumReceivedInvestments,
    address investorWallet,
    Tier currentTier,
    uint256 newInvestmentAmount
  ) public override onlyOwner returns (uint256, TierInvestment newTierInvestment) {
    newTierInvestment = new TierInvestment(investorWallet, newInvestmentAmount, currentTier);
    cumReceivedInvestments += newInvestmentAmount;
    return (cumReceivedInvestments, newTierInvestment);
  }
}
