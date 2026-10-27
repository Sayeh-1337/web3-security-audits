// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

/// @notice Adapted from OpenZeppelin Ethernaut level 21.
contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() external {
        Buyer buyer = Buyer(msg.sender);
        // AUDIT: view callback invoked twice with different storage between calls.
        // First call: gate (>= price && !isSold). Second: sets final price after isSold=true.
        if (buyer.price() >= price && !isSold) {
            isSold = true;
            // AUDIT: attacker returns 0 here by reading isSold
            price = buyer.price();
        }
    }
}
