// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CivicToken.sol";
import "./CivicVault.sol";
import "./CivicCustody.sol";

/**
 * Proposals snapshot a member's balance and may be settled immediately.
 */
contract CivicCouncil {
    struct Proposal {
        uint256 snapshotId;
        address payable recipient;
        uint256 amount;
        uint256 votes;
        bool executed;
    }

    CivicToken public immutable token;
    CivicVault public immutable vault;
    CivicCustody public immutable custody;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    constructor(CivicToken tokenAddress, CivicVault vaultAddress, CivicCustody custodyAddress) {
        token = tokenAddress;
        vault = vaultAddress;
        custody = custodyAddress;
    }

    function propose(address payable recipient, uint256 amount) external returns (uint256 proposalId) {
        require(token.balanceOf(msg.sender) > 0, "no voting power");
        proposalId = ++proposalCount;
        uint256 snapshotId = token.snapshot();
        proposals[proposalId] = Proposal({
            snapshotId: snapshotId,
            recipient: recipient,
            amount: amount,
            votes: token.balanceOfAt(msg.sender, snapshotId),
            executed: false
        });
    }

    function execute(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "already executed");
        require(proposal.recipient != address(0), "unknown proposal");
        require(proposal.votes > token.totalSupplyAt(proposal.snapshotId) / 4, "not enough votes");

        proposal.executed = true;
        vault.sendPayment(proposal.recipient, proposal.amount);
    }
}
