# 19 — Ethernaut MagicNumber

- Challenge: [MagicNumber](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-magic-number)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Install a Solver that returns `42` and has at most **ten** runtime bytes.

## Starting facts

- `setSolver` accepts any address — no size check on-chain
- Verifier requires `whatIsTheMeaningOfLife() == 42` and `extcodesize(solver) <= 10`
- Solidity cannot emit a ≤10-byte contract; deploy raw EVM creation bytecode

## Files

| File | Purpose |
|------|---------|
| `src/MagicNumber.sol` | Target contract |
| `src/MagicNumber.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/MagicNumberExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
