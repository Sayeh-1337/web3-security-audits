# Audit Notes — `CoinFlip.sol`

**Auditor notes for:** Ethernaut 03 Coin Flip (CTF)  
**Contract:** `src/CoinFlip.sol`  
**Annotated copy:** `src/CoinFlip.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Predictable PRNG from public `blockhash` | L9–26 (`flip`) |
| I-01 | Info | `FACTOR` not `constant` / `immutable` | L7 |
| I-02 | Info | `lastHash` only blocks same-block replay — not entropy | L10–12 |

**Verdict:** Not safe for any real stakes. On-chain “coin flip” from `blockhash` is fully predictable by the caller’s transaction.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| `CoinFlip.sol` — randomness, streak logic | MEV / block producer manipulation (bonus attack, not needed) |
| Same-block `lastHash` guard | Upgradeability |

---

## Line-by-line review

### L1–2 — Header

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
```

| Note | Detail |
|------|--------|
| **INFO** | `^0.8.0` — fine. No external deps. |

---

### L4–7 — State

```solidity
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
```

| Note | Detail |
|------|--------|
| **INFO** | Goal variable is public — attacker can poll progress. |
| **INFO (I-01)** | `FACTOR == 2^255`. Should be `constant` for gas; not a vuln. |
| **CHECK** | Confirm entropy source is off-chain / commit-reveal / VRF. **Finding: it is not** (see C-01). |

---

### L9–26 — `flip()` — **PRIMARY FINDING**

```solidity
    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        if (lastHash == blockValue) {
            revert();
        }
        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        // ... streak update
    }
```

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | `blockhash(block.number - 1)` is public and fixed for the entire current block. Any caller can recompute `side` before guessing. |
| **INFO (I-02)** | `lastHash` only stops two flips in one block. Attacker still wins every block. |
| **INFO** | `blockValue / FACTOR` extracts the MSB of the previous block hash — deterministic bit, not a coin. |
| **FIX** | Use Chainlink VRF (or equivalent), or a commit-reveal scheme with a future block. Never use `blockhash` / `block.timestamp` / `block.prevrandao` alone for adversarial games. |

**Auditor question answered:** *Can a player know the correct guess before calling `flip`?*  
**Yes** — same formula, same block context.

---

## Invariant analysis

### Intended invariant

> Each flip is an independent 50/50 chance; reaching 10 consecutive wins is improbable (~1/1024).

### Actual invariant (broken)

> A player who copies the PRNG wins with probability 1 every block.

### Privilege / attack graph

```
block N-1 hash (public)
        │
        ▼
 attacker computes side = hash / 2^255 == 1
        │
        ▼
 flip(side) in block N  ──►  consecutiveWins++
        │
        ▼  (repeat across 10 blocks)
 consecutiveWins == 10
```

---

## Function interaction matrix

| Function | Reads entropy | Mutates streak | Can be predicted? |
|----------|---------------|----------------|-------------------|
| `flip()` | `blockhash(n-1)` | Yes | **Yes — fully** |

---

## Test recommendations (for a fixed version)

| Test | Assert |
|------|--------|
| Attacker copies PRNG across 10 blocks | Must **not** reach 10 wins after fix |
| Honest random guesser | Streak should reset on wrong guesses |
| Same-block double `flip` | Still reverts (keep `lastHash` or better rate limit) |

Local exploit test (current vulnerable code): `test/CoinFlipExploit.t.sol` — **must fail after fix**.

---

## Remediation priority

1. **C-01** — Replace `blockhash` PRNG with VRF / commit-reveal (blocking).
2. **I-01** — Mark `FACTOR` as `constant` (gas hygiene).

---

## Auditor sign-off block

| Item | Status |
|------|--------|
| Entropy sources reviewed | Done — public `blockhash` only |
| Same-block replay reviewed | Done — mitigated, irrelevant to C-01 |
| Exploit PoC exists | Yes — `test/CoinFlipExploit.t.sol` |
| Safe to deploy (real value) | **No** |
