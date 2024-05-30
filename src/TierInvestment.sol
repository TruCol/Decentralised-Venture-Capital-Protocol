// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25; // Specifies the Solidity compiler version.

import { Tier } from "../src/Tier.sol";
error UnauthorizedOwnerAction(string message, address sender);
error InvalidInvestmentAmount(string message, uint256 amount);
error InvalidInvestorAddress(string message);
error IncorrectInvestorUpdate(string message, address wrongInvestor);

interface ITierInvestment {
  function publicSetRemainingReturn(address someInvestor, uint256 newlyReturnedAmount) external;

  function getInvestor() external view returns (address investor);

  function getNewInvestmentAmount() external view returns (uint256 newInvestmentAmount);

  function getRemainingReturn() external view returns (uint256 remainingReturn);

  function getOwner() external view returns (address owner);
}

contract TierInvestment is ITierInvestment {
  address private immutable _INVESTOR;
  uint256 private immutable _NEW_INVESTMENT_AMOUNT;
  Tier private immutable _TIER;

  /**
   * The amount of DAI that is still to be returned for this investment.
   */
  uint256 private _remainingReturn;

  address private immutable _OWNER;

  event RemainingReturnDecreased(uint256 indexed oldRemainingReturn, uint256 indexed newRemainingReturn);

  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    // require(msg.sender == _OWNER, "The message is sent by someone other than the owner of this contract.");
    if (msg.sender != _OWNER) {
      revert UnauthorizedOwnerAction("Only the contract owner can perform this action.", msg.sender);
    }

    _;
  }

  /**
  @notice This function is the constructor used to create a new TierInvestment contract instance.

  @dev All parameters are set during construction and cannot be modified afterwards.

  @param someInvestor The address of the investor who is making the investment.
  @param newInvestmentAmount The amount of Wei invested by the investor. Must be greater than or equal to 1 Wei.
  @param tier The Tier object containing investment details like multiplier and lockin period.
  */
  // solhint-disable-next-line comprehensive-interface
  constructor(address someInvestor, uint256 newInvestmentAmount, Tier tier) {
    // require(newInvestmentAmount >= 1, "A new investment amount should at least be 1.");
    if (newInvestmentAmount < 1) {
      revert InvalidInvestmentAmount("New investment amount must be at least 1 wei.", newInvestmentAmount);
    }

    _OWNER = msg.sender;

    // require(someInvestor != address(0), "someInvestor address can't be 0.");
    if (someInvestor == address(0)) {
      revert InvalidInvestorAddress("The provided investor address cannot be zero.");
    }

    _INVESTOR = someInvestor;
    _NEW_INVESTMENT_AMOUNT = newInvestmentAmount;
    _TIER = tier;

    // Initialise default value.

    _remainingReturn = _NEW_INVESTMENT_AMOUNT * tier.getMultiple();
  }

  /**
  @notice Sets the remaining return amount for the investor for whom this TierInvestment was made.
  @dev This function allows the owner of the TierInvestment object to set the remaining return amount for a specific
  investor. It subtracts the newly returned amount from the remaining return balance.
  @param someInvestor The address of the investor for whom the remaining return amount is being set.
  @param newlyReturnedAmount The amount newly returned by the investor.
  */
  function publicSetRemainingReturn(address someInvestor, uint256 newlyReturnedAmount) public override onlyOwner {
    // require(_INVESTOR == someInvestor, "Error, the new return is being set for the wrong investor.");

    if (_INVESTOR != someInvestor) {
      revert IncorrectInvestorUpdate("Cannot set return for a different investor.", someInvestor);
    }

    // Store the old remaining return for the event emit.
    uint256 oldRemainingReturn = _remainingReturn;
    _remainingReturn = _remainingReturn - newlyReturnedAmount;
    emit RemainingReturnDecreased(oldRemainingReturn, _remainingReturn);
  }

  /**
  @notice Retrieves the address of the investor associated with this TierInvestment object.
  @dev This function is a view function that returns the address of the investor associated with this TierInvestment
  object.
  @return investor The address of the investor.
  */
  function getInvestor() public view override returns (address investor) {
    investor = _INVESTOR;
    return investor;
  }

  /**
  @notice Retrieves investment amount associated with this TierInvestment object.
  @dev This function is a view function that returns the investment amount associated with this TierInvestment object.
  @return newInvestmentAmount The new investment amount.
  */
  function getNewInvestmentAmount() public view override returns (uint256 newInvestmentAmount) {
    newInvestmentAmount = _NEW_INVESTMENT_AMOUNT;
    return newInvestmentAmount;
  }

  /**
  @notice Retrieves the remaining return amount that the investor can still get with this TierInvestment object.
  @dev This function is a view function that returns the remaining return that the investor can still get with this
  TierInvestment object.
  @return remainingReturn The remaining return amount.
  */
  function getRemainingReturn() public view override returns (uint256 remainingReturn) {
    remainingReturn = _remainingReturn;
    return remainingReturn;
  }

  /**
  @notice Retrieves the address of the owner of this contract.
  @dev This function is a view function that returns the address of the owner of this contract.
  @return owner The address of the owner.
  */
  function getOwner() public view override returns (address owner) {
    owner = _OWNER;
    return owner;
  }
}
