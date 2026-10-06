# MagicNumber — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 19 — MagicNumber](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-magic-number) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/MagicNumber.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Info (bytecode / size constraint CTF) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`MagicNumber` stores a `Solver` and forwards `whatIsTheMeaningOfLife()`. The level requires the solver to return `42` with **at most 10 bytes** of runtime code. That forces raw EVM bytecode: Solidity’s compiler cannot produce a contract that small.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Solver returns 42 | `whatIsTheMeaningOfLife() == 42` |
| 2 | Runtime ≤ 10 bytes | `address(solver).code.length <= 10` |

---

## Finding

### [I-01] Unrestricted solver + off-chain size gate

| Field | Detail |
|-------|--------|
| **Severity** | Info (CTF constraint) |
| **Bug class** | Missing on-chain size / interface checks |
| **Location** | `setSolver` |

#### Proof of concept

```bash
cd web3-ctf-challenges/19-ethernaut-magic-number
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    bytes memory bytecode = hex"600a600c600039600a6000f3602a60005260206000f3";
    address solver;
    assembly {
        solver := create(0, add(bytecode, 0x20), mload(bytecode))
    }
    require(solver != address(0), "create failed");
    magicNumberInstance.setSolver(solver);

    vm.stopBroadcast();
}
```

Instance name: `magicNumberInstance`.

---

## Remediation

If size or interface constraints matter on-chain, check `extcodesize` / function selectors in `setSolver` (or the factory). For this level, the constraint is intentional.

---

## References

- [Ethernaut MagicNumber (OZ)](https://ethernaut.openzeppelin.com/level/18)
- EVM opcodes: `PUSH1`, `MSTORE`, `CODECOPY`, `RETURN`
