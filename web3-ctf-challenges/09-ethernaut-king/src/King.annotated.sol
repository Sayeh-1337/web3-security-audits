// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/King.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — DoS via .transfer to untrusted king
    // - New king is msg.sender with no restriction (EOA or contract).
    // - Before updating king, refunds previous king with .transfer (2300 gas stipend).
    // - If current king is a contract without payable receive/fallback (or that reverts),
    //   EVERY subsequent claim reverts — including owner reclaim attempts that still hit .transfer first.
    // - Note: owner bypasses prize check (`msg.sender == owner`) but still executes transfer(king).
    // - Exploit: deploy helper (no receive) that becomes king by sending >= prize via call{value:}.
    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        // AUDIT [CRITICAL]: External call to untrusted address before state update (also CEI violation).
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
