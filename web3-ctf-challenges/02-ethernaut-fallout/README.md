# 02 — Ethernaut Fallout

- Challenge: [Fallout](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-fallout)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Claim ownership of the contract.

## Starting facts

- No real constructor ran at deploy
- `owner` = `address(0)`
- `Fal1out()` is a public payable function anyone can call
- Player balance = 1 ether (local harness)

## Files

| File | Purpose |
|------|---------|
| `src/Fallout.sol` | Target contract (unmodified SCH version) |
| `src/Fallout.annotated.sol` | Same contract with inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes and findings register |
| `Exploit.s.sol` | SCH submission snippet (paste into their editor) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/FalloutExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution steps |

## Local test

```bash
forge install foundry-rs/forge-std
forge test --match-test testExploit -vv
```
