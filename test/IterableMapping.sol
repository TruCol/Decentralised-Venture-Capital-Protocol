pragma solidity >=0.8.25 <0.9.0;
/**
  The logging flow is described with:
    1. Initialise the mapping at all 0 values, and export those to file and set them in the struct.
    initialiseMapping(_map)
  Loop:
    2. The values from the log file are read from file and overwrite those in the mapping.
    readHitRatesFromLogFileAndSetToMap()
    3. The code is ran, the mapping values are updated.
    4. The mapping values are logged to file.

  The mapping key value pairs exist in this map unstorted. Then they are
  written to a file in a sorted fashion. They are sorted automatically.
  Then they are read from file in alphabetical order. Since they are read in
  alphabetical order (automatically), they can stored into the alphabetical
  keys of the map using a switch case and enumeration (counts as indices).

  TODO: verify the non-alphabetical keys of a mapping are exported to an
  alphabetical order.
  TODO: verify the non-alphabetical keys of a file are exported and read into
  alphabetical order.
  */

import { console2 } from "forge-std/src/console2.sol";
import "test/TestConstants.sol";
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

  /** Removes the key-value pair that belongings to the incoming key, from the
  map.
   */
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
}
