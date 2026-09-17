// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Elevator.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

interface Building {
    // AUDIT [INFO]: NOT view — state-changing callbacks are allowed. Attackers can return different
    // values on successive calls for the same input.
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — trusts msg.sender as Building
    // - goTo casts msg.sender to Building and calls isLastFloor TWICE.
    // - First call must return false to enter the branch; second sets top.
    // - A malicious Building returns false then true → top = true.
    // - Interface is not view, so lying via storage toggle is trivial.
    // - Exploit: HelperContract.isLastFloor flips a bool; helper.goTo(elevator).
    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);
        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
