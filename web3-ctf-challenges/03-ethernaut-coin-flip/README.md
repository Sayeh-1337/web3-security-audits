# 03 — Ethernaut Coin Flip

- Challenge: [Coin Flip](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-coin-flip)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Win the game 10 times in a row (`consecutiveWins == 10`).

## Starting facts

- Outcome of each flip is derived from `blockhash(block.number - 1) / FACTOR`
- `FACTOR` = `2^255`
- Same-block second flip reverts (`lastHash` guard)
- SCH calls your `run()` once per block until the goal is met

## Files

| File | Purpose |
|------|---------|
| `src/CoinFlip.sol` | Target contract (unmodified SCH version) |
| `src/CoinFlip.annotated.sol` | Same contract with inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes and findings register |
| `Exploit.s.sol` | SCH submission snippet (paste into their editor) |
| `script/Exploit.s.sol` | Full local Foundry script (loops 10 blocks) |
| `test/CoinFlipExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution steps |

## Local test

```bash
forge test --match-test testExploit -vv
```
