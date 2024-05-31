// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";
error InvalidProjectLeadAddress(string message);

error TierMultipleMismatch(string message, uint256 tierCount, uint256 multipleCount);

error UnauthorizedWithdrawal(string message, address sender);

error InsufficientContractBalance(string message, uint256 requestedAmount, uint256 availableBalance);

interface IInitialiseDim {
  function getDim() external returns (DecentralisedInvestmentManager dim);

  function getExposedDim() external returns (ExposedDecentralisedInvestmentManager exposedDim);

  function withdraw(uint256 amount) external;
}

contract InitialiseDim is IInitialiseDim {
  Tier[] private _tiers;
  DecentralisedInvestmentManager private immutable _DIM;
  ExposedDecentralisedInvestmentManager private immutable _EXPOSED_DIM;
  address private immutable _PROJECT_LEAD;

  // solhint-disable-next-line comprehensive-interface
  constructor(
    uint256[] memory ceilings,
    uint8[] memory multiples,
    uint256 investmentTarget,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLead,
    uint32 raisePeriod
  ) {
    // Initialise the private attributes.
    if (projectLead == address(0)) {
      revert InvalidProjectLeadAddress("Project lead address cannot be zero.");
    }

    _PROJECT_LEAD = projectLead;

    // Specify the investment tiers in ether.
    uint256 nrOfTiers = ceilings.length;
    uint256 nrOfMultiples = multiples.length;
    if (nrOfTiers != nrOfMultiples) {
      revert TierMultipleMismatch("Number of tiers and multiples must be equal.", nrOfTiers, nrOfMultiples);
    }

    for (uint256 i = 0; i < nrOfTiers; ++i) {
      if (i == 0) {
        _tiers.push(new Tier(0, ceilings[i], multiples[i]));
      } else {
        _tiers.push(new Tier(ceilings[i - 1], ceilings[i], multiples[i]));
      }
    }

    _DIM = new DecentralisedInvestmentManager({
      tiers: _tiers,
      projectLeadFracNumerator: projectLeadFracNumerator,
      projectLeadFracDenominator: projectLeadFracDenominator,
      projectLead: projectLead,
      raisePeriod: raisePeriod,
      investmentTarget: investmentTarget
    });

    // Initialise exposed dim.
    _EXPOSED_DIM = new ExposedDecentralisedInvestmentManager({
      tiers: _tiers,
      projectLeadFracNumerator: projectLeadFracNumerator,
      projectLeadFracDenominator: projectLeadFracDenominator,
      projectLead: projectLead,
      raisePeriod: raisePeriod,
      investmentTarget: investmentTarget
    });
  }

  /**
  @notice This function exists only to resolve the Slither warning: "Contract locking ether found". This contract is
  not actually deployed, it is only used by tests.

  @param amount The amount of DAI the project lead wants to withdraw.


  */
  function withdraw(uint256 amount) public override {
    if (msg.sender != _PROJECT_LEAD) {
      revert UnauthorizedWithdrawal("Only project lead can withdraw funds.", msg.sender);
    }
    if (address(this).balance < amount) {
      revert InsufficientContractBalance(
        "Insufficient contract balance for withdrawal.",
        amount,
        address(this).balance
      );
    }
    payable(msg.sender).transfer(amount);
  }

  function getDim() public view override returns (DecentralisedInvestmentManager dim) {
    dim = _DIM;
    return dim;
  }

  function getExposedDim() public view override returns (ExposedDecentralisedInvestmentManager exposedDim) {
    exposedDim = _EXPOSED_DIM;
    return exposedDim;
  }
}
