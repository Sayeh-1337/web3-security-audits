# 01 — Ethernaut Fallback

- Challenge: [Fallback](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-fallback)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Claim ownership of the contract.
2. Reduce the contract balance to zero.

## Starting facts

- `owner` = deployer
- Contract balance = 0.001 ether
- Player balance = 1 ether

## Files

| File | Purpose |
|------|---------|
| `src/Fallback.sol` | Target contract (unmodified CTF version) |
| `src/Fallback.annotated.sol` | Same contract with inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes and findings register |
| `Exploit.s.sol` | SCH submission snippet (paste into their editor) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/FallbackExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution steps |

## Local test

```bash
forge install foundry-rs/forge-std
forge test --match-test testExploit -vv
```
