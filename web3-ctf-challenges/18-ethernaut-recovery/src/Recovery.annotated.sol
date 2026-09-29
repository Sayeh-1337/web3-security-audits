// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Recovery.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;
    address public owner;

    constructor(string memory tokenName, address creator, uint256 initialSupply) payable {
        name = tokenName;
        balances[creator] = initialSupply;
        // AUDIT [INFO]: creator (generateToken caller) is owner and may selfdestruct the contract.
        owner = creator;
    }

    // AUDIT [INFO]: Owner can recover all ETH via selfdestruct; no other withdrawal path.
    function destroy(address payable recipient) external {
        require(msg.sender == owner, "SimpleToken: owner only");
        selfdestruct(recipient);
    }
}

contract Recovery {
    // AUDIT [MEDIUM / M-01]: Token address is not stored or emitted — off-chain / CREATE math required.
    // First child: address = keccak256(RLP([address(this), nonce]))[12:], nonce = 1 for a new contract account.
    function generateToken(string memory name, uint256 initialSupply) external payable {
        new SimpleToken{value: msg.value}(name, msg.sender, initialSupply);
    }
}
