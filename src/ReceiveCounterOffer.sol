// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { Tier } from "../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import "forge-std/src/console2.sol"; // Import the console library
struct Offer {
  address payable _offerInvestor;
  uint256 _investmentAmount;
  uint16 _offerMultiplier;
  uint256 _offerDuration; // Time in seconds for project lead to decide
  uint256 _offerStartTime;
  bool _offerIsAccepted;
  bool _isDecided;
}

interface Interface {
  function makeOffer(uint16 multiplier, uint256 duration) external payable;

  function acceptOrRejectOffer(uint256 offerId, bool accept) external;

  function pullbackOffer(uint256 offerId) external;
}

contract ReceiveCounterOffer is Interface {
  uint16 private _offerMultiplier;
  uint256 private _offerDuration; // Time in seconds for project lead to decide
  uint256 private _offerStartTime;
  bool private _offerIsAccepted;
  bool private _isDecided;

  Offer[] private _offers;
  address private _projectLead;
  address private _owner;

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
    _offers.push(Offer(payable(msg.sender), msg.value, multiplier, duration, block.timestamp, false, false));
  }

  function acceptOrRejectOffer(uint256 offerId, bool accept) public override {
    require(msg.sender == _projectLead, "Only project lead can accept offer");

    require(!_offers[offerId]._isDecided, "Offer already rejected or accepted.");
    require(block.timestamp <= _offers[offerId]._offerStartTime + _offers[offerId]._offerDuration, "Offer expired");

    if (accept) {
      // offer._offerIsAccepted = true;
      _offers[offerId]._offerIsAccepted = true;
      _offers[offerId]._isDecided = true;

      DecentralisedInvestmentManager dim = DecentralisedInvestmentManager(_owner);
      dim.receiveAcceptedOffer{ value: _offers[offerId]._investmentAmount }(_offers[offerId]._offerInvestor);

      // the transaction is rejected e.g. because the investmentCeiling is reached.
    } else {
      _offers[offerId]._offerIsAccepted = false;
      _offers[offerId]._isDecided = true;
    }
  }

  function pullbackOffer(uint256 offerId) public override {
    require(msg.sender == _offers[offerId]._offerInvestor, "Someone other than the investor tried to retrieve offer.");
    if (_offers[offerId]._isDecided) {
      require(!_offers[offerId]._offerIsAccepted, "The offer has been accepted, so can't pull back.");
    } else {
      require(
        block.timestamp > _offers[offerId]._offerStartTime + _offers[offerId]._offerDuration,
        "The offer duration has not yet expired."
      );
    }

    payable(_offers[offerId]._offerInvestor).transfer(_offers[offerId]._investmentAmount);
  }
}
