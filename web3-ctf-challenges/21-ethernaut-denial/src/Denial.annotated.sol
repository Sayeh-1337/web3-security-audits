// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Adapted from OpenZeppelin Ethernaut level 20.
contract Denial {
    address public partner; // AUDIT: anyone can set via setWithdrawPartner — no access control
    address payable public owner;
    uint256 public timeLastWithdrawn;
    mapping(address => uint256) public withdrawPartnerBalances;

    constructor(address payable initialOwner) {
        owner = initialOwner;
    }

    // AUDIT: missing onlyOwner / auth — attacker becomes withdraw partner
    function setWithdrawPartner(address partnerAddress) external {
        partner = partnerAddress;
    }

    function withdraw() external {
        uint256 amountToSend = address(this).balance / 100;
        // AUDIT: call forwards almost all remaining gas; return value ignored
        (bool sent,) = partner.call{value: amountToSend}("");
        sent;
        // AUDIT: if partner burns gas, owner.transfer OOG → whole withdraw reverts under gas cap
        owner.transfer(amountToSend);
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    receive() external payable {}
}
