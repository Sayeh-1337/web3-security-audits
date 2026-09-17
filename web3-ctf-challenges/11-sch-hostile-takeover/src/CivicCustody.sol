// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CivicToken.sol";

interface ICustodyRecipient {
    function receiveCustody(uint256 amount) external;
}

contract CivicCustody {
    CivicToken public immutable token;

    constructor(CivicToken tokenAddress) {
        token = tokenAddress;
    }

    function checkout(uint256 amount) external {
        require(msg.sender.code.length > 0, "recipient must be contract");
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= amount, "insufficient custody");

        token.transfer(msg.sender, amount);
        ICustodyRecipient(msg.sender).receiveCustody(amount);

        require(token.balanceOf(address(this)) >= balanceBefore, "custody not restored");
    }
}
