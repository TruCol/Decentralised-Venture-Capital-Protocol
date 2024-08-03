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
  string private _hitRateFilePath;
  LogParams private _logParams;

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

  /** Exports the current map to the already existing log file. Throws an error
  if the log file does not yet exist.*/
  function overwriteExistingMapLogFile(Map storage map, string memory hitRateFilePath) public {
    // TODO: assert the file already exists, throw error if file does not yet exist.
    string memory serialisedTextString = _testFileLogging.convertHitRatesToString(map.keys, map.values);
    // overwriteFileContent(serialisedTextString, hitRateFilePath);
    _testFileLogging.overwriteFileContent(serialisedTextString, hitRateFilePath);
    // TODO: assert the log filecontent equals the current mapping values.
  }

  /** Reads the log data (parameter name and value) from the file, converts it
into a struct, and then converts that struct into this mapping.
 */
  function readHitRatesFromLogFileAndSetToMap(Map storage map, string memory hitRateFilePath) public {
    bytes memory data = _testFileLogging.readLogData(hitRateFilePath);
    // Unpack sorted HitRate data from file into HitRatesReturnAll object.
    LogParams memory readLogParams = abi.decode(data, (LogParams));

    // Update the hit rate mapping using the HitRatesReturnAll object.
    _updateLogParamMapping({ hitRates: readLogParams });

    // TODO: assert the data in the log file equals the data in this map.
  }

  function _initialiseMapping(Map storage map) public returns (string memory hitRateFilePath) {
    _logParams = new LogParams({
      a: 0,
      b: 0,
      c: 0,
      d: 0,
      e: 0,
      f: 0,
      g: 0,
      h: 0,
      i: 0,
      j: 0,
      k: 0,
      l: 0,
      m: 0,
      n: 0,
      o: 0,
      p: 0,
      q: 0,
      r: 0,
      s: 0,
      t: 0,
      u: 0,
      v: 0,
      w: 0,
      x: 0,
      y: 0,
      z: 0
    });
    _updateLogParamMapping(_logParams);

    // This should just be to get the hitRateFilePath because the data should
    // already exist.
    _hitRateFilePath = _testFileLogging.createLogIfNotExistAndReadLogData(map.getKeys(), map.getValues());
    return _hitRateFilePath;
  }

  // solhint-disable-next-line foundry-test-functions
  function _updateLogParamMapping(Map storage map, LogParams memory logParams) public {
    // string[] memory structKeys = vm.parseJsonKeys(logParams, "$");
    string[] memory structKeys = ["hello","another"];
    for (uint256 i = 0; i < structKeys.length; i++) {
      if (i == 0) {
        map.set(structKeys[i], logParams.a);
      } else if (i == 1) {
        map.set(structKeys[i], logParams.b);
      } else if (i == 2) {
        map.set(structKeys[i], logParams.c);
      } else if (i == 3) {
        map.set(structKeys[i], logParams.d);
      } else if (i == 4) {
        map.set(structKeys[i], logParams.e);
      } else if (i == 5) {
        map.set(structKeys[i], logParams.f);
      } else if (i == 6) {
        map.set(structKeys[i], logParams.g);
      } else if (i == 7) {
        map.set(structKeys[i], logParams.h);
      } else if (i == 8) {
        map.set(structKeys[i], logParams.i);
      } else if (i == 9) {
        map.set(structKeys[i], logParams.j);
      } else if (i == 10) {
        map.set(structKeys[i], logParams.k);
      } else if (i == 11) {
        map.set(structKeys[i], logParams.l);
      } else if (i == 12) {
        map.set(structKeys[i], logParams.m);
      } else if (i == 13) {
        map.set(structKeys[i], logParams.n);
      } else if (i == 14) {
        map.set(structKeys[i], logParams.o);
      } else if (i == 15) {
        map.set(structKeys[i], logParams.p);
      } else if (i == 16) {
        map.set(structKeys[i], logParams.q);
      } else if (i == 17) {
        map.set(structKeys[i], logParams.r);
      } else if (i == 18) {
        map.set(structKeys[i], logParams.s);
      } else if (i == 19) {
        map.set(structKeys[i], logParams.t);
      } else if (i == 20) {
        map.set(structKeys[i], logParams.u);
      } else if (i == 21) {
        map.set(structKeys[i], logParams.v);
      } else if (i == 22) {
        map.set(structKeys[i], logParams.w);
      } else if (i == 23) {
        map.set(structKeys[i], logParams.x);
      } else if (i == 24) {
        map.set(structKeys[i], logParams.y);
      } else if (i == 25) {
        map.set(structKeys[i], logParams.z);
      }
    }
    // map.set("didNotreachInvestmentCeiling", hitRates.didNotreachInvestmentCeiling);
    // map.set("didReachInvestmentCeiling", hitRates.didReachInvestmentCeiling);
  }
}
