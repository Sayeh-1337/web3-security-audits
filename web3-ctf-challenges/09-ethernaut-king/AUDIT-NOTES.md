# Audit Notes — `King.sol`

**Auditor notes for:** Ethernaut 09 King (CTF)  
**Contract:** `src/King.sol`  
**Annotated copy:** `src/King.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | DoS: `.transfer` to untrusted `king` can permanently lock throne | `receive` L16–20 |
| M-01 | Medium | Checks-Effects-Interactions violated (external call before state update) | L17–19 |
| I-01 | Info | `.transfer` 2300 gas stipend — fragile even for “friendly” contract kings | L17 |

**Verdict:** Not safe. A malicious king contract bricks further kingship transfers.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `receive` kingship / refund logic | Game-theory prize inflation |

---

## Line-by-line review

### Constructor

| Note | Detail |
|------|--------|
| **OK** | Sets `owner`, initial `king`, `prize = msg.value`. |

### `receive()` — **PRIMARY FINDING**

```solidity
    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | `king` can be any contract. If it rejects ETH, `.transfer` reverts → no one (including owner) can become the new king. Owner bypasses the prize `require` but still hits `.transfer`. |
| **MEDIUM (M-01)** | State (`king`, `prize`) updated after external call. |
| **INFO (I-01)** | Prefer pull-payment or `call` with handled failure — better: don’t push ETH to arbitrary kings at all. |
| **FIX** | Pull pattern: credit `pendingReturns[king]`; let them withdraw. Or use `call` and continue on failure (game-design choice). Never let an untrusted recipient abort critical state transitions. |

---

## Attack path

```
Helper (no receive) ──call{value: prize}──► King.receive
                                              transfer(oldKing) OK
                                              king = Helper
Anyone / owner ──call{value:}──► King.receive
                                   transfer(Helper) REVERTS
                                   king stays Helper forever
```

---

## Remediation

1. Pull payments instead of pushing to `king`.
2. Or ignore refund failure and still update `king`.
3. Avoid `.transfer` for anything security-critical.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| External calls to untrusted addrs | Done — C-01 |
| Exploit PoC | `test/KingExploit.t.sol` |
| Safe to deploy | **No** |
