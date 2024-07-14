pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import { IterableMapping } from "./IterableMapping.sol";

contract TestFileLogging is PRBTest, StdCheats {
  using IterableMapping for IterableMapping.Map;
  struct Map {
    address[] keys;
    mapping(address => uint256) values;
    mapping(address => uint256) indexOf;
    mapping(address => bool) inserted;
  }

  //  /**
  //  @dev This is a function stores the log elements used to verify each test case in the fuzz test is reached.
  //   */
  //  // solhint-disable-next-line foundry-test-functions
  //  function convertHitRatesToString(
  //    // mapping(bytes32 => uint256) loggingMap
  //    Map memory  map
  //  ) public returns (string memory serialisedTextString) {
  //    string memory obj1 = "ThisValueDissapearsIntoTheVoid";
  //    address key;
  //     for (uint256 i = 0; i < map.size() -1; i++) {
  //        key = map.getKeyAtIndex(i);
  //        vm.serializeUint(obj1, key, map.get(key));
  //        }
  //
  //    // The last instance is different because it needs to be stored into a variable.
  //    key = map.getKeyAtIndex(map.size()-1);
  //    serialisedTextString = vm.serializeUint(
  //      obj1,
  //      key,
  //      map.get(key)
  //    );
  //    return serialisedTextString;
  //  }

  function readDataFromFile(string memory path) public view returns (bytes memory data) {
    string memory fileContent = vm.readFile(path);
    data = vm.parseJson(fileContent);
    return data;
  }

  function createFileIfNotExists(
    string memory serialisedTextString,
    string memory filePath
  ) public returns (uint256 lastModified) {
    if (!vm.isFile(filePath)) {
      overwriteFileContent(serialisedTextString, filePath);
    }
    if (!vm.isFile(filePath)) {
      revert("File does not exist.");
    }
    return vm.fsMetadata(filePath).modified;
  }

  function overwriteFileContent(string memory serialisedTextString, string memory filePath) public {
    vm.writeJson(serialisedTextString, filePath);
    if (!vm.isFile(filePath)) {
      revert("File does not exist.");
    }
  }

  function createLogFileIfItDoesNotExist(
    string memory tempFileName,
    string memory serialisedTextString
  ) public returns (string memory hitRateFilePath) {
    // Specify the logging directory and filepath.
    uint256 timeStamp = createFileIfNotExists(serialisedTextString, tempFileName);
    string memory logDir = string(abi.encodePacked("test_logging/", Strings.toString(timeStamp)));
    hitRateFilePath = string(abi.encodePacked(logDir, "/DebugTest.txt"));

    // If the log file does not yet exist, create it.
    if (!vm.isFile(hitRateFilePath)) {
      // Create logging structure
      vm.createDir(logDir, true);
      overwriteFileContent(serialisedTextString, hitRateFilePath);

      // Assort logging file exists.
      if (!vm.isFile(hitRateFilePath)) {
        revert("LogFile not created.");
      }
    }
    return hitRateFilePath;
  }
}
