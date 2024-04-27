// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { Tier } from "../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
struct Offer {
  address payable _offerInvestor;
  uint256 _investmentAmount;
  uint16 _offerMultiplier;
  uint256 _offerDuration; // Time in seconds for project lead to decide
  uint256 _offerStartTime;
  bool _offerIsAccepted;
}

interface Interface {
  function makeOffer(uint16 multiplier, uint256 duration) external payable;

  function getOffer(uint256 offerId) external returns (Offer memory);

  function getOwner() external returns (address payable);

  function acceptOrRejectOffer(uint256 offerId, bool accept) external;
}

contract ReceiveCounterOffer is Interface {
  uint256 private _offerInvestmentAmount;
  uint16 private _offerMultiplier;
  uint256 private _offerDuration; // Time in seconds for project lead to decide
  uint256 private _offerStartTime;
  bool private _offerIsAccepted;
  address payable private _owner;

  Offer[] public offers;
  address private _projectLead;

  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "The message is sent by someone other than the owner of this contract.");
    _;
  }

  /**
   * Constructor for creating a Tier instance. The values cannot be changed
   * after creation.
   *
   */
  constructor(address projectLead) public {
    _owner = payable(msg.sender);
    _projectLead = projectLead;
  }

  function makeOffer(uint16 multiplier, uint256 duration) external payable override {
    offers.push(Offer(payable(msg.sender), msg.value, multiplier, duration, block.timestamp, false));
  }

  function getOffer(uint256 offerId) public view override returns (Offer memory) {
    require(offerId < offers.length, "Invalid offer ID");
    return offers[offerId];
  }

  function getOwner() public view override returns (address payable) {
    return _owner;
  }

  function acceptOrRejectOffer(uint256 offerId, bool accept) public override {
    require(msg.sender == _projectLead, "Only project lead can accept offer");
    // Offer memory offer ==
    Offer memory offer = getOffer(offerId);
    require(!offer._offerIsAccepted, "Offer already accepted");
    require(block.timestamp <= offer._offerStartTime + offer._offerDuration, "Offer expired");

    if (accept) {
      offer._offerIsAccepted = true;
      DecentralisedInvestmentManager dim = DecentralisedInvestmentManager(_owner);
      dim.receiveAcceptedOffer{ value: offer._investmentAmount }(offer._offerInvestor);

      // the transaction is rejected e.g. because the investmentCeiling is reached.
    } else {
      offer._offerIsAccepted = false;
    }
  }
}
