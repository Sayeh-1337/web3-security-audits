# Audit Notes — `Telephone.sol`

**Auditor notes for:** Ethernaut 04 Telephone (CTF)  
**Contract:** `src/Telephone.sol`  
**Annotated copy:** `src/Telephone.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Ownership gated on `tx.origin != msg.sender` | L12–16 |
| I-01 | Info | No events on ownership change | L14 |
| I-02 | Info | Inverted / confused access control (EOA blocked, contract path allowed) | L13 |

**Verdict:** Not safe to deploy. Any intermediary contract call lets an attacker set `owner`.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `Telephone.sol` — ownership / auth | Upgradeability |
| `tx.origin` vs `msg.sender` semantics | Front-running |

---

## Line-by-line review

### L1–2 — Header

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
```

| Note | Detail |
|------|--------|
| **INFO** | No dependencies. Minimal surface. |

---

### L4–10 — State + constructor

```solidity
contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
```

| Note | Detail |
|------|--------|
| **OK** | Constructor correctly sets deployer as owner. |
| **INFO** | Entire privilege model is this one address. |

---

### L12–16 — `changeOwner` — **PRIMARY FINDING**

```solidity
    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | Uses `tx.origin` for authorization (actually as a *requirement* that a contract sits in the middle). |
| **CRITICAL** | No check that `msg.sender` is trusted. Any helper works. |
| **INFO (I-02)** | Direct EOA calls are rejected; intermediate contracts are accepted — opposite of “only EOA” intuition. |
| **INFO (I-01)** | No `OwnershipTransferred` event. |
| **FIX** | Never use `tx.origin` for auth. Prefer `msg.sender` + Ownable / AccessControl. If EOA-only is required, that is still wrong for wallets (AA / smart wallets). |

**Auditor question answered:** *Can a non-owner become owner?*  
**Yes** — deploy any contract that calls `changeOwner(attacker)` and invoke it from an EOA.

---

## Invariant analysis

### Intended (implied) invariant

> Only a “real” user (EOA) should control ownership — or only the current owner.

### Actual invariant (broken)

> Anyone who routes through a contract can set `owner` to an arbitrary address. Current `owner` is irrelevant.

### Privilege graph

```
Player EOA  ──►  Helper.attack()  ──►  Telephone.changeOwner(player)
 tx.origin=player                     msg.sender=Helper
                                      tx.origin != msg.sender  ✓
                                      owner = player
```

Classic phishing variant (production lesson):

```
Victim EOA  ──►  MaliciousSite  ──►  VictimWallet.transfer(...)
 tx.origin=victim                     drains victim because auth used tx.origin
```

---

## Function interaction matrix

| Function | Mutates `owner` | Auth check |
|----------|-----------------|------------|
| `constructor` | Yes (deployer) | N/A |
| `changeOwner` | Yes (if `tx.origin != msg.sender`) | Broken |

---

## Test recommendations (for a fixed version)

| Test | Assert |
|------|--------|
| Direct EOA `changeOwner` | Must not change owner (or only owner can) |
| Via helper contract | Must **not** change owner after fix |
| Owner-only transfer | Only current owner can update |

Local exploit test (vulnerable code): `test/TelephoneExploit.t.sol` — **must fail after fix**.

---

## Remediation priority

1. **C-01** — Remove `tx.origin` check; use `onlyOwner` / `msg.sender` (blocking).
2. **I-01** — Emit ownership events.

---

## Auditor sign-off block

| Item | Status |
|------|--------|
| Auth paths reviewed | Done — C-01 found |
| `tx.origin` usages reviewed | Done — one site, critical |
| Exploit PoC exists | Yes — `test/TelephoneExploit.t.sol` |
| Safe to deploy | **No** |
