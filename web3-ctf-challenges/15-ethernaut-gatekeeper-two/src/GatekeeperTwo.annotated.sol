// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/GatekeeperTwo.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract GatekeeperTwo {
    address public entrant;

    // AUDIT [HIGH / H-01]: gateOne — requires contract caller (msg.sender != tx.origin).
    // Bypass: call enter() from another contract so tx.origin stays the EOA player.
    modifier gateOne() {
        require(msg.sender != tx.origin, "GatekeeperTwo: gate one");
        _;
    }

    // AUDIT [CRITICAL / C-01]: gateTwo — extcodesize(caller()) == 0.
    // During construction, runtime code is not yet stored, so extcodesize is 0.
    // Bypass: call enter() from HelperContract's constructor.
    modifier gateTwo() {
        uint256 size;
        assembly {
            size := extcodesize(caller())
        }
        require(size == 0, "GatekeeperTwo: gate two");
        _;
    }

    // AUDIT [CRITICAL / C-02]: gateThree — key is deterministic from msg.sender.
    // Require: uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(key) == type(uint64).max
    // Closed form: key = bytes8(~uint64(bytes8(keccak256(abi.encodePacked(address(this))))))
    // (in the helper constructor, address(this) == msg.sender seen by enter).
    modifier gateThree(bytes8 gateKey) {
        require(
            uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(gateKey) == type(uint64).max,
            "GatekeeperTwo: gate three"
        );
        _;
    }

    function enter(bytes8 gateKey) public gateOne gateTwo gateThree(gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
