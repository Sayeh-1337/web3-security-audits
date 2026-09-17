// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * A deliberately small ERC20-like civic token with snapshots. The verifier
 * seeds only a handful of holders, so a full snapshot is practical here.
 */
contract CivicToken {
    string public constant name = "Civic Token";
    string public constant symbol = "CVC";
    uint8 public constant decimals = 18;

    address public immutable owner;
    uint256 public totalSupply;
    uint256 public lastSnapshotId;

    mapping(address => uint256) private _balances;
    mapping(uint256 => uint256) private _totalSupplyAt;
    mapping(uint256 => mapping(address => uint256)) private _balanceAt;
    mapping(address => bool) private _knownHolder;
    address[] private _holders;

    constructor() {
        owner = msg.sender;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "only owner");
        totalSupply += amount;
        _balances[to] += amount;
        _rememberHolder(to);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(_balances[msg.sender] >= amount, "insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        _rememberHolder(to);
        return true;
    }

    function snapshot() external returns (uint256 snapshotId) {
        snapshotId = ++lastSnapshotId;
        _totalSupplyAt[snapshotId] = totalSupply;
        for (uint256 index = 0; index < _holders.length; index++) {
            address holder = _holders[index];
            _balanceAt[snapshotId][holder] = _balances[holder];
        }
    }

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256) {
        return _balanceAt[snapshotId][account];
    }

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256) {
        return _totalSupplyAt[snapshotId];
    }

    function _rememberHolder(address account) private {
        if (!_knownHolder[account]) {
            _knownHolder[account] = true;
            _holders.push(account);
        }
    }
}
