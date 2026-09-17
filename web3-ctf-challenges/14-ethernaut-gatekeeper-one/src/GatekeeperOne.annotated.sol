// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/GatekeeperOne.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract GatekeeperOne {
    address public entrant;

    // AUDIT [MEDIUM / H-01]: gateOne — requires contract caller (msg.sender != tx.origin).
    // Bypass: call enter() via an intermediate HelperContract so tx.origin stays the EOA player.
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    // AUDIT [HIGH / H-02]: gateTwo — gasleft() % 8191 == 0 at modifier check.
    // Opcode gas costs vary by compiler / call path; brute-force remaining gas offset (0..8190).
    // Exploit: target.call{gas: base + i}(enter(key)) until success.
    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    // AUDIT [CRITICAL / C-01]: gateThree — key constraints are fully recoverable from tx.origin.
    //   (1) uint32(key) == uint16(key)  → bytes [2:4] of the low 4 must be 0x0000
    //   (2) uint32(key) != uint64(key)  → high 4 bytes of key must be non-zero
    //   (3) uint32(key) == uint16(tx.origin) → low 2 bytes = last 2 bytes of tx.origin
    // Closed form: key = bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF)
    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)));
        require(uint32(uint64(_gateKey)) != uint64(_gateKey));
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)));
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
