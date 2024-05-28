// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { Tier } from "../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

interface IEdim {
  function allocateInvestment(uint256 investmentAmount, address payable investorWallet) external;

  function performSaasRevenueAllocation(uint256 amount, address receivingWallet) external;
}

contract ExposedDecentralisedInvestmentManager is DecentralisedInvestmentManager, IEdim {
  // solhint-disable-next-line comprehensive-interface
  constructor(
    Tier[] memory tiers,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLead,
    uint32 raisePeriod,
    uint256 investmentTarget
  )
    DecentralisedInvestmentManager(
      tiers,
      projectLeadFracNumerator,
      projectLeadFracDenominator,
      projectLead,
      raisePeriod,
      investmentTarget
    )
  {
    // Additional logic for ExposedDecentralisedInvestmentManager if needed
  }

  function allocateInvestment(uint256 investmentAmount, address payable investorWallet) public override {
    return _allocateInvestment(investmentAmount, investorWallet);
  }

  function performSaasRevenueAllocation(uint256 amount, address receivingWallet) public override {
    return _performSaasRevenueAllocation(amount, receivingWallet);
  }
}
