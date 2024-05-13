// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

contract ExposedDecentralisedInvestmentManager is DecentralisedInvestmentManager {
  // solhint-disable-next-line comprehensive-interface
  constructor(
    Tier[] memory tiers,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLeadAddress,
    uint32 raisePeriod,
    uint256 investmentTarget
  )
    public
    DecentralisedInvestmentManager(
      tiers,
      projectLeadFracNumerator,
      projectLeadFracDenominator,
      projectLeadAddress,
      raisePeriod,
      investmentTarget
    )
  {
    // Additional logic for ExposedDecentralisedInvestmentManager if needed
  }

  function allocateInvestment(uint256 investmentAmount, address investorWallet) public {
    return _allocateInvestment(investmentAmount, investorWallet);
  }

  function performSaasRevenueAllocation(uint256 amount, address receivingWallet) public {
    return _performSaasRevenueAllocation(amount, receivingWallet);
  }
}
