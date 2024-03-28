// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

contract Foo {
  /**
   * @notice This returns the value that it is given.
   * @dev The current dev does not yet know what the permissible range of the
   * uint256 values may be, nor how this function handles a None/void/null
   * input if those exist in Solidity. Nor do I know how it handles with an
   * overflow input value, if that is possible.
   * @param value An integer that is assumed to be stored in a 256 bit memory.
   * @return The value that it receives as input. The developer does not yet
   * know whether Solidity passes uint256 variables by value or by reference.
   */
  function id(uint256 value) external pure returns (uint256) {
    return value;
  }
}
