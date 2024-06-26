pragma solidity >=0.8.25 <0.9.0;

import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract TestFileLogging is PRBTest, StdCheats {
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
