# Audit Notes — `Token.sol`

**Auditor notes for:** Ethernaut 05 Token (CTF)  
**Contract:** `src/Token.sol`  
**Annotated copy:** `src/Token.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Unchecked underflow in `transfer` (Solidity 0.6) | L12–16 |
| I-01 | Info | Useless `require(... >= 0)` on `uint256` math | L13 |
| I-02 | Info | No events; `totalSupply` not conserved after exploit | L6, L14–15 |

**Verdict:** Not safe to deploy. Any holder can mint themselves near-infinite balance by transferring more than they own.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `Token.sol` — balances, transfer arithmetic | Approvals / ERC-20 completeness |
| Solidity 0.6 overflow semantics | Front-running |

---

## Line-by-line review

### L1–2 — Header

```solidity
pragma solidity ^0.6.0;
```

| Note | Detail |
|------|--------|
| **CRITICAL context** | Pre-0.8: arithmetic wraps by default. Must use SafeMath or upgrade pragma. |

---

### L4–10 — State + constructor

```solidity
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }
```

| Note | Detail |
|------|--------|
| **OK** | Standard mint-to-deployer. |
| **INFO (I-02)** | After underflow exploit, sum of balances ≫ `totalSupply`. |

---

### L12–16 — `transfer` — **PRIMARY FINDING**

```solidity
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | `20 - 21` underflows to `2^256 - 1` before/during the check and assignment. |
| **INFO (I-01)** | For `uint256`, `x >= 0` is always true after wrap; the require is a false sense of safety. |
| **FIX** | Use Solidity `^0.8.0`, or SafeMath `sub`, or `require(balances[msg.sender] >= _value)` **before** subtracting. |

**Auditor question:** *Can a user transfer more tokens than they hold?*  
**Yes** — underflow makes the check pass and leaves a huge remaining balance.

---

## Invariant analysis

### Intended

> `balances[from] >= value` before debit; sum of balances == `totalSupply`.

### Actual (broken)

> Debit wraps; sender can end with `type(uint256).max`; conservation fails.

### Attack

```
balance[player] = 20
transfer(0x0, 21)
  require(20 - 21 >= 0)  →  require(2^256-1 >= 0)  ✓
  balances[player] = 2^256 - 1
  balances[0x0] += 21
```

---

## Remediation priority

1. **C-01** — Check `balances[msg.sender] >= _value` before subtract; prefer 0.8+ / SafeMath.
2. **I-02** — Emit `Transfer`; keep supply accounting consistent.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| Arithmetic reviewed | Done — C-01 |
| Exploit PoC | `test/TokenExploit.t.sol` |
| Safe to deploy | **No** |
