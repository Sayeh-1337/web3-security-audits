# 05 — Ethernaut Token

- Challenge: [Token](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-token)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Increase the player's token balance beyond the initial allocation (20).

## Starting facts

- Solidity `^0.6.0` — no automatic overflow/underflow checks
- Player starts with **20** tokens
- `require(balances[msg.sender] - _value >= 0)` does not stop underflow

## Files

| File | Purpose |
|------|---------|
| `src/Token.sol` | Target contract (unmodified SCH version) |
| `src/Token.annotated.sol` | Same contract with inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes and findings register |
| `Exploit.s.sol` | SCH submission snippet (paste into their editor) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/TokenExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution steps |

## Local test

```bash
forge test --match-test testExploit -vv
```
