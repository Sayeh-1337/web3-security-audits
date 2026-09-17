// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

// AUDIT: Annotated copy for review only. Deploy / test against src/Fallout.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Fallout {
    using SafeMath for uint256;

    // AUDIT [INFO]: Private mapping — no auto-generated getter. allocatorBalance is missing in the SCH cut.
    mapping(address => uint256) allocations;

    // AUDIT [INFO]: Single privileged role. collectAllocations() drains all ETH to owner.
    // AUDIT [INFO]: Starts as address(0) because there is no real constructor (see Fal1out).
    address payable public owner;

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY
    // - Comment says "constructor" but this is a normal public function.
    // - Name is Fal1out (digit 1), not Fallout (letter l). Even if spelled correctly,
    //   Solidity 0.5+ constructors MUST use the `constructor` keyword — a function named
    //   after the contract is NOT a constructor on pragma ^0.6.0.
    // - Never runs at deploy → owner remains 0x0.
    // - Anyone can call it and become owner. Payable, but msg.value is optional.
    // - Exploit: falloutInstance.Fal1out();
    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    // AUDIT [OK]: Standard modifier — correctly used on collectAllocations() only.
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function allocate() public payable {
        // AUDIT [OK]: Records ETH deposits. Not involved in the ownership bug.
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    function collectAllocations() public onlyOwner {
        // AUDIT [CRITICAL downstream]: Drains entire balance once C-01 is exploited.
        // AUDIT [MEDIUM / M-01]: .transfer() only forwards 2300 gas; may fail for smart-wallet owners.
        // AUDIT [INFO / I-02]: No Withdrawn event.
        msg.sender.transfer(address(this).balance);
    }
}
