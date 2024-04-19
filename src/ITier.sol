// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.

import { Tier } from "../src/Tier.sol";

interface ITier {
  function minVal() external view returns (uint256);

  function maxVal() external view returns (uint256);

  function multiple() external view returns (uint256);
}
