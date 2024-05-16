// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";

interface Interface {
  function getDim() external returns (DecentralisedInvestmentManager dim);

  function getExposedDim() external returns (ExposedDecentralisedInvestmentManager exposedDim);

  function withdraw(uint256 amount) external;
}

contract InitialiseDim is Interface {
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  ExposedDecentralisedInvestmentManager private _exposedDim;
  address private _projectLead;

  // solhint-disable-next-line comprehensive-interface
  constructor(
    uint256[] memory ceilings,
    uint8[] memory multiples,
    uint32 raisePeriod,
    uint256 investmentTarget,
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator
  ) public {
    // Initialise the private attributes.
    _projectLead = projectLead;

    // Specify the investment tiers in ether.
    uint256 nrOfTiers = ceilings.length;
    uint256 nrOfMultiples = multiples.length;
    require(nrOfTiers == nrOfMultiples, "The nr of tiers is not equal to the nr of multiples.");
    for (uint256 i = 0; i < nrOfTiers; ++i) {
      if (i == 0) {
        _tiers.push(new Tier(0, ceilings[i], multiples[i]));
      } else {
        _tiers.push(new Tier(ceilings[i - 1], ceilings[i], multiples[i]));
      }
    }

    _dim = new DecentralisedInvestmentManager({
      tiers: _tiers,
      projectLeadFracNumerator: projectLeadFracNumerator,
      projectLeadFracDenominator: projectLeadFracDenominator,
      projectLead: projectLead,
      raisePeriod: raisePeriod,
      investmentTarget: investmentTarget
    });

    // Initialise exposed dim.
    _exposedDim = new ExposedDecentralisedInvestmentManager({
      tiers: _tiers,
      projectLeadFracNumerator: projectLeadFracNumerator,
      projectLeadFracDenominator: projectLeadFracDenominator,
      projectLead: projectLead,
      raisePeriod: raisePeriod,
      investmentTarget: investmentTarget
    });
  }

  function getDim() public override returns (DecentralisedInvestmentManager dim) {
    dim = _dim;
    return dim;
  }

  function getExposedDim() public override returns (ExposedDecentralisedInvestmentManager exposedDim) {
    exposedDim = _exposedDim;
    return exposedDim;
  }

  /**
  @notice This function exists only to resolve the Slither warning: "Contract locking ether found". This contract is
  not actually deployed, it is only used by tests.

  @param amount The amount of DAI the project lead wants to withdraw.


  */
  function withdraw(uint256 amount) public override {
    require(msg.sender == _projectLead, "Withdraw attempted by someone other than project lead.");
    // Check if contract has sufficient balance
    require(address(this).balance >= amount, "Insufficient contract balance");

    // Transfer funds to user using call{value: } (safer approach).
    (bool success, ) = payable(msg.sender).call{ value: amount }("");
    require(success, "Investment withdraw by project lead failed");
  }
}
