// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Force.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Force {
    /*
        The contract has no payable function.
        The goal is still to make its balance greater than zero.

        AUDIT [CRITICAL / C-01]: Design assumption / invariant failure
        - No receive(), no payable fallback, no payable functions → normal transfers revert.
        - ETH can STILL be forced in via:
          1) selfdestruct(payable(this)) from another contract
          2) coinbase / block reward (miner) — out of scope for CTF
        - Lesson: NEVER rely on address(this).balance == 0 (or exact balance accounting
          that assumes only payable paths can change it).
        - Exploit: deploy helper with 1 wei, selfdestruct(forceInstance).
    */
}
