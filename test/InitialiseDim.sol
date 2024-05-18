// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";

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
    uint32 raisePeriod,
    uint256 investmentTarget,
    address projectLead,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator
  ) public {
    // Initialise the private attributes.
    require(projectLead != address(0), "projectLead address can't be 0.");
    _PROJECT_LEAD = projectLead;

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
    require(msg.sender == _PROJECT_LEAD, "Withdraw attempted by someone other than project lead.");
    // Check if contract has sufficient balance
    require(address(this).balance >= amount, "Insufficient contract balance");

    // Transfer funds to user using call{value: } (safer approach).
    // (bool success, ) = payable(msg.sender).call{ value: amount }("");
    // require(success, "Investment withdraw by project lead failed");
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
