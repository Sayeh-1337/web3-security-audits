# Audit Notes — `Delegation.sol`

**Auditor notes for:** Ethernaut 06 Delegation (CTF)  
**Contract:** `src/Delegation.sol`  
**Annotated copy:** `src/Delegation.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Unrestricted `delegatecall` of `msg.data` + public `pwn()` | `Delegation.fallback`, `Delegate.pwn` |
| I-01 | Info | `delegatecall` return value ignored | `fallback` |
| I-02 | Info | Storage layout coincidence (`owner` @ slot 0) enables the attack | both contracts |

**Verdict:** Not safe. Any caller can become `Delegation.owner` with one low-level call.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `Delegate` + `Delegation` interaction | Upgradeable proxy patterns in general (related lesson) |
| `fallback` / `delegatecall` / storage layout | Front-running |

---

## Line-by-line review

### `Delegate.pwn()`

```solidity
    function pwn() public {
        owner = msg.sender;
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL** | No auth. Harmless if only called on `Delegate` itself (changes Delegate's owner). Catastrophic via `Delegation.delegatecall`. |
| **INFO** | Under `delegatecall`, `msg.sender` stays the original EOA. |

### `Delegation.fallback()`

```solidity
    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        result;
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | Forwards **arbitrary** calldata. Calling non-existent `pwn()` on Delegation hits fallback → executes `Delegate.pwn` in Delegation storage. |
| **INFO (I-01)** | Success flag discarded. |
| **FIX** | Do not `delegatecall` untrusted/user-controlled `msg.data`. Use explicit functions, or a tightly scoped library with matching storage layout. |

### Storage layout

| Slot | `Delegate` | `Delegation` |
|------|------------|--------------|
| 0 | `owner` | `owner` |
| 1 | — | `delegate` |

Aligned `owner` slots make `pwn()` rewrite `Delegation.owner`. Layout mismatch would corrupt `delegate` or other state instead — still dangerous.

---

## Attack path

```
Player.call(delegation, abi.encodeWithSignature("pwn()"))
  → Delegation has no pwn() → fallback
  → delegate.delegatecall(msg.data)
  → runs Delegate.pwn in Delegation context
  → slot0 owner = player
```

---

## Remediation

1. Remove open `delegatecall(msg.data)` from `fallback`.
2. If delegation is required, expose named wrappers with access control.
3. Never put privileged state mutation in library/logic contracts without matching carefully audited storage and auth.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| `delegatecall` sites reviewed | Done — C-01 |
| Storage layout compared | Done — slot 0 match |
| Exploit PoC | `test/DelegationExploit.t.sol` |
| Safe to deploy | **No** |
