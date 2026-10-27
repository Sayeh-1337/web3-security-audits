# Shop — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 22 — Shop](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-shop) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Shop.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Medium (inconsistent view oracle / double-read) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Shop.buy` calls `Buyer.price()` twice and mutates `isSold` between them. A buyer that returns a qualifying price on the first call and `0` on the second purchases the item at a final price of zero.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Item sold at price 0 | `isSold == true` and `price == 0` |

---

## Finding

### [M-01] Double-read of attacker-controlled `price()`

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **Bug class** | Inconsistent oracle / view callback |
| **Location** | `buy()` |

#### Proof of concept

```bash
cd web3-ctf-challenges/22-ethernaut-shop
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

Helper implements `Buyer.price` keyed off `shop.isSold()`, then calls `buy()`. Instance name: `shopInstance`.

### Fix (real systems)

Cache `uint256 p = buyer.price()` once and use that value for both the check and the assignment, or avoid relying on untrusted view callbacks for pricing.
