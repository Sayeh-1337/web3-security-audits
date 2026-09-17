# Audit Notes — `Fallout.sol`

**Auditor notes for:** Ethernaut 02 Fallout (CTF)  
**Contract:** `src/Fallout.sol`  
**Annotated copy:** `src/Fallout.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Incorrect constructor name — `Fal1out()` is a public initializer | L12–15 |
| M-01 | Medium | `collectAllocations()` uses `.transfer()` (2300 gas stipend) | L27–29 |
| I-01 | Info | Comment `/* constructor */` masks the missing `constructor` keyword | L11–15 |
| I-02 | Info | No events on ownership or withdrawal | L13, L28 |
| I-03 | Info | `owner` defaults to `address(0)` after deploy | L9, L12–15 |

**Verdict:** Not safe to deploy. The intended constructor never runs; any caller can take ownership and drain ETH.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `Fallout.sol` — ownership, allocations, ETH handling | External dependencies (SafeMath overflow — unused attack surface) |
| Constructor / initializer pattern | Front-running / MEV |
| `collectAllocations()` fund movement | Upgradeability / proxy patterns |

SCH ships a shortened Fallout (no `sendAllocation` / `allocatorBalance`). Official Ethernaut includes those helpers; they do not change C-01.

---

## Line-by-line review

### L1–3 — Header

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";
```

| Note | Detail |
|------|--------|
| **INFO** | `^0.6.0` is pre-0.8 (no built-in overflow checks). SafeMath is used only in `allocate()`. |
| **INFO** | From Solidity **0.5.0**, constructors must use the `constructor` keyword. A function named after the contract is **not** a constructor on this pragma. |
| **INFO** | Pin exact compiler version in production (`0.6.x`) for reproducible builds. |

---

### L6–9 — State variables

```solidity
contract Fallout {
    using SafeMath for uint256;
    mapping(address => uint256) allocations;
    address payable public owner;
```

| Note | Detail |
|------|--------|
| **INFO** | `allocations` is not `public` — no auto-getter. Fine for this design. |
| **INFO** | `owner` is a single point of privilege for `collectAllocations()`. Any bug in ownership logic is Critical. |
| **CHECK** | Uninitialized `address` is `0x0`. Confirm a constructor sets `owner`. **Finding: it does not** (see C-01). |

---

### L11–15 — `Fal1out()` — **PRIMARY FINDING**

```solidity
    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | Intended as the constructor. The name is `Fal1out` (letter `l` replaced by digit `1`), not `Fallout`. |
| **CRITICAL** | Even a correctly spelled `function Fallout()` would **not** be a constructor on `^0.6.0`. Only `constructor()` is. |
| **CRITICAL** | Visibility is `public` with no access control. Anyone can call it after deploy. |
| **CRITICAL** | Never executes at deployment → `owner` stays `address(0)`. |
| **INFO (I-01)** | The `/* constructor */` comment is a decoy. Reviewers who trust comments miss the typo. |
| **INFO** | `payable` is optional for the exploit. SCH win condition does not require `msg.value`. |
| **INFO (I-02)** | No `OwnershipTransferred` event. |
| **FIX** | Replace with `constructor() public payable { owner = msg.sender; ... }` (0.6 syntax). |

**Auditor question answered:** *Does anything set `owner` at deploy time?*  
**No.** The only assignment is inside a public function.

---

### L17–20 — `onlyOwner` modifier

```solidity
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
```

| Note | Detail |
|------|--------|
| **OK** | Standard access control. Correctly gates `collectAllocations()`. |
| **INFO** | Until someone calls `Fal1out()`, `owner == address(0)`, so only the zero address would pass — and that address cannot send txs. The contract is ownerless until C-01 is used. |

---

### L22–24 — `allocate()`

```solidity
    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }
```

| Note | Detail |
|------|--------|
| **OK** | Records deposits. Does not mutate `owner`. |
| **INFO** | SafeMath `.add()` is appropriate on 0.6. |
| **INFO** | Not required for the SCH goal (ownership only). |

---

### L26–29 — `collectAllocations()`

```solidity
    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (downstream)** | Once C-01 is exploited, this sends **100% of balance** to the attacker. Impact amplifier. Not required to pass the SCH level. |
| **MEDIUM (M-01)** | `.transfer()` forwards only 2300 gas. Can fail if `owner` is a contract with heavy `receive()`. Prefer `.call{value:}("")` + `require(success)` in modern Solidity. |
| **INFO (I-02)** | No withdrawal event. |
| **INFO** | Sends to `msg.sender` (which the modifier already proved is `owner`). |

---

## Invariant analysis

### Intended invariant (implied by the constructor comment)

> `owner` is set once at deployment to the deployer and never taken by an unprivileged caller.

### Actual invariant (broken)

> `owner` is unset at deploy (`address(0)`). Any address that calls `Fal1out()` becomes `owner`.

### Privilege graph

```
deploy  ──►  owner = 0x0  (no constructor)
any EOA ──►  Fal1out()  ──►  owner = msg.sender
                         ──►  collectAllocations()  ──►  drain all ETH
```

---

## Function interaction matrix

| Function | Mutates `owner` | Mutates `allocations` | Receives ETH | Sends ETH |
|----------|-----------------|-----------------------|--------------|-----------|
| *(missing constructor)* | No | No | No | No |
| `Fal1out()` | **Yes (unrestricted)** | Yes | Optional | No |
| `allocate()` | No | Yes | Yes | No |
| `collectAllocations()` | No | No | No | Yes (all balance) |

**Gap:** the only `owner` assignment is an unprotected public function.

---

## Test recommendations (for a fixed version)

| Test | Assert |
|------|--------|
| Fresh deploy | `owner == deployer` |
| Unprivileged `Fal1out()` | Must revert (function should not exist) |
| Owner `collectAllocations()` | Balance zero; recipient receives funds |
| Non-owner `collectAllocations()` | Reverts |

Local exploit test (current vulnerable code): `test/FalloutExploit.t.sol` — **must fail after fix**.

---

## Remediation priority

1. **C-01** — Replace `Fal1out()` with a real `constructor` (blocking).
2. **M-01** — Replace `.transfer()` with safe `.call` pattern (recommended).
3. **I-02** — Add `OwnershipTransferred` and `Withdrawn` events (best practice).

---

## Auditor sign-off block

| Item | Status |
|------|--------|
| All `owner` assignments reviewed | Done — 1 path, unprotected |
| Constructor / initializer reviewed | Done — C-01 found |
| External calls reviewed | Done — `collectAllocations()` `.transfer()` noted |
| Exploit PoC exists | Yes — `test/FalloutExploit.t.sol` |
| Safe to deploy | **No** |
