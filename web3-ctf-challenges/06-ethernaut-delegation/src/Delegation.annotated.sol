// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Delegation.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Delegate {
    // AUDIT [INFO]: Slot 0 — MUST match Delegation.owner layout for delegatecall to be "safe".
    // Here both put `owner` in slot 0, so pwn() writes Delegation's owner when called via delegatecall.
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    // AUDIT [CRITICAL / C-01]: Unrestricted owner takeover when executed via Delegation.delegatecall.
    // - No access control.
    // - msg.sender is preserved under delegatecall → becomes the EOA that called Delegation.
    // - Storage writes hit the CALLER contract (Delegation), not Delegate.
    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    // AUDIT [INFO]: Slot 0 — aligned with Delegate.owner (intentional for this CTF, dangerous in production).
    address public owner;
    // AUDIT [INFO]: Slot 1 — Delegate's second slot would be unused / different if layouts diverge.
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — unrestricted delegatecall of msg.data
    // - Any calldata (e.g. pwn() selector) is forwarded to Delegate's code in THIS storage context.
    // - No allowlist of selectors, no onlyOwner, no msg.value handling.
    // - Exploit: address(delegation).call(abi.encodeWithSignature("pwn()"));
    //   → fallback → delegatecall(pwn) → Delegation.owner = msg.sender (player).
    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        result; // AUDIT [INFO]: Return value ignored — silent failure possible.
    }
}
