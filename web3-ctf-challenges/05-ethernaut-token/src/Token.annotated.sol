// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Token.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Token {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public {
        // AUDIT [OK]: Mints full supply to deployer (factory). Player later receives 20.
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — unchecked arithmetic underflow (Solidity < 0.8)
    // - require(balances[msg.sender] - _value >= 0) is ALWAYS true for uint256 subtraction that wraps,
    //   OR wraps before the comparison: 20 - 21 wraps to type(uint256).max which is >= 0.
    // - No SafeMath. Pragma ^0.6.0 has no built-in overflow checks.
    // - Exploit: with balance 20, transfer(any, 21) → sender balance becomes 2^256 - 1.
    // - Also breaks conservation: recipient gets +21 while sender wraps — totalSupply invariant lies.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    // AUDIT [OK]: View-only.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
