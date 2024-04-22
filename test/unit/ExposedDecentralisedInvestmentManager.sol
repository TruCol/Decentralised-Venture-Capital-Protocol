// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Tier } from "../../src/Tier.sol";

import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";

// interface Interface {
// function allocateInvestment() external;
// }

contract ExposedDecentralisedInvestmentManager is DecentralisedInvestmentManager {
  constructor(
    Tier[] memory tiers,
    uint256 projectLeadFracNumerator,
    uint256 projectLeadFracDenominator,
    address projectLeadAddress
  )
    public
    DecentralisedInvestmentManager(tiers, projectLeadFracNumerator, projectLeadFracDenominator, projectLeadAddress)
  {
    // Additional logic for ExposedDecentralisedInvestmentManager if needed
  }

  function allocateInvestment(uint256 investmentAmount, address investorWallet) public {
    return _allocateInvestment(investmentAmount, investorWallet);
  }

  function distributeSaasPaymentFractionToInvestors(
    uint256 saasRevenueForInvestors,
    uint256 cumRemainingInvestorReturn
  ) public {
    return _distributeSaasPaymentFractionToInvestors(saasRevenueForInvestors, cumRemainingInvestorReturn);
  }

  function performSaasRevenueAllocation(uint256 amount, address receivingWallet) public {
    return _performSaasRevenueAllocation(amount, receivingWallet);
  }
}
