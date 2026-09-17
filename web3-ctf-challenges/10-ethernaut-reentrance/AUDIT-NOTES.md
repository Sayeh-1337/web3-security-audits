# Audit Notes — `Reentrance.sol`

**Auditor notes for:** Ethernaut 10 Re-entrancy (CTF)  
**Contract:** `src/Reentrance.sol`  
**Annotated copy:** `src/Reentrance.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Reentrancy: ETH sent before balance update | `withdraw` |
| C-02 | Critical | Unchecked `-=` on 0.6 can underflow after reentrancy | `withdraw` |
| I-01 | Info | SafeMath only on `donate` — inconsistent hardening | `donate` vs `withdraw` |

**Verdict:** Not safe. Classic reentrancy drains all ETH.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `donate` / `withdraw` ETH flow | ERC-777 / token callbacks (same class, different asset) |

---

## Line-by-line review

### `donate`

| Note | Detail |
|------|--------|
| **OK** | Credits `balances[_to]` with SafeMath. |
| **INFO (I-01)** | SafeMath here lulls reviewers; withdraw is unprotected. |

### `withdraw` — **PRIMARY FINDING**

```solidity
    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | Interaction before effect. Attacker `receive` can re-call `withdraw` while credit remains. |
| **CRITICAL (C-02)** | After N successful reentrant withdrawals of size X with credited balance X, final `-=` underflows → balance wraps to ~`uint256.max` (secondary drain path). |
| **FIX** | CEI: zero/decrement balance first; use `nonReentrant`; prefer pull pattern; use 0.8+ or SafeMath on subtract. |

---

## Attack path

```
Helper.attack{value: B}:
  donate(Helper, B)     balances[Helper]=B; victim ETH += B
  withdraw(B)
    call Helper with B
      receive → withdraw(B) again while balances still B
      ... repeat until victim.balance == 0
    then balances[Helper] -= B (may underflow if reentered)
```

---

## Remediation

1. Update `balances[msg.sender]` **before** the external call (CEI).
2. Add OpenZeppelin `ReentrancyGuard` (`nonReentrant`).
3. Use Solidity `^0.8.0` or SafeMath for all balance math.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| External calls reviewed | Done — C-01 |
| Arithmetic on 0.6 reviewed | Done — C-02 |
| Exploit PoC | `test/ReentranceExploit.t.sol` |
| Safe to deploy | **No** |
