// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice A deliberately minimal ERC-20 with a time-locked direct transfer.
/// The inherited allowance path is intentionally not locked.
contract NaughtCoin {
    string public constant name = "NaughtCoin";
    string public constant symbol = "0";
    uint8 public constant decimals = 18;
    uint256 public immutable timeLock;
    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor(address player, uint256 initialSupply) {
        timeLock = block.timestamp + 3650 days;
        totalSupply = initialSupply;
        balances[player] = initialSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(block.timestamp > timeLock, "NaughtCoin: locked");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowances[from][msg.sender];
        require(allowed >= amount, "NaughtCoin: allowance");
        allowances[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(balances[from] >= amount, "NaughtCoin: balance");
        balances[from] -= amount;
        balances[to] += amount;
    }
}
