// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;
    address public owner;

    constructor(string memory tokenName, address creator, uint256 initialSupply) payable {
        name = tokenName;
        balances[creator] = initialSupply;
        owner = creator;
    }

    function destroy(address payable recipient) external {
        require(msg.sender == owner, "SimpleToken: owner only");
        selfdestruct(recipient);
    }
}

/// @notice Adapted from OpenZeppelin Ethernaut level 17. A generated token has
/// no retained address; learners must derive its CREATE address.
contract Recovery {
    function generateToken(string memory name, uint256 initialSupply) external payable {
        new SimpleToken{value: msg.value}(name, msg.sender, initialSupply);
    }
}
