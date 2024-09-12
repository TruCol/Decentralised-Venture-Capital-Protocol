pragma solidity >=0.8.25 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import "forge-std/src/Vm.sol";
import "test/TestConstants.sol";
error InvalidExportLogMapError(string message, string[] keys, uint256[] values, uint256);

contract TestFileLogging is PRBTest, StdCheats {
  /**
    @dev This is a function stores the log elements used to verify each test case in the fuzz test is reached.
     */
  // solhint-disable-next-line foundry-test-functions
  function convertHitRatesToString(
    // mapping(bytes32 => uint256) loggingMap
    string[] memory keys,
    uint256[] memory values
  ) public returns (string memory serialisedTextString) {
    if (keys.length > _MAX_NR_OF_TEST_LOG_VALUES_PER_LOG_FILE) {
      revert InvalidExportLogMapError(
        "More log keys than supported.",
        keys,
        values,
        _MAX_NR_OF_TEST_LOG_VALUES_PER_LOG_FILE
      );
    }

    string memory obj1 = "ThisValueDissapearsIntoTheVoid";
    if (keys.length > 1) {
      for (uint256 i = 0; i < keys.length - 1; i++) {
        vm.serializeUint(obj1, keys[i], values[i]);
      }
    }

    // The last instance is different because it needs to be stored into a variable.
    if (keys.length > 0) {
      uint256 lastKeyIndex = keys.length - 1;

      serialisedTextString = vm.serializeUint(obj1, keys[lastKeyIndex], values[lastKeyIndex]);
    } else {
      serialisedTextString = vm.serializeUint(obj1, "a", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "b", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "c", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "d", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "e", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "f", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "g", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "h", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "i", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "j", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "k", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "l", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "m", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "n", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "o", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "p", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "q", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "r", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "s", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "t", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "u", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "v", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "w", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "x", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "y", values[0]);
      serialisedTextString = vm.serializeUint(obj1, "z", values[0]);
    }

    return serialisedTextString;
  }

  function readDataFromFile(string memory path) public returns (bytes memory jsonData) {
    string memory fileContent = vm.readFile(path);
    emit Log("fileContent");
    emit Log(fileContent);
    jsonData = vm.parseJson(fileContent);

    string[] memory firstKeys = new string[](jsonData.length);
    emit Log("firstKeys.length");
    emit Log(Strings.toString(firstKeys.length));

    return jsonData;
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

  /**
@dev Ensures the struct with the log data for this test file is exported into a log file if it does not yet exist.
Afterwards, it can load that new file.
 */
  // solhint-disable-next-line foundry-test-functions
  function createLogIfNotExistAndReadLogData(
    string[] memory keys,
    uint256[] memory values
  ) public returns (string memory hitRateFilePath) {
    // initialiseHitRates();
    // Output hit rates to file if they do not exist yet.
    string memory serialisedTextString = convertHitRatesToString(keys, values);
    hitRateFilePath = createLogFileIfItDoesNotExist(_LOG_TIME_CREATOR, serialisedTextString);
    return (hitRateFilePath);
  }

  // solhint-disable-next-line foundry-test-functions
  function readLogData(string memory hitRateFilePath) public returns (bytes memory data) {
    // Read the latest hitRates from file.
    data = readDataFromFile(hitRateFilePath);
    return data;
  }
}
