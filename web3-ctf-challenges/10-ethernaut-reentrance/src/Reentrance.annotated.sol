// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

// AUDIT: Annotated copy for review only. Deploy / test against src/Reentrance.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Reentrance {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        // AUDIT [OK]: SafeMath.add used here.
        balances[_to] = balances[_to].add(msg.value);
    }

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — classic reentrancy
    // - Checks balance, then sends ETH via call{value:} (forwards remaining gas), THEN updates balances.
    // - Violates Checks-Effects-Interactions. Attacker receive()/fallback can call withdraw again
    //   while balances[msg.sender] is still the old value.
    // - Also: balances[msg.sender] -= _amount uses unchecked 0.6 arithmetic (no SafeMath).
    //   After recursive drains, balance can underflow to type(uint256).max (secondary C-02).
    // - Exploit: donate(X) → withdraw(X) → receive reenters withdraw until contract empty.
    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount; // AUDIT [INFO]: no-op; return value ignored for control flow beyond this.
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
