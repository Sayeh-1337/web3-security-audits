# Audit Notes — `Fallback.sol`

**Auditor notes for:** Ethernaut 01 Fallback (CTF)  
**Contract:** `src/Fallback.sol`  
**Annotated copy:** `src/Fallback.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Ownership bypass via `receive()` | L34–37 |
| M-01 | Medium | `withdraw()` uses `.transfer()` (2300 gas stipend) | L30–32 |
| I-01 | Info | Misleading ownership path in `contribute()` | L18–24, L8–11 |
| I-02 | Info | No events on ownership or withdrawal | L21–22, L30–31, L36 |
| I-03 | Info | No reentrancy guard on `withdraw()` | L30–32 |

**Verdict:** Not safe to deploy. Critical ownership flaw allows unprivileged takeover and fund drain.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `Fallback.sol` — ownership, contributions, ETH handling | External dependencies (none) |
| `receive()` / fallback behavior | Front-running / MEV |
| `withdraw()` fund movement | Upgradeability / proxy patterns |

---

## Line-by-line review

### L1–2 — Header

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
```

| Note | Detail |
|------|--------|
| **INFO** | `^0.8.0` enables built-in overflow checks. No issue here. |
| **INFO** | Pin exact compiler version in production (`0.8.x`) for reproducible builds. |

---

### L4–6 — State variables

```solidity
contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;
```

| Note | Detail |
|------|--------|
| **INFO** | `contributions` is publicly readable via auto-generated getter. Fine for this design. |
| **INFO** | `owner` is a single point of privilege for `withdraw()`. Any bug in ownership logic is Critical. |
| **CHECK** | Confirm every assignment to `owner` uses the same invariant. **Finding: it does not** (see C-01). |

---

### L8–11 — Constructor

```solidity
    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }
```

| Note | Detail |
|------|--------|
| **INFO (I-01)** | Deployer gets `1000 ether` credited without sending ETH. This is intentional for the CTF but creates a misleading signal: reviewers may assume `contribute()` is the only ownership path. |
| **INFO** | No `payable` constructor — contract cannot receive ETH at deploy time via constructor. ETH must arrive later via `contribute()` or plain transfer. |
| **RISK** | If `contributions[owner]` is ever out of sync with reality (here it is — deployer never paid), ownership rules based on that mapping are gameable. |

---

### L13–16 — `onlyOwner` modifier

```solidity
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
```

| Note | Detail |
|------|--------|
| **OK** | Standard access control pattern. Correctly gates `withdraw()`. |
| **INFO** | Modifier is only applied to `withdraw()`. **`receive()` has no access control** — and should not grant ownership without equivalent checks. |

---

### L18–24 — `contribute()`

```solidity
    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }
```

| Note | Detail |
|------|--------|
| **INFO (I-01)** | `require(msg.value < 0.001 ether)` caps each deposit. Combined with deployer's `1000 ether` seed, beating the owner via this function alone requires 1,000,000+ calls. |
| **INFO** | Uses strict inequality `>` — tie goes to incumbent owner. Reasonable. |
| **INFO (I-02)** | No `OwnershipTransferred` event when `owner` changes. Harder to monitor off-chain. |
| **CRITICAL (C-01)** | This function is **not the only path** that sets `owner`. `receive()` uses weaker rules — inconsistent invariant. |
| **CHECK** | Arithmetic safe under 0.8.x for realistic contribution amounts. |

**Auditor question answered:** *Can a user become owner without exceeding 1000 ether in contributions?*  
**Yes** — via `receive()` after any dust contribution.

---

### L26–28 — `getContribution()`

```solidity
    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }
```

| Note | Detail |
|------|--------|
| **OK** | Simple view. No state mutation. No issue. |
| **INFO** | Redundant with public mapping getter `contributions(address)` — duplicate API surface, not a security issue. |

---

### L30–32 — `withdraw()`

