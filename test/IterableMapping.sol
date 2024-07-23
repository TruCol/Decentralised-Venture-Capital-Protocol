pragma solidity >=0.8.25 <0.9.0;
import "test/TestConstants.sol";
import { console2 } from "forge-std/src/console2.sol";
import { TestFileLogging } from "./TestFileLogging.sol";
/**
Stores the counters used to track how often the different branches of the tests are covered.*/
struct LogParams {
  uint256 a;
  uint256 b;
  uint256 c;
  uint256 d;
  uint256 e;
  uint256 f;
  uint256 g;
  uint256 h;
  uint256 i;
  uint256 j;
  uint256 k;
  uint256 l;
  uint256 m;
  uint256 n;
  uint256 o;
  uint256 p;
  uint256 q;
  uint256 r;
  uint256 s;
  uint256 t;
  uint256 u;
  uint256 v;
  uint256 w;
  uint256 x;
  uint256 y;
  uint256 z;
}

library IterableMapping {
  // Iterable mapping from string[] to uint;
  struct Map {
    string[] keys;
    mapping(string => uint256) values;
    mapping(string => uint256) indexOf;
    mapping(string => bool) inserted;
  }
  TestFileLogging private _testFileLogging;

  function get(Map storage map, string memory key) public view returns (uint256) {
    return map.values[key];
  }

  function getKeys(Map storage map) public view returns (string[] memory) {
    return map.keys;
  }

  function getValues(Map storage map) public view returns (uint256[] memory) {
    uint256[] memory listOfValues = new uint256[](_MAX_NR_OF_TEST_LOG_VALUES_PER_LOG_FILE);

    if (map.keys.length > 1) {
      for (uint256 i = 0; i < map.keys.length; i++) {
        listOfValues[i] = map.values[map.keys[i]];
      }
    }
    return listOfValues;
  }

  function getKeyAtIndex(Map storage map, uint256 index) public view returns (string memory) {
    return map.keys[index];
  }

  function size(Map storage map) public view returns (uint256) {
    return map.keys.length;
  }

  function set(Map storage map, string memory key, uint256 val) public {
    if (map.inserted[key]) {
      map.values[key] = val;
    } else {
      map.inserted[key] = true;
      map.values[key] = val;
      map.indexOf[key] = map.keys.length;
      map.keys.push(key);
    }
  }

  function remove(Map storage map, string memory key) public {
    if (!map.inserted[key]) {
      return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint256 index = map.indexOf[key];
    string memory lastKey = map.keys[map.keys.length - 1];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
  }

  /** Converts the data that is read from the json into this mapping.
  Use an export struct.

  The come in unsorted. Then they are written to a file in a sorted fashion.
  Then they are read from file, and they can be mapped to the struct a-z.
  Then the struct values can be re-assigned to the sorted keys. So the mapping keys
  need to be sorted first, and then you can enumerate over the keys with a counter i
  that can be re-used to get the value out of the struct. This value can then be
  used to overwrite the existing value.

  - Sort an array of keys.
  - Enumerate over the keys with a counter.
  - Read the hitrate file from the library.
  */
  function dataToMapping(Map storage map) public view returns (string[] memory) {
    (string memory hitRateFilePath, bytes memory data) = _testFileLogging.createLogIfNotExistAndReadLogData(
      map.getKeys(),
      map.getValues()
    );
    // Unpack HitRate data from file into HitRatesReturnAll object.
    LogParams memory updatedHitrates = abi.decode(data, (LogParams));

    // Update the hit rate mapping using the HitRatesReturnAll object.
    _updateHitRates({ hitRates: updatedHitrates });

    return map.keys;
  }

  // solhint-disable-next-line foundry-test-functions
  function _updateHitRates(LogParams memory hitRates) internal {
    map.set("didNotreachInvestmentCeiling", hitRates.didNotreachInvestmentCeiling);
    map.set("didReachInvestmentCeiling", hitRates.didReachInvestmentCeiling);
    map.set("validInitialisations", hitRates.validInitialisations);
    map.set("validInvestments", hitRates.validInvestments);
    map.set("invalidInitialisations", hitRates.invalidInitialisations);
    map.set("invalidInvestments", hitRates.invalidInvestments);
    map.set("investmentOverflow", hitRates.investmentOverflow);
  }
}
