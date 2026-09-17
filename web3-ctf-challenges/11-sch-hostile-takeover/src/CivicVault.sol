// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CivicVault {
    address public immutable owner;
    address public governance;

    constructor() {
        owner = msg.sender;
    }

    function setGovernance(address governanceAddress) external {
        require(msg.sender == owner, "only owner");
        require(governance == address(0), "governance set");
        governance = governanceAddress;
    }

    function sendPayment(address payable receiver, uint256 amount) external {
        require(msg.sender == governance, "only governance");
        require(address(this).balance >= amount, "insufficient treasury");
        (bool sent,) = receiver.call{value: amount}("");
        require(sent, "payment failed");
    }

    receive() external payable {}
}
