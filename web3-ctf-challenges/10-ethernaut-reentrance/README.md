# 10 — Ethernaut Re-entrancy

- Challenge: [Re-entrancy](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-reentrance)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Drain the Reentrance contract's ETH balance.

## Starting facts

- Solidity `^0.6.12` — unchecked arithmetic on `balances -= _amount`
- `donate` uses SafeMath; `withdraw` does not
- `withdraw` sends ETH with `call{value:}` **before** updating `balances`
- Instance is usually seeded with ETH (e.g. `0.001 ether`)

## Files

| File | Purpose |
|------|---------|
| `src/Reentrance.sol` | Target contract (unmodified SCH version) |
| `src/Reentrance.annotated.sol` | Inline `AUDIT:` comments |
| `src/vendor/math/SafeMath.sol` | Minimal SafeMath for 0.6 compile |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet (HelperContract + run) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/ReentranceExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
