// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Privacy.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Privacy {
    // AUDIT [INFO]: Slot 0 — bool takes full slot (next var is uint256).
    bool public locked = true;

    // AUDIT [INFO]: Slot 1 — full word.
    uint256 public ID = block.timestamp;

    // AUDIT [INFO]: Slot 2 — packed: flattening (1) + denomination (1) + awkwardness (2).
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — "private" data is still on-chain
    // Storage layout for fixed array bytes32[3]:
    //   data[0] -> slot 3
    //   data[1] -> slot 4
    //   data[2] -> slot 5   <- unlock key source
    // unlock requires bytes16(data[2]) — high 16 bytes of slot 5.
    // Exploit: key = bytes16(vm.load(privacy, bytes32(uint256(5)))); privacy.unlock(key);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }
}
