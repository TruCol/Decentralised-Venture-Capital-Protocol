pragma solidity >=0.8.25 <0.9.0;
import "test/TestConstants.sol";
import { console2 } from "forge-std/src/console2.sol";

/**
Stores the counters used to track how often the different branches of the tests are covered.*/
struct HitRatesReturnAll {
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
  Use an export struct.*/
  function dataToMapping(Map storage map) public view returns (string[] memory) {
    return map.keys;
  }
}
