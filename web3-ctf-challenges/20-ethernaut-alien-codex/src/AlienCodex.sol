// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Local Foundry port of SCH / Ethernaut AlienCodex (Solidity 0.5).
 * SCH original uses `codex.length--` which underflows in 0.5; 0.8 removed
 * writable `.length`, so `retract` uses assembly to preserve the same bug.
 */
contract Ownable {
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
    bool public contact;
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

    function retract() public contacted {
        // Simulate Solidity 0.5 `codex.length--` underflow.
        assembly {
            sstore(codex.slot, sub(sload(codex.slot), 1))
        }
    }

    function revise(uint256 index, bytes32 content) public contacted {
        codex[index] = content;
    }
}
