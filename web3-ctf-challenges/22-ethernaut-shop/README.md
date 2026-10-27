# 22 — Ethernaut Shop

- Challenge: [Shop](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-shop)
- Platform: Ethernaut (SCH)
- Reward: CTF EXP

## Goals

1. Buy the item and leave its final price at zero.

## Starting facts

- `buy()` treats `msg.sender` as a `Buyer` and calls `price()` **twice**
- First call gates the purchase; second call (after `isSold = true`) sets `price`
- A malicious buyer can return `>= 100` then `0` by reading `isSold`

## Files

| File | Purpose |
|------|---------|
| `src/Shop.sol` | Target contract |
| `src/Shop.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/ShopExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
