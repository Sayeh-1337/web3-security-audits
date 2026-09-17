# 07 — Ethernaut Force

- Challenge: [Force](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-force)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Make the Force contract hold a positive ETH balance.

## Starting facts

- Empty contract — no `receive`, no payable `fallback`, no payable functions
- Plain ETH transfers revert
- ETH can still be forced in via `selfdestruct(target)`

## Files

| File | Purpose |
|------|---------|
| `src/Force.sol` | Target contract (unmodified SCH version) |
| `src/Force.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet (HelperContract + run) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/ForceExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
