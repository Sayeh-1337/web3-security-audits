// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Telephone.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Telephone {
    // AUDIT [INFO]: Single privileged role. No other functions — owning the contract is the whole game.
    address public owner;

    constructor() {
        // AUDIT [OK]: Deployer becomes owner. SCH factory is owner at start; player must steal it.
        owner = msg.sender;
    }

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — authentication via tx.origin
    // - Intended (wrong) idea: only EOAs can change owner (tx.origin == msg.sender for direct calls).
    // - Actual rule: owner changes ONLY when tx.origin != msg.sender, i.e. when a contract is in the middle.
    // - Attack: EOA → Helper → changeOwner(player). Here tx.origin = EOA, msg.sender = Helper → check passes.
    // - Also teaches the phishing pattern: never authorize with tx.origin (victim EOA → evil contract → victim wallet).
    // - Exploit: deploy helper that calls telephoneInstance.changeOwner(PLAYER_ADDRESS); invoke helper from player.
    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
