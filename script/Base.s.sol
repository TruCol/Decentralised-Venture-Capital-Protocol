// SPDX-License-Identifier: MIT
pragma solidity >=0.8.23 <0.9.0;

import { Script } from "forge-std/src/Script.sol";

abstract contract BaseScript is Script {
  /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
  string internal constant _TEST_MNEMONIC = "test test test test test test test test test test test junk";

  /// @dev Needed for the deterministic deployments.
  bytes32 internal constant _ZERO_SALT = bytes32(0);

  /// @dev The address of the transaction broadcaster.
  address internal _broadcaster;

  /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
  string internal _mnemonic;

  /// @dev Initializes the transaction broadcaster like this:
  ///
  /// - If $ETH_FROM is defined, use it.
  /// - Otherwise, derive the broadcaster address from $MNEMONIC.
  /// - If $MNEMONIC is not defined, default to a test mnemonic.
  ///
  /// The use case for $ETH_FROM is to specify the broadcaster key and its address via the command line.
  constructor() {
    address from = vm.envOr({ name: "ETH_FROM", defaultValue: address(0) });
    if (from != address(0)) {
      _broadcaster = from;
    } else {
      _mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: _TEST_MNEMONIC });
      (_broadcaster, ) = deriveRememberKey({ mnemonic: _mnemonic, index: 0 });
    }
  }

  modifier broadcast() {
    vm.startBroadcast(_broadcaster);
    _;
    vm.stopBroadcast();
  }
}
