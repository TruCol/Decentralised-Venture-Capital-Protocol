// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/src/Vm.sol" as vm;
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

interface ITestLogHelper {}

contract TestLogHelper is PRBTest, StdCheats, ITestLogHelper {
  function createFileIfNotExists(
    string memory filePath,
    string memory serialisedTextString
  ) public returns (uint256 lastModified) {
    if (!vm.isFile(filePath)) {
      //   _hitRates = initialiseHitRates();
      //   _initialisedHitRates = true;

      //   overwriteFileContent(filePath, _hitRates);
      vm.writeJson(serialisedTextString, filePath);
    }
    if (!vm.isFile(filePath)) {
      revert("File does not exist.");
    }
    return vm.fsMetadata(filePath).modified;
  }

  function readHitRatesFromFile(string memory path) public returns (bytes memory data) {
    if (!vm.isFile(path)) {
      revert("Reading file does not exist.");
    }
    string memory fileContent = vm.readFile(path);
    data = vm.parseJson(fileContent);
    return data;
  }

  function createLogFile(
    string memory fileName,
    string memory serialisedTextString
  ) public returns (string memory hitRateFilePath, bytes memory data) {
    // TODO: initialise the _hitRate struct, if the file in which it will be stored, does not yet exist.
    string memory tempFilename = "temp.txt";
    uint256 timeStamp = createFileIfNotExists(tempFilename, serialisedTextString);

    string memory logDir = string(abi.encodePacked("test_logging/", Strings.toString(timeStamp)));
    hitRateFilePath = string(abi.encodePacked(logDir, fileName));
    emit Log("hitRateFilePath=");
    emit Log(hitRateFilePath);
    if (!vm.isFile(hitRateFilePath)) {
      // Create logging structure
      vm.createDir(logDir, true);
      // overwriteFileContent(hitRateFilePath, _hitRates);
      vm.writeJson(serialisedTextString, hitRateFilePath);
      // Assort logging file exists.
      if (!vm.isFile(hitRateFilePath)) {
        revert("LogFile not created.");
      }
    }
    data = readHitRatesFromFile(hitRateFilePath);
    return (hitRateFilePath, data);
  }
}
