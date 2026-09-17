// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Adapted from OpenZeppelin Ethernaut level 14. Original authorship and
/// source attribution are recorded in the challenge manifest.
contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin, "GatekeeperTwo: gate one");
        _;
    }

    modifier gateTwo() {
        uint256 size;
        assembly {
            size := extcodesize(caller())
        }
        require(size == 0, "GatekeeperTwo: gate two");
        _;
    }

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
