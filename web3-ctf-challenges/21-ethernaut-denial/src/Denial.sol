// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Adapted from OpenZeppelin Ethernaut level 20. The unbounded call to
/// `partner` intentionally lets a partner prevent the owner withdrawal.
contract Denial {
    address public partner;
    address payable public owner;
    uint256 public timeLastWithdrawn;
    mapping(address => uint256) public withdrawPartnerBalances;

    constructor(address payable initialOwner) {
        owner = initialOwner;
    }

    function setWithdrawPartner(address partnerAddress) external {
        partner = partnerAddress;
    }

    function withdraw() external {
        uint256 amountToSend = address(this).balance / 100;
        // Unbounded gas forward to partner — partner can grief / OOG the rest of withdraw.
        (bool sent,) = partner.call{value: amountToSend}("");
        sent;
        // `transfer` needs ~2300 gas; fails if partner already burned the budget.
        owner.transfer(amountToSend);
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    receive() external payable {}
}
