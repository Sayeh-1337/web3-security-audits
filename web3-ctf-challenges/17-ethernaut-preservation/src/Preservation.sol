// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LibraryContract {
    uint256 public storedTime;

    function setTime(uint256 time) external {
        storedTime = time;
    }
}

/// @notice Adapted from OpenZeppelin Ethernaut level 16.
contract Preservation {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 public storedTime;

    constructor(address libraryOne, address libraryTwo) {
        timeZone1Library = libraryOne;
        timeZone2Library = libraryTwo;
        owner = msg.sender;
    }

    function setFirstTime(uint256 timeStamp) external {
        timeZone1Library.delegatecall(abi.encodeWithSignature("setTime(uint256)", timeStamp));
    }

    function setSecondTime(uint256 timeStamp) external {
        timeZone2Library.delegatecall(abi.encodeWithSignature("setTime(uint256)", timeStamp));
    }
}
