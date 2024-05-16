// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25; // Specifies the Solidity compiler version.

import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

struct Offer {
  address payable _offerInvestor;
  uint16 _offerMultiplier;
  bool _offerIsAccepted;
  bool _isDecided;
  uint256 _investmentAmount;
  uint256 _offerDuration; // Time in seconds for project lead to decide
  uint256 _offerStartTime;
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
  @notice This contract serves as a framework for facilitating counteroffers within a project.

  @dev This contract facilitates the exchange of counteroffers between an investor and the project lead.

  Key features:

      Tracks counteroffer details, including offer multiplier and duration.
      Maintains the offer start time for tracking validity.
      Stores booleans to indicate offer acceptance and decision status.
      Holds an array of Offer structs to manage historical offers.
      Tracks both project lead and owner addresses.

  @param projectLead The address of the project lead who can make and accept counteroffers.
  **/
  // solhint-disable-next-line comprehensive-interface
  constructor(address projectLead) public {
    _owner = payable(msg.sender);
    _projectLead = projectLead;
  }

  /**
  @notice This function allows the investor to make an offer with an investment amount and ROI multiple different than
  what is proposed in the current investment tier.

  @dev This function creates a new Offer struct and adds it to the internal _offers array. The Offer struct captures
  details about the counteroffer, including:

    The address of the investor making the offer.
    The amount of wei offered by the recipient (stored in amount).
    The ROI multiplier proposed for the initial investment value (stored in multiplier).
    The duration in seconds for the project lead to consider the offer (stored in duration)
    The timestamp of the offer creation (stored in timestamp).
    A boolean flag indicating offer acceptance (initially set to false in accepted)
    A boolean flag indicating whether the project lead has made a decision (initially set to false in decided).

  Requirements:
    The investor must also attach a payment along with the offer (enforced by the payable modifier). (The investor
    can get its money back if the offer is rejected or expired.)

  @param multiplier The multiplier to be applied to the initial project value.
  @param duration The duration in seconds for the project lead to consider the counteroffer.

  **/
  function makeOffer(uint16 multiplier, uint256 duration) external payable override {
    // miners can manipulate time(stamps) seconds, not hours/days.
    // solhint-disable-next-line not-rely-on-time
    _offers.push(
      Offer({
        _offerInvestor: payable(msg.sender),
        _offerMultiplier: multiplier,
        _offerIsAccepted: false,
        _isDecided: false,
        _investmentAmount: msg.value,
        _offerDuration: duration,
        // solhint-disable-next-line not-rely-on-time
        _offerStartTime: block.timestamp
      })
    );
  }

  /**
  @notice This function allows the project lead to accept or reject an offer made by an investor.

  @dev This function enables the project lead to make a decision on an offer stored in the internal _offers array. The
  function performs the following actions:

      Validates that the function caller is the project lead (enforced by the require statement
      with msg.sender == _projectLead).

      Ensures the offer hasn't already been decided upon (enforced by the require statement
      with !_offers[offerId]._isDecided).

      Checks if the offer is still valid by comparing the current timestamp with the offer's start time and duration.

      If the project lead accepts the offer (indicated by accept being true):
          The offer's _offerIsAccepted flag is set to true.
          The offer's _isDecided flag is set to true, signifying a decision has been made.
          The DecentralisedInvestmentManager contract is called using the receiveAcceptedOffer function. This function
          likely handles tasks related to finalizing the investment based on the accepted offer details (investor
          address, investment amount). The value parameter of the function call ensures the appropriate investment
          amount is transferred.

      If the project lead rejects the offer (indicated by accept being false):
          The offer's _offerIsAccepted flag is set to false.
          The offer's _isDecided flag is set to true, signifying a decision has been made.

  Limitations:

      This function assumes the existence of a DecentralisedInvestmentManager contract and its receiveAcceptedOffer
      function. The specific implementation details of that function are not defined here.

  @param offerId The unique identifier of the offer within the _offers array.
  @param accept A boolean indicating the project lead's decision (true for accept, false for reject).
  **/
  function acceptOrRejectOffer(uint256 offerId, bool accept) public override {
    require(msg.sender == _projectLead, "Only project lead can accept offer");

    require(!_offers[offerId]._isDecided, "Offer already rejected or accepted.");
    // miners can manipulate time(stamps) seconds, not hours/days.
    // solhint-disable-next-line not-rely-on-time
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

  /**
  @notice This function allows an investor to withdraw their investment offer.

  @dev This function enables the investor to retract an offer stored in the _offers array, but only under certain
  conditions:

      The function caller must be the investor who made the offer (verified by comparing msg.sender with the
      _offerInvestor address stored in the offer).
      If the project lead has already made a decision (indicated by _isDecided being true):
          The investor can only withdraw the offer if it was not accepted (enforced by the require statement with
          !_offers[offerId]._offerIsAccepted).
      If the project lead hasn't made a decision yet (indicated by _isDecided being false):
          The investor can only withdraw the offer if the offer duration has expired (enforced by the require statement
          with block.timestamp > _offers[offerId]._offerStartTime + _offers[offerId]._offerDuration).

  If the withdrawal conditions are met, the function transfers the investor's original investment amount back to the
  investor's address using the transfer function.

  @param offerId The unique identifier of the offer within the _offers array.

  */
  function pullbackOffer(uint256 offerId) public override {
    require(msg.sender == _offers[offerId]._offerInvestor, "Someone other than the investor tried to retrieve offer.");
    if (_offers[offerId]._isDecided) {
      require(!_offers[offerId]._offerIsAccepted, "The offer has been accepted, so can't pull back.");
    } else {
      require(
        // miners can manipulate time(stamps) seconds, not hours/days.
        // solhint-disable-next-line not-rely-on-time
        block.timestamp > _offers[offerId]._offerStartTime + _offers[offerId]._offerDuration,
        "The offer duration has not yet expired."
      );
    }

    payable(_offers[offerId]._offerInvestor).transfer(_offers[offerId]._investmentAmount);
  }
}
