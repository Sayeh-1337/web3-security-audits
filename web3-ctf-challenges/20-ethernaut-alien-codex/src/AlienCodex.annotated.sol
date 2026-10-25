// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. See AUDIT-NOTES.md and WRITEUP.md.

contract Ownable {
    // AUDIT [INFO]: slot 0 — owner (20 bytes). Packed with `contact` in AlienCodex.
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract AlienCodex is Ownable {
    // AUDIT [INFO]: slot 0 (packed with owner) — must be true before mutate.
    bool public contact;
    // AUDIT [CRITICAL / C-01]: slot 1 = length; data at keccak256(1).
    // After length underflow to 2^256-1, revise() can write ANY storage slot.
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 content) public contacted {
        codex.push(content);
    }

    // AUDIT [CRITICAL / C-01]: Underflow length → map entire storage into codex[].
    function retract() public contacted {
        assembly {
            sstore(codex.slot, sub(sload(codex.slot), 1))
        }
    }

    // AUDIT [CRITICAL / C-01]: Write owner (slot 0) via index = -keccak256(1).
    function revise(uint256 index, bytes32 content) public contacted {
        codex[index] = content;
    }
}
