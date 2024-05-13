// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";
import { console2 } from "forge-std/src/console2.sol";

interface Interface {
  function getDim() external returns (DecentralisedInvestmentManager dim);

  function getExposedDim() external returns (ExposedDecentralisedInvestmentManager exposedDim);
}

contract InitialiseDim is Interface {
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  ExposedDecentralisedInvestmentManager private _exposedDim;

  // solhint-disable-next-line comprehensive-interface
  constructor(
    uint256[] memory ceilings,
    uint8[] memory multiples,
    uint32 raisePeriod,
    uint256 investmentTarget,
    address projectLeadAddress,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator
  ) {
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

    _dim = new DecentralisedInvestmentManager(
      _tiers,
      projectLeadFracNumerator,
      projectLeadFracDenominator,
      projectLeadAddress,
      raisePeriod,
      investmentTarget
    );

    // Initialise exposed dim.
    _exposedDim = new ExposedDecentralisedInvestmentManager(
      _tiers,
      projectLeadFracNumerator,
      projectLeadFracDenominator,
      projectLeadAddress,
      raisePeriod,
      investmentTarget
    );
  }

  function getDim() public override returns (DecentralisedInvestmentManager dim) {
    dim = _dim;
    return dim;
  }

  function getExposedDim() public override returns (ExposedDecentralisedInvestmentManager exposedDim) {
    exposedDim = _exposedDim;
    return exposedDim;
  }
}
