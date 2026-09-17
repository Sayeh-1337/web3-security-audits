// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Vault.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Vault {
    // AUDIT [INFO]: Slot 0 — bool uses 1 byte; next var is bytes32 so no packing → locked alone in slot 0.
    bool public locked;

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — "private" is not secret on-chain
    // - `private` only hides the auto-getter from other contracts. Storage is fully public.
    // - Slot 1 holds the entire bytes32 password.
    // - Anyone can read via eth_getStorageAt / cast storage / vm.load / Etherscan creation tx calldata.
    // - Exploit: password = vm.load(vault, bytes32(uint256(1))); vault.unlock(password);
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    // AUDIT [OK]: Logic is fine — comparing secrets that were already public is the problem.
    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