```solidity
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (downstream)** | Once C-01 is exploited, this sends **100% of balance** to attacker. Impact amplifier. |
| **MEDIUM (M-01)** | `.transfer()` forwards only 2300 gas to recipient. Can fail if `owner` is a contract with heavy fallback logic. Prefer `.call{value:}("")` + `require(success)` in modern Solidity. |
| **INFO (I-03)** | No reentrancy guard. State (`owner`) is not cleared before external call, but no state depends on balance after transfer in this minimal contract. Low risk here; would matter in extended designs. |
| **INFO (I-02)** | No withdrawal event. |
| **INFO** | Sends to `owner`, not `msg.sender`. Correct if `owner == msg.sender` (enforced by modifier). |

---

### L34–37 — `receive()` — **PRIMARY FINDING**

```solidity
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | Sets `owner = msg.sender` when caller has **any** contribution > 0. Does **not** require `contributions[msg.sender] > contributions[owner]`. |
| **CRITICAL** | Callable via plain ETH transfer (`call{value:}("")`), not only via `contribute()`. |
| **CRITICAL** | Attack: `contribute{value: 1 wei}()` then `call{value: 1 wei}("")` → instant ownership. |
| **INFO** | `msg.value > 0` is satisfied by 1 wei. |
| **INFO (I-02)** | No event on ownership change. |
| **FIX** | Remove ownership logic from `receive()`, or duplicate `contribute()`'s comparison logic. |

**This is the sibling-function miss:** auditors who only review `contribute()` miss the weaker `receive()` path.

---

## Invariant analysis

### Intended invariant (implied by `contribute()`)

> `owner` is the address whose `contributions[owner]` is the highest among participants.

### Actual invariant (broken)

> `owner` may also become any address that (1) has `contributions[a] > 0` and (2) sends ETH via plain transfer.

### Privilege graph

```
contributions > 0  +  plain ETH send  ──►  receive()  ──►  owner = msg.sender
                                                      ──►  withdraw()  ──►  drain all ETH
```

---

## Function interaction matrix

| Function | Mutates `owner` | Mutates `contributions` | Receives ETH | Sends ETH |
|----------|-----------------|-------------------------|--------------|-----------|
| `constructor` | Yes (deployer) | Yes (deployer seed) | No | No |
| `contribute()` | Conditional | Yes | Yes | No |
| `getContribution()` | No | No | No | No |
| `withdraw()` | No | No | No | Yes (all balance) |
| `receive()` | **Always (if checks pass)** | No | Yes | No |

**Gap:** `receive()` mutates `owner` without updating `contributions` or comparing totals.

---

## Test recommendations (for a fixed version)

| Test | Assert |
|------|--------|
| Dust contribution + plain send | Must **not** change `owner` after fix |
| Legitimate out-contribution via `contribute()` | Should change `owner` if that path is kept |
| Non-contributor plain send | Must not change `owner` |
| Owner `withdraw()` | Balance zero; recipient receives funds |
| Contract owner recipient | `withdraw()` succeeds with smart-wallet owner (if using `.call`) |

Local exploit test (current vulnerable code): `test/FallbackExploit.t.sol` — **must fail after fix**.

---

## Remediation priority

1. **C-01** — Fix or remove ownership logic in `receive()` (blocking).
2. **M-01** — Replace `.transfer()` with safe `.call` pattern (recommended).
3. **I-02** — Add `OwnershipTransferred` and `Withdrawn` events (best practice).
4. **I-03** — Add `nonReentrant` if contract grows beyond this minimal scope.

---

## Auditor sign-off block

| Item | Status |
|------|--------|
| All `owner` assignments reviewed | Done — 3 paths found |
| Fallback/receive handlers reviewed | Done — C-01 found |
| External calls reviewed | Done — `withdraw()` `.transfer()` noted |
| Exploit PoC exists | Yes — `test/FallbackExploit.t.sol` |
| Safe to deploy | **No** |
