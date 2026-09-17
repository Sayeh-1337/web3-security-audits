# Audit Notes — `Force.sol`

**Auditor notes for:** Ethernaut 07 Force (CTF)  
**Contract:** `src/Force.sol`  
**Annotated copy:** `src/Force.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** (design) | Balance can be forced despite no payable path | whole contract |
| I-01 | Info | Empty bytecode surface — all risk is in assumptions others make about it | L4–9 |

**Verdict:** The contract itself does nothing wrong functionally. The lesson is for **any** contract that treats `address(this).balance` as a trusted invariant.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| How ETH can enter without payable functions | Miner coinbase rewards |
| `selfdestruct` force-send | Post-Cancun EIP-6780 code deletion nuances (ETH transfer still works) |

---

## Line-by-line review

```solidity
contract Force {
    /*
        The contract has no payable function.
        The goal is still to make its balance greater than zero.
    */
}
```

| Note | Detail |
|------|--------|
| **INFO** | No state, no functions. Normal `call{value:}` / `transfer` / `send` fail. |
| **CRITICAL (C-01)** | `selfdestruct(payable(force))` credits balance without executing Force code. |
| **LESSON** | Do not gate logic on `balance == 0` or “only deposits via our payable functions.” Use internal accounting (`mapping` deposits) instead of raw balance. |

---

## Attack path

```
Player ──deploy Helper{value: 1 wei}──► Helper.constructor
                                              │
                                              ▼ selfdestruct(force)
                                        Force.balance += 1 wei
                                        (no receive/fallback runs)
```

---

## Remediation (for real protocols)

1. Track deposits in a state variable; never trust `address(this).balance` alone for shares / payouts.
2. Assume balance can increase unexpectedly at any time.
3. Post-Cancun: `selfdestruct` still force-sends ETH even when code deletion is limited.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| Payable entry points | None — intentional |
| Force-send vectors considered | Yes — C-01 |
| Exploit PoC | `test/ForceExploit.t.sol` |
| Safe as a “balance == 0” assumption? | **No** |
