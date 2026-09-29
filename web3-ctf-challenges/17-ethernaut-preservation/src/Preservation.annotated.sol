// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Preservation.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract LibraryContract {
    // AUDIT [CRITICAL / C-01]: Library layout is NOT aligned with Preservation.
    // Library slot 0 = storedTime
    // Preservation slot 0 = timeZone1Library
    // delegatecall writes library's slot 0 into the caller's slot 0 → overwrites timeZone1Library.
    uint256 public storedTime;

    function setTime(uint256 time) external {
        storedTime = time;
    }
}

contract Preservation {
    // AUDIT [INFO]: Storage layout
    //   slot 0: timeZone1Library
    //   slot 1: timeZone2Library
    //   slot 2: owner
    //   slot 3: storedTime
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 public storedTime;

    constructor(address libraryOne, address libraryTwo) {
        timeZone1Library = libraryOne;
        timeZone2Library = libraryTwo;
        owner = msg.sender;
    }

    // AUDIT [CRITICAL / C-01]: Unchecked delegatecall + mismatched storage layout.
    // 1) setFirstTime(uint256(uint160(malicious))) overwrites timeZone1Library (slot 0).
    // 2) setFirstTime(uint256(uint160(player))) runs malicious setTime which writes owner (slot 2).
    function setFirstTime(uint256 timeStamp) external {
        timeZone1Library.delegatecall(abi.encodeWithSignature("setTime(uint256)", timeStamp));
    }

    function setSecondTime(uint256 timeStamp) external {
        timeZone2Library.delegatecall(abi.encodeWithSignature("setTime(uint256)", timeStamp));
    }
}
