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
        // price() consulted twice — buyer can change answer after isSold flips.
        if (buyer.price() >= price && !isSold) {
            isSold = true;
            price = buyer.price();
        }
    }
}
