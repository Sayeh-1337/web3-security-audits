// SPDX-License-Identifier: MIT
// SCH original (Solidity 0.5) — reference only. Local tests use AlienCodex.sol (^0.8 + assembly).
pragma solidity ^0.5.0;

contract Ownable {
    address public owner;

    constructor() public {
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

/// @notice Adapted from OpenZeppelin Ethernaut level 19. Solidity 0.5 is
/// intentional: decrementing an empty dynamic array has no checked arithmetic.
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
        codex.length--;
    }

    function revise(uint256 index, bytes32 content) public contacted {
        codex[index] = content;
    }
}
