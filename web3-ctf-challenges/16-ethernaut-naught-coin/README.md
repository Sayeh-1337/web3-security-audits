# 16 — Ethernaut Naught Coin

- Challenge: [Naught Coin](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-naught-coin)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Move all player NaughtCoin before the time lock expires (`balanceOf(player) == 0`).

## Starting facts

- `transfer` is locked until `timeLock` (~10 years)
- `approve` / `transferFrom` are **not** locked
- Bypass: approve a helper, then `transferFrom`

## Files

| File | Purpose |
|------|---------|
| `src/NaughtCoin.sol` | Target contract |
| `src/NaughtCoin.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/NaughtCoinExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
