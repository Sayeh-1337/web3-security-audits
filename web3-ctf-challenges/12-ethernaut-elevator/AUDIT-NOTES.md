# Audit Notes — `Elevator.sol`

**Auditor notes for:** Ethernaut 12 Elevator (CTF)  
**Contract:** `src/Elevator.sol`  
**Annotated copy:** `src/Elevator.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Untrusted `msg.sender` Building; stateful `isLastFloor` called twice | `goTo` |
| I-01 | Info | `Building.isLastFloor` is not `view` — enables inconsistent answers | interface |

**Verdict:** Not safe. Any caller contract can force `top = true`.

---

## Line-by-line

### `Building` interface

| Note | Detail |
|------|--------|
| **INFO (I-01)** | Non-view callback. Same input can yield different outputs across calls. |
| **FIX** | Use `view` (and don't rely on untrusted view either without verification), or don't trust external oracles for safety flags. |

### `goTo`

```solidity
    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);
        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | Assumes `msg.sender` is an honest Building. Attacker implements Building, returns false then true. |
| **FIX** | Don't take floor/top from untrusted callbacks; use internal logic or a trusted registry. |

---

## Attack path

```
Helper.attack(1)
  Elevator.goTo(1)
    isLastFloor(1) -> false   // enter if
    floor = 1
    isLastFloor(1) -> true    // top = true
```

---

## Auditor sign-off

| Item | Status |
|------|--------|
| External callbacks reviewed | Done — C-01 |
| Exploit PoC | `test/ElevatorExploit.t.sol` |
| Safe to deploy | **No** |
